import asyncio
import os
import sys

# Add app to path
sys.path.append(os.getcwd())

from app.core.database import AsyncSessionLocal
from app.models.user import User
import app.models.models
import app.models.address
import app.models.payment_method
import app.models.user_document
from sqlalchemy import select

GENERIC_NAMES = [
    ("Mario", "Rossi"),
    ("Luigi", "Verdi"),
    ("Anna", "Bianchi"),
    ("Giulia", "Neri"),
    ("Francesca", "Gialli"),
    ("Antonio", "Viola"),
    ("Sofia", "Marrone"),
    ("Marco", "Ferrari"),
]

async def fix_users():
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(User))
        users = result.scalars().all()
        
        print(f"Found {len(users)} users. Checking for missing/incomplete names...")
        
        updated_count = 0
        for i, user in enumerate(users):
            current_name = user.name or ""
            parts = current_name.split()
            
            new_name = None
            if len(parts) < 2:
                # Assign a generic name based on ID to be deterministic but varied
                first, last = GENERIC_NAMES[user.id % len(GENERIC_NAMES)]
                # If they had a name, keep it as first name if reasonable
                if parts and len(parts[0]) > 2:
                    first = parts[0]
                
                new_name = f"{first} {last}"
            
            if new_name:
                print(f"Updating User {user.id} ({user.email}): '{current_name}' -> '{new_name}'")
                user.name = new_name
                updated_count += 1
                
        if updated_count > 0:
            await db.commit()
            print(f"Successfully updated {updated_count} users.")
        else:
            print("No users needed updating.")

if __name__ == "__main__":
    # Ensure we assume we are running from 'apps/backend'
    if not os.path.exists("app"):
        print("Error: Please run this script from 'd:/taskmat/apps/backend' directory")
        sys.exit(1)
        
    asyncio.run(fix_users())
