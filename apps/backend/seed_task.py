from app.core.database import AsyncSessionLocal
from app.models.models import Task, TaskStatus, Review, Payment, TaskOffer, TaskThread, Message, TaskAssignment, TaskProof, TaskMessage
from app.models.user import User
from app.models.address import Address
from app.models.payment_method import PaymentMethod
from app.models.user_document import UserDocument
from geoalchemy2.elements import WKTElement
import asyncio
from sqlalchemy.future import select

async def seed_task():
    async with AsyncSessionLocal() as session:
        # Get Client
        email = "test@test.it"
        result = await session.execute(select(User).where(User.email == email))
        client = result.scalars().first()
        
        if not client:
            print(f"Client {email} not found. Run seed_user.py first.")
            return

        # Check if task exists (id=1 ideally, but just any task)
        # We try to force id=1 if possible or just create one.
        # Postgres sequences handle IDs, so valid way is just insert.
        
        # Check if we already have tasks
        result = await session.execute(select(Task).where(Task.client_id == client.id))
        task = result.scalars().first()
        
        if not task:
            print("Creating Task...")
            task = Task(
                client_id=client.id,
                title="Test Task for Chat",
                description="I need help with something.",
                category="General",
                price_cents=1000,
                status=TaskStatus.POSTED,
                location=WKTElement('POINT(12.4964 41.9028)', srid=4326), # Rome
                address_line="Via Roma 1",
                city="Roma",
                urgency="asap"
            )
            session.add(task)
            await session.commit()
            print(f"Task created with ID: {task.id}")
        else:
            print(f"Task already exists with ID: {task.id}")

if __name__ == "__main__":
    asyncio.run(seed_task())
