"""add password reset codes

Revision ID: b5c6d7e8f9a0
Revises: a3f1b2c4d5e6
Create Date: 2026-04-05 10:00:00.000000

"""
from alembic import op
import sqlalchemy as sa

revision = 'b5c6d7e8f9a0'
down_revision = 'a3f1b2c4d5e6'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'password_reset_code',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), sa.ForeignKey('user.id'), nullable=False),
        sa.Column('code', sa.String(length=6), nullable=False),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('used', sa.Boolean(), nullable=False, server_default='0'),
        sa.PrimaryKeyConstraint('id'),
        if_not_exists=True
    )


def downgrade():
    op.drop_table('password_reset_code')
