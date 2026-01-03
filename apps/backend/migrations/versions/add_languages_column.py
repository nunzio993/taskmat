"""add languages column to users

Revision ID: add_languages_column
Revises: 3051335b46ac
Create Date: 2026-01-03

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = 'add_languages_column'
down_revision: Union[str, None] = '3051335b46ac'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add languages column with default value
    op.add_column('users', sa.Column('languages', sa.JSON(), nullable=True, server_default='["Italiano"]'))


def downgrade() -> None:
    op.drop_column('users', 'languages')
