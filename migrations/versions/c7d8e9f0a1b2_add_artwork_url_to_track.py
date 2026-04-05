"""add artwork_url to track

Revision ID: c7d8e9f0a1b2
Revises: b5c6d7e8f9a0
Create Date: 2026-04-05
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect

revision = 'c7d8e9f0a1b2'
down_revision = 'b5c6d7e8f9a0'
branch_labels = None
depends_on = None


def upgrade():
    bind = op.get_bind()
    cols = [c['name'] for c in inspect(bind).get_columns('track')]
    if 'artwork_url' not in cols:
        op.add_column('track', sa.Column('artwork_url', sa.String(500), nullable=True))


def downgrade():
    op.drop_column('track', 'artwork_url')
