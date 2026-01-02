"""
WebSocket endpoint for real-time notifications.
Uses Redis pub/sub for broadcasting events between connections.
"""
import json
import asyncio
from typing import Dict, Set
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from jose import jwt, JWTError
from app.core.config import settings
from app.core.redis_client import redis_client
from app.api import deps
from app.models.user import User

router = APIRouter()

# Active connections: user_id -> set of WebSocket connections
active_connections: Dict[int, Set[WebSocket]] = {}


async def get_user_id_from_token(token: str, db: AsyncSession) -> int | None:
    """Extract user_id from JWT token (which contains email)."""
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        email = payload.get("sub")
        if not email:
            return None
            
        # Lookup user by email
        result = await db.execute(select(User).where(User.email == email))
        user = result.scalars().first()
        return user.id if user else None
    except (JWTError, ValueError, Exception) as e:
        print(f"WS Auth Error: {e}")
        return None


class ConnectionManager:
    """Manages WebSocket connections per user."""
    
    async def connect(self, websocket: WebSocket, user_id: int):
        await websocket.accept()
        if user_id not in active_connections:
            active_connections[user_id] = set()
        active_connections[user_id].add(websocket)
    
    def disconnect(self, websocket: WebSocket, user_id: int):
        if user_id in active_connections:
            active_connections[user_id].discard(websocket)
            if not active_connections[user_id]:
                del active_connections[user_id]
    
    async def send_to_user(self, user_id: int, message: dict):
        """Send message to all connections of a user."""
        if user_id in active_connections:
            disconnected = []
            for ws in active_connections[user_id]:
                try:
                    await ws.send_json(message)
                except Exception:
                    disconnected.append(ws)
            # Clean up disconnected
            for ws in disconnected:
                active_connections[user_id].discard(ws)


manager = ConnectionManager()


async def redis_listener(user_id: int, websocket: WebSocket):
    """Listen to Redis pub/sub channel for this user and forward messages."""
    pubsub = redis_client.redis.pubsub()
    channel = f"user:{user_id}"
    
    try:
        await pubsub.subscribe(channel)
        
        while True:
            message = await pubsub.get_message(ignore_subscribe_messages=True, timeout=1.0)
            if message and message["type"] == "message":
                try:
                    data = json.loads(message["data"])
                    await websocket.send_json(data)
                except (json.JSONDecodeError, Exception):
                    pass
            await asyncio.sleep(0.1)
    except asyncio.CancelledError:
        pass
    finally:
        await pubsub.unsubscribe(channel)
        await pubsub.close()


@router.websocket("/ws")
async def websocket_endpoint(
    websocket: WebSocket,
    token: str = Query(...),
    db: AsyncSession = Depends(deps.get_db)
):
    """
    WebSocket endpoint for real-time updates.
    
    Connect with: ws://host/ws?token=<jwt_token>
    
    Events received:
    - {"type": "new_offer", "task_id": 123, "offer_id": 456}
    - {"type": "task_status_changed", "task_id": 123, "status": "assigned"}
    - {"type": "new_message", "thread_id": 123, "sender_id": 456}
    """
    # Authenticate
    user_id = await get_user_id_from_token(token, db)
    if not user_id:
        print("WS Auth Failed: Invalid token or user not found")
        await websocket.close(code=4001, reason="Invalid token")
        return
    
    await manager.connect(websocket, user_id)
    
    # Start Redis listener task
    listener_task = asyncio.create_task(redis_listener(user_id, websocket))
    
    try:
        # Keep connection alive, handle incoming messages (ping/pong)
        while True:
            try:
                data = await websocket.receive_text()
                # Handle ping
                if data == "ping":
                    await websocket.send_text("pong")
            except WebSocketDisconnect:
                break
    finally:
        listener_task.cancel()
        try:
            await listener_task
        except asyncio.CancelledError:
            pass
        manager.disconnect(websocket, user_id)
