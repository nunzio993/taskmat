
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from app.api.endpoints import tasks, auth, profile, helper, chat
from app.core.redis_client import redis_client
from app.core.database import engine, Base

app = FastAPI(title="TaskMate API") # Reload trigger

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:3001",
        "http://127.0.0.1:3001",
        "http://localhost:3002",
        "http://127.0.0.1:3002",
        "http://localhost",
        "http://127.0.0.1"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
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

@app.get("/health")
async def health_check():
    return {"status": "ok"}