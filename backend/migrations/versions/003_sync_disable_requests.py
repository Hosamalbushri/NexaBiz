"""sync disable requests

Revision ID: 003_sync_disable_requests
Revises: 002_identity_rbac
Create Date: 2026-08-16
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "003_sync_disable_requests"
down_revision: Union[str, None] = "002_identity_rbac"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "sync_disable_requests",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "company_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("companies.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "device_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("devices.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("status", sa.String(length=32), nullable=False, server_default="pending"),
        sa.Column("message", sa.String(length=500), nullable=True),
        sa.Column(
            "resolved_by_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("resolved_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index(
        "ix_sync_disable_requests_company_status",
        "sync_disable_requests",
        ["company_id", "status"],
    )
    op.create_index(
        "ix_sync_disable_requests_device_id",
        "sync_disable_requests",
        ["device_id"],
    )


def downgrade() -> None:
    op.drop_index("ix_sync_disable_requests_device_id", table_name="sync_disable_requests")
    op.drop_index(
        "ix_sync_disable_requests_company_status",
        table_name="sync_disable_requests",
    )
    op.drop_table("sync_disable_requests")
