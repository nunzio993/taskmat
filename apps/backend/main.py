
from fastapi import FastAPI, Request
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from app.api.endpoints import tasks, auth, profile, helper, chat, ws, users, reviews, admin, stripe, categories
from app.core.redis_client import redis_client
from app.core.database import engine, Base
import os

# SEC-006: Rate limiter setup
limiter = Limiter(key_func=get_remote_address)

app = FastAPI(title="TaskMate API")

# Attach limiter to app state for use in endpoints
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS Configuration - can be overridden via CORS_ORIGINS environment variable
# Format: comma-separated list e.g. "https://app.taskmate.it,https://admin.taskmate.it"
default_origins = [
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://localhost:3001",
    "http://127.0.0.1:3001",
    "http://localhost:3002",
    "http://127.0.0.1:3002",
    "http://localhost:3003",  # Admin panel
    "http://127.0.0.1:3003",
    "http://localhost",
    "http://127.0.0.1"
]

cors_origins_env = os.environ.get("CORS_ORIGINS", "")
if cors_origins_env:
    allowed_origins = [origin.strip() for origin in cors_origins_env.split(",") if origin.strip()]
else:
    allowed_origins = default_origins

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

app.mount("/static", StaticFiles(directory="static"), name="static")

@app.on_event("shutdown")
async def shutdown_event():
    await redis_client.close()

@app.on_event("startup")
async def startup_event():
    # Create tables (Simple MVP approach)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(profile.router, prefix="/profile", tags=["profile"])
app.include_router(tasks.router, prefix="/tasks", tags=["tasks"])
app.include_router(helper.router, prefix="/helper", tags=["helper"])
app.include_router(chat.router, prefix="/chat", tags=["chat"])
app.include_router(users.router, prefix="/users", tags=["users"])
app.include_router(reviews.router, prefix="", tags=["reviews"])
app.include_router(ws.router, tags=["websocket"])
app.include_router(admin.router)  # Admin panel endpoints
app.include_router(stripe.router)  # Stripe Connect endpoints
app.include_router(categories.router)  # Public categories endpoint

@app.get("/health")
async def health_check():
    return {"status": "ok"}