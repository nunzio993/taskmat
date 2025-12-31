"""
Direct test to query offers from database bypassing the API layer.
"""
import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, selectinload
from sqlalchemy import select

DB_URL = "postgresql+asyncpg://user:password@localhost:5432/taskmate"

async def test_offers():
    print("=== DIRECT DATABASE TEST ===")
    engine = create_async_engine(DB_URL)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as session:
        # Query all offers
        from sqlalchemy import text
        
        # Raw SQL query
        result = await session.execute(text("SELECT * FROM task_offers WHERE task_id = 1"))
        rows = result.fetchall()
        print(f"\nRaw SQL: Found {len(rows)} offers for task_id=1")
        for row in rows:
            print(f"   -> {row}")
        
        # Now test SQLAlchemy ORM query
        print("\n--- Testing SQLAlchemy ORM ---")
        
        # We need to import the model - let's use raw SQL for now
        result2 = await session.execute(text("SELECT id, task_id, helper_id, price_cents, status FROM task_offers"))
        all_offers = result2.fetchall()
        print(f"All offers in DB: {len(all_offers)}")
        for o in all_offers:
            print(f"   -> ID={o[0]}, TaskID={o[1]}, HelperID={o[2]}, Price={o[3]}, Status={o[4]}")
        
        # Test task query
        result3 = await session.execute(text("SELECT id, client_id, title FROM tasks"))
        tasks = result3.fetchall()
        print(f"\nAll tasks in DB: {len(tasks)}")
        for t in tasks:
            print(f"   -> ID={t[0]}, ClientID={t[1]}, Title={t[2]}")
    
    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(test_offers())
