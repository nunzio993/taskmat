
import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select
from app.core.config import settings
from app.models.models import Task, TaskOffer
from app.models.user import User
from app.models.address import Address
from app.models.payment_method import PaymentMethod
from app.models.user_document import UserDocument

# DB_URL = settings.DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://")
DB_URL = "postgresql+asyncpg://user:password@localhost:5432/taskmate"

async def check_db():
    print(f"Connecting to {DB_URL}...")
    engine = create_async_engine(DB_URL)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        print("\n--- USERS ---")
        users = await session.execute(select(User))
        for u in users.scalars().all():
            print(f"ID: {u.id}, Email: {u.email}, Role: {u.role}")

        print("\n--- TASKS ---")
        tasks = await session.execute(select(Task))
        all_tasks = tasks.scalars().all()
        for t in all_tasks:
            print(f"Task ID: {t.id}, ClientID: {t.client_id}, Title: {t.title}, Status: {t.status}")

        print("\n--- OFFERS ---")
        offers = await session.execute(select(TaskOffer))
        all_offers = offers.scalars().all()
        for o in all_offers:
            print(f"Offer ID: {o.id}, TaskID: {o.task_id}, HelperID: {o.helper_id}, Price: {o.price_cents}")
        
        print("\n--- LINK CHECK ---")
        for t in all_tasks:
            related_offers = [o for o in all_offers if o.task_id == t.id]
            print(f"Task {t.id} has {len(related_offers)} offers in DB.")

    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(check_db())
