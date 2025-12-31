import asyncio
from sqlalchemy import text
from app.core.database import engine

async def migrate():
    async with engine.begin() as conn:
        print("Migrating tasks table...")
        try:
            await conn.execute(text("ALTER TABLE tasks ADD COLUMN urgency VARCHAR"))
            print("Added urgency")
        except Exception as e:
            print(f"urgency error (ignored): {e}")

        try:
            await conn.execute(text("ALTER TABLE tasks ADD COLUMN category VARCHAR"))
            print("Added category")
        except Exception as e:
            print(f"category error (ignored): {e}")

        try:
            await conn.execute(text("ALTER TABLE tasks ADD COLUMN address_line VARCHAR"))
            print("Added address_line")
        except Exception as e:
            print(f"address_line error (ignored): {e}")

        try:
            await conn.execute(text("ALTER TABLE tasks ADD COLUMN city VARCHAR"))
            print("Added city")
        except Exception as e:
            print(f"city error (ignored): {e}")

        try:
            await conn.execute(text("ALTER TABLE tasks ADD COLUMN scheduled_at TIMESTAMPTZ"))
            print("Added scheduled_at")
        except Exception as e:
            print(f"scheduled_at error (ignored): {e}")

        print("Migrating task_messages table...")
        try:
            await conn.execute(text("ALTER TABLE task_messages ADD COLUMN type VARCHAR DEFAULT 'text'"))
            print("Added type")
        except Exception as e:
            print(f"type error (ignored): {e}")

        try:
            await conn.execute(text("ALTER TABLE task_messages ADD COLUMN payload JSON DEFAULT '{}'"))
            print("Added payload")
        except Exception as e:
            print(f"payload error (ignored): {e}")
            
    print("Migration complete.")

if __name__ == "__main__":
    asyncio.run(migrate())
