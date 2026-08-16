from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Any
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


SUPPORTED_ENTITY_TYPES = frozenset(
    {
        "product",
        "inventory_item",
        "customer",
        "account",
        "journal_entry",
        "sale",
        "financial_transaction",
    }
)


class SyncOperationType(str, Enum):
    create = "create"
    update = "update"
    delete = "delete"


class SyncOperationIn(BaseModel):
    """
    Mirrors Flutter SyncOperation fields used by RemoteSyncApi.push.

    Flutter field mapping:
      id            → operation_id
      entityType    → entity_type (also passed at request level)
      entityId      → entity_id
      type          → type
      payload       → payload
      baseVersion   → base_version
    """

    model_config = ConfigDict(extra="ignore")

    operation_id: UUID
    entity_type: str
    entity_id: UUID
    type: SyncOperationType
    payload: dict[str, Any] = Field(default_factory=dict)
    base_version: int = 0


class SyncPushRequest(BaseModel):
    """Single-operation push (matches Flutter RemoteSyncApi.push one-at-a-time)."""

    model_config = ConfigDict(extra="ignore")

    entity_type: str
    operation: SyncOperationIn


class SyncBatchPushRequest(BaseModel):
    """Optional batch push for multi-op testing."""

    model_config = ConfigDict(extra="ignore")

    operations: list[SyncOperationIn]


class SyncUploadAckOut(BaseModel):
    """Matches Flutter SyncUploadAck."""

    entity_id: str
    remote_version: int
    remote_updated_at: datetime
    server_payload: dict[str, Any] | None = None
    status: str = "success"
    operation_id: str | None = None


class SyncPushResultItem(BaseModel):
    operation_id: str
    status: str
    ack: SyncUploadAckOut | None = None
    conflict: dict[str, Any] | None = None
    error: dict[str, Any] | None = None


class SyncBatchPushResponse(BaseModel):
    results: list[SyncPushResultItem]


class SyncRemoteChangeOut(BaseModel):
    """Matches Flutter SyncRemoteChange (+ sequence for cursor clients)."""

    entity_id: str
    entity_type: str
    version: int
    updated_at: datetime
    payload: dict[str, Any]
    deleted: bool = False
    sequence: int | None = None
    operation: str | None = None


class SyncPullResponse(BaseModel):
    """
    Pull response.

    Flutter HttpRemoteSyncApi uses `changes` (list of SyncRemoteChange).
    `next_cursor` / `has_more` enable proper incremental sync for multi-device.
    """

    changes: list[SyncRemoteChangeOut]
    next_cursor: int
    has_more: bool = False


class RemoteEntityMetaOut(BaseModel):
    """Matches Flutter RemoteEntityMeta."""

    entity_id: str
    version: int
    updated_at: datetime
    payload: dict[str, Any] | None = None


class HealthResponse(BaseModel):
    status: str
    database: str
    app: str
    env: str
