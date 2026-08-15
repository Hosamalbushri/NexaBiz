"""initial experimental sync schema

Revision ID: 001_experimental_sync
Revises:
Create Date: 2026-08-14
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "001_experimental_sync"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "companies",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("name", sa.String(length=200), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "sync_sequences",
        sa.Column("company_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("next_value", sa.BigInteger(), nullable=False),
        sa.ForeignKeyConstraint(["company_id"], ["companies.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("company_id"),
    )

    op.create_table(
        "sync_entities",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("company_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("entity_type", sa.String(length=64), nullable=False),
        sa.Column("entity_uuid", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("version", sa.Integer(), nullable=False),
        sa.Column("payload", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["company_id"], ["companies.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "company_id",
            "entity_type",
            "entity_uuid",
            name="uq_sync_entity_tenant_type_uuid",
        ),
    )
    op.create_index(
        "ix_sync_entities_company_id", "sync_entities", ["company_id"]
    )
    op.create_index(
        "ix_sync_entities_company_type",
        "sync_entities",
        ["company_id", "entity_type"],
    )
    op.create_index(
        "ix_sync_entities_company_updated",
        "sync_entities",
        ["company_id", "updated_at"],
    )

    op.create_table(
        "sync_changes",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("sequence", sa.BigInteger(), nullable=False),
        sa.Column("company_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("entity_type", sa.String(length=64), nullable=False),
        sa.Column("entity_uuid", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("operation", sa.String(length=16), nullable=False),
        sa.Column("version", sa.Integer(), nullable=False),
        sa.Column("payload", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("deleted", sa.Boolean(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["company_id"], ["companies.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "company_id",
            "sequence",
            name="uq_sync_changes_company_sequence",
        ),
    )
    op.create_index(
        "ix_sync_changes_company_type_sequence",
        "sync_changes",
        ["company_id", "entity_type", "sequence"],
    )

    op.create_table(
        "sync_operations",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("company_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("operation_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("entity_type", sa.String(length=64), nullable=False),
        sa.Column("entity_uuid", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("operation_type", sa.String(length=16), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("result", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("device_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column(
            "processed_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["company_id"], ["companies.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "company_id",
            "operation_id",
            name="uq_sync_operations_company_op",
        ),
    )


def downgrade() -> None:
    op.drop_table("sync_operations")
    op.drop_index(
        "ix_sync_changes_company_type_sequence", table_name="sync_changes"
    )
    op.drop_table("sync_changes")
    op.drop_index("ix_sync_entities_company_updated", table_name="sync_entities")
    op.drop_index("ix_sync_entities_company_type", table_name="sync_entities")
    op.drop_index("ix_sync_entities_company_id", table_name="sync_entities")
    op.drop_table("sync_entities")
    op.drop_table("sync_sequences")
    op.drop_table("companies")
