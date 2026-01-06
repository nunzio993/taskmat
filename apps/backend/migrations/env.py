import asyncio
from logging.config import fileConfig

from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config

from alembic import context

# Import models for autogenerate support
from app.core.database import Base
from app.models.user import User
from app.models.models import Task, TaskAssignment, Payment, Message, Review, SystemSetting, TaskOffer, TaskThread, TaskMessage, TaskProof
from app.models.address import Address
from app.models.payment_method import PaymentMethod
from app.models.user_document import UserDocument
from app.models.category_settings import CategorySettings, CategorySettingsVersion, GlobalSettingsVersion
from app.core.config import settings

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata

def include_object(object, name, type_, reflected, compare_to):
    if type_ == "table":
        # Ignore PostGIS/Tiger tables
        if name in ["spatial_ref_sys", "layer", "topology"]:
            return False
        if name and (
            name == "addr" or 
            name.startswith("addrfeat") or
            name.startswith("bg") or
            name.startswith("county") or
            name.startswith("cousub") or
            name.startswith("direction_") or
            name.startswith("edges") or
            name.startswith("face") or
            name.startswith("featnames") or
            name.startswith("geocode_") or
            name.startswith("loader_") or
            name.startswith("pagc_") or
            name.startswith("place") or
            name.startswith("secondary_") or
            name.startswith("state") or
            name.startswith("street_") or
            name.startswith("tabblock") or
            name.startswith("tiger_") or
            name.startswith("tract") or
            name.startswith("zcta5") or
            name.startswith("zip_")
        ):
            return False
    return True

def run_migrations_offline() -> None:
    url = settings.DATABASE_URL
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        include_object=include_object,
    )

    with context.begin_transaction():
        context.run_migrations()

def do_run_migrations(connection: Connection) -> None:
    context.configure(
        connection=connection, 
        target_metadata=target_metadata,
        include_object=include_object,
    )

    with context.begin_transaction():
        context.run_migrations()

async def run_migrations_online() -> None:
    configuration = config.get_section(config.config_ini_section)
    configuration["sqlalchemy.url"] = settings.DATABASE_URL
    
    connectable = async_engine_from_config(
        configuration,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)

    await connectable.dispose()

if context.is_offline_mode():
    run_migrations_offline()
else:
    asyncio.run(run_migrations_online())
