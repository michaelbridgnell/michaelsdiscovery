"""add email and posts

Revision ID: a3f1b2c4d5e6
Revises: 1700d2affb44
Create Date: 2026-04-04 20:00:00.000000

"""
from alembic import op
import sqlalchemy as sa

revision = 'a3f1b2c4d5e6'
down_revision = '1700d2affb44'
branch_labels = None
depends_on = None


def upgrade():
    # Add email column to user (nullable so existing rows are unaffected)
    with op.batch_alter_table('user', schema=None) as batch_op:
        batch_op.add_column(sa.Column('email', sa.String(length=255), nullable=True))
        batch_op.create_unique_constraint('uq_user_email', ['email'])

    # Create post table
    op.create_table(
        'post',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), sa.ForeignKey('user.id'), nullable=False),
        sa.Column('username', sa.String(length=80), nullable=False),
        sa.Column('content', sa.String(length=280), nullable=False),
        sa.Column('category', sa.String(length=50), nullable=False, server_default='General'),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        if_not_exists=True
    )


def downgrade():
    op.drop_table('post')
    with op.batch_alter_table('user', schema=None) as batch_op:
        batch_op.drop_constraint('uq_user_email', type_='unique')
        batch_op.drop_column('email')
