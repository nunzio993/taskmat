import asyncio
from sqlalchemy import text
from app.core.database import AsyncSessionLocal

async def check():
    async with AsyncSessionLocal() as db:
        r = await db.execute(text('SELECT id, task_id, from_user_id, to_user_id, stars, status FROM reviews'))
        rows = r.fetchall()
        for row in rows:
            print(dict(row._mapping))

asyncio.run(check())
