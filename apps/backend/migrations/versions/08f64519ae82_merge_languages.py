"""merge languages

Revision ID: 08f64519ae82
Revises: add_languages_column, fda2fd688f6e
Create Date: 2026-01-03 12:30:42.587251

"""
from alembic import op
import sqlalchemy as sa
import geoalchemy2


# revision identifiers, used by Alembic.
revision = '08f64519ae82'
down_revision = ('add_languages_column', 'fda2fd688f6e')
branch_labels = None
depends_on = None


def upgrade():
    pass


def downgrade():
    pass
