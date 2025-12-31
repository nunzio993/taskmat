
import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select
from app.models.models import Task, TaskOffer, TaskThread
from app.models.user import User
from app.models.address import Address
from app.models.payment_method import PaymentMethod
from app.models.user_document import UserDocument

DB_URL = "postgresql+asyncpg://user:password@localhost:5432/taskmate"

async def create_test_data():
    engine = create_async_engine(DB_URL)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        # 1. Get Client (ID 2) and Helper (ID 3)
        client = await session.get(User, 2)
        helper = await session.get(User, 3)
        
        if not client or not helper:
            print("Client or Helper not found!")
            return

        print(f"Creating task for Client: {client.email}")

        # 2. Create Task
        new_task = Task(
            client_id=client.id,
            title="Test Chat Button",
            description="Task for debugging chat button",
            category="General",
            price_cents=5000,
            urgency="low",
            status="posted",
            location="POINT(12.4964 41.9028)"
        )
        session.add(new_task)
        await session.flush()
        print(f"Created Task ID: {new_task.id}")

        # 3. Create Offer
        offer = TaskOffer(
            task_id=new_task.id,
            helper_id=helper.id,
            price_cents=4500,
            message="I can help with this debug task!",
            status="submitted"
        )
        session.add(offer)
        await session.flush()
        print(f"Created Offer ID: {offer.id}")

        # 4. Ensure Thread Exists
        # Check if thread exists
        stmt = select(TaskThread).where(
            TaskThread.task_id == new_task.id,
            TaskThread.helper_id == helper.id
        )
        result = await session.execute(stmt)
        thread = result.scalars().first()

        if not thread:
            print("Creating new chat thread...")
            thread = TaskThread(
                task_id=new_task.id,
                client_id=client.id,
                helper_id=helper.id
            )
            session.add(thread)
            await session.flush()
            print(f"Created Thread ID: {thread.id}")
        else:
            print(f"Thread already exists: {thread.id}")

        await session.commit()
        print("Done! Test data ready.")

    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(create_test_data())
