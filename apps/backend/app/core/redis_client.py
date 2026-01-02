import json
import redis.asyncio as redis
from app.core.config import settings

class RedisClient:
    def __init__(self):
        self.redis = redis.from_url(settings.REDIS_URL, encoding="utf-8", decode_responses=True)

    async def close(self):
        await self.redis.close()

    async def lock_task(self, task_id: int, helper_id: int, ttl_seconds: int = 120) -> bool:
        """
        Try to acquire a lock for a task.
        Returns True if lock acquired, False otherwise.
        Key format: task:{id}:lock
        """
        key = f"task:{task_id}:lock"
        # SET NX EX -> Set only if Not eXists, set EXpire time
        is_locked = await self.redis.set(key, helper_id, nx=True, ex=ttl_seconds)
        return bool(is_locked)

    async def unlock_task(self, task_id: int, helper_id: int):
        """
        Unlock task only if it is locked by this helper.
        Lua letter verification is safest but for MVP we do simple check.
        """
        key = f"task:{task_id}:lock"
        current_holder = await self.redis.get(key)
        if current_holder and int(current_holder) == helper_id:
            await self.redis.delete(key)

    async def publish_event(self, user_id: int, event_type: str, payload: dict = None):
        """
        Publish a real-time event to a user's channel.
        Used for WebSocket notifications.
        
        Args:
            user_id: The user to notify
            event_type: Event type (e.g., 'new_offer', 'task_status_changed', 'new_message')
            payload: Additional data for the event
        """
        channel = f"user:{user_id}"
        message = {
            "type": event_type,
            **(payload or {})
        }
        await self.redis.publish(channel, json.dumps(message))

redis_client = RedisClient()

