from app.core.database import AsyncSessionLocal
from app.models.user import User
from app.models.models import UserRole
# Import other models to ensure registry is populated for relationships
from app.models.models import Task, Review, Payment, TaskOffer, TaskThread, Message, TaskAssignment, TaskProof, TaskMessage
from app.models.address import Address
from app.models.payment_method import PaymentMethod
from app.models.user_document import UserDocument
from app.core import security
import asyncio
from sqlalchemy.future import select

async def seed_users():
    async with AsyncSessionLocal() as session:
        users_to_create = [
            {
                "email": "test@test.it",
                "password": "testtt",
                "role": UserRole.CLIENT,
                "name": "Test Client",
                "is_available": True
            },
            {
                "email": "helper@test.it",
                "password": "testtt",
                "role": UserRole.HELPER,
                "name": "Test Helper",
                "is_available": True
            }
        ]

        for user_data in users_to_create:
            result = await session.execute(select(User).where(User.email == user_data["email"]))
            user = result.scalars().first()
            
            if not user:
                print(f"Creating user {user_data['email']}...")
                user = User(
                    email=user_data["email"],
                    hashed_password=security.get_password_hash(user_data["password"]),
                    role=user_data["role"],
                    name=user_data["name"],
                    is_available=user_data["is_available"],
                    preferences={},
                    readiness_status={}
                )
                session.add(user)
                await session.flush() # Flush to get ID if needed
                
                # If helper, maybe add dummy profile if needed (checking models.py)
                # HelperProfile seems to be in models.py but not linked in User directly in the snippet I saw?
                # Let's check models.py again if I need to add HelperProfile. 
                # Converting previous seed_helper.py logic:
                if user_data["role"] == UserRole.HELPER:
                     # Check if HelperProfile exists (it uses same ID as user in previous legacy code, or user_id?)
                     # models.py says: class HelperProfile(Base): ... user_id = Column(Integer, ForeignKey("users.id"))
                     # Wait, I didn't see HelperProfile in the models.py view earlier, let me check.
                     # Ah, in the previous `view_file` of models.py I saw UserRole but I didn't see HelperProfile class definition?
                     # Wait, line 2 of models.py: from app.models.models import User, HelperProfile
                     # But I was viewing models.py. 
                     # Let's look at models.py content again in my context.
                     # Snippet 187 showed lines 1-220. I didn't see HelperProfile class there.
                     # Snippet 182 (seed_helper.py) imported HelperProfile from app.models.models.
                     # It might be further down in models.py or I missed it.
                     # Regardless, the user request is just for the accounts. I will stick to creating the User objects first.
                     pass

                print(f"User {user_data['email']} created.")
            else:
                print(f"User {user_data['email']} already exists. Updating password...")
                user.hashed_password = security.get_password_hash(user_data["password"])
                session.add(user)
                print(f"User {user_data['email']} password updated.")
        
        await session.commit()
        print("Seeding complete.")

if __name__ == "__main__":
    asyncio.run(seed_users())
