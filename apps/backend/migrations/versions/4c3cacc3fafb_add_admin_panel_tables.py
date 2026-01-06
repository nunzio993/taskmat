"""add_admin_panel_tables

Revision ID: 4c3cacc3fafb
Revises: 18c39cf0d2bc
Create Date: 2026-01-06 11:15:14.528948

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision = '4c3cacc3fafb'
down_revision = '18c39cf0d2bc'
branch_labels = None
depends_on = None


def upgrade():
    # Add admin columns to users
    op.add_column('users', sa.Column('is_admin', sa.Boolean(), nullable=True, server_default='false'))
    op.add_column('users', sa.Column('admin_role', sa.String(), nullable=True))
    
    # Note: category_settings and related tables already exist in DB
    # They were created directly, this migration just syncs the model


def downgrade():
    op.drop_column('users', 'admin_role')
    op.drop_column('users', 'is_admin')
