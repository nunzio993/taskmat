"""add_stripe_connect_fields

Revision ID: 48650be23d4d
Revises: 4c3cacc3fafb
Create Date: 2026-01-06 15:01:22.163233

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '48650be23d4d'
down_revision = '4c3cacc3fafb'
branch_labels = None
depends_on = None


def upgrade():
    # Add Stripe Connect columns
    op.add_column('users', sa.Column('stripe_account_id', sa.String(), nullable=True))
    op.add_column('users', sa.Column('stripe_onboarding_complete', sa.Boolean(), nullable=True, server_default='false'))


def downgrade():
    op.drop_column('users', 'stripe_onboarding_complete')
    op.drop_column('users', 'stripe_account_id')
