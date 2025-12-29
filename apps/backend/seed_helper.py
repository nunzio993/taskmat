from app.core.database import SessionLocal
from app.models.models import User, HelperProfile
import asyncio

async def seed_helper():
    async with SessionLocal() as session:
        # Check if user 99 exists
        user = await session.get(User, 99)
        if not user:
            user = User(id=99, contact="helper_99", display_name="Test Helper", role="helper")
            session.add(user)
            await session.flush()
            
        # Check if profile exists
        profile = await session.get(HelperProfile, 99)
        if not profile:
            profile = HelperProfile(user_id=99, radius_km=10, is_available=True)
            session.add(profile)
            await session.commit()
            print("Helper 99 seeded.")

if __name__ == "__main__":
    asyncio.run(seed_helper())
