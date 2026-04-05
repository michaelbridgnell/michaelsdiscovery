"""add city to post

Revision ID: d8e9f0a1b2c3
Revises: c7d8e9f0a1b2
Create Date: 2026-04-05
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect

revision = 'd8e9f0a1b2c3'
down_revision = 'c7d8e9f0a1b2'
branch_labels = None
depends_on = None


def upgrade():
    bind = op.get_bind()
    cols = [c['name'] for c in inspect(bind).get_columns('post')]
    if 'city' not in cols:
        op.add_column('post', sa.Column('city', sa.String(100), nullable=True))


def downgrade():
    op.drop_column('post', 'city')
