from __future__ import annotations

import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.auth.deps import AuthContext, get_auth_context
from app.core.config import Settings, get_settings
from app.core.database import get_db
from app.core.exceptions import AppError, ConflictError, ValidationAppError
from app.sync.schemas import (
    HealthResponse,
    RemoteEntityMetaOut,
    SyncBatchPushRequest,
    SyncBatchPushResponse,
    SyncOperationIn,
    SyncPullResponse,
    SyncPushRequest,
    SyncPushResultItem,
    SyncUploadAckOut,
)
from app.sync.service import SyncService

router = APIRouter()
sync_router = APIRouter(prefix="/api/v1/sync", tags=["sync"])


@router.get("/health", response_model=HealthResponse, tags=["health"])
def health(
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> HealthResponse:
    ok = SyncService(db).database_ok()
    return HealthResponse(
        status="ok" if ok else "degraded",
        database="ok" if ok else "error",
        app=settings.app_name,
        env=settings.app_env,
    )


@sync_router.post(
    "/push",
    response_model=SyncUploadAckOut,
    summary="Push one SyncOperation (Flutter RemoteSyncApi.push)",
)
def push_one(
    body: SyncPushRequest,
    db: Session = Depends(get_db),
    auth: AuthContext = Depends(get_auth_context),
) -> SyncUploadAckOut:
    op = body.operation
    if op.entity_type != body.entity_type:
        # Allow entity_type only on wrapper; normalize.
        op = SyncOperationIn(
            operation_id=op.operation_id,
            entity_type=body.entity_type,
            entity_id=op.entity_id,
            type=op.type,
            payload=op.payload,
            base_version=op.base_version,
        )
    service = SyncService(db)
    try:
        ack = service.push_operation(
            company_id=auth.company_id,
            user_id=auth.user_id,
            device_id=auth.device_id,
            op=op,
        )
        db.commit()
        return ack
    except Exception:
        db.rollback()
        raise


@sync_router.post(
    "/push/batch",
    response_model=SyncBatchPushResponse,
    summary="Push multiple SyncOperations with per-operation results",
)
def push_batch(
    body: SyncBatchPushRequest,
    db: Session = Depends(get_db),
    auth: AuthContext = Depends(get_auth_context),
) -> SyncBatchPushResponse:
    if not body.operations:
        raise ValidationAppError("operations must not be empty")

    service = SyncService(db)
    results: list[SyncPushResultItem] = []

    for op in body.operations:
        # Each operation commits independently so one failure does not
        # incorrectly mark siblings as successful after a full rollback.
        try:
            ack = service.push_operation(
                company_id=auth.company_id,
                user_id=auth.user_id,
                device_id=auth.device_id,
                op=op,
            )
            db.commit()
            results.append(
                SyncPushResultItem(
                    operation_id=str(op.operation_id),
                    status="success",
                    ack=ack,
                )
            )
        except ConflictError as exc:
            db.rollback()
            results.append(
                SyncPushResultItem(
                    operation_id=str(op.operation_id),
                    status="conflict",
                    conflict=exc.details,
                    error={"code": exc.code, "message": exc.message},
                )
            )
        except AppError as exc:
            db.rollback()
            results.append(
                SyncPushResultItem(
                    operation_id=str(op.operation_id),
                    status="error",
                    error={
                        "code": exc.code,
                        "message": exc.message,
                        "details": exc.details,
                    },
                )
            )
        except Exception as exc:  # noqa: BLE001
            db.rollback()
            results.append(
                SyncPushResultItem(
                    operation_id=str(op.operation_id),
                    status="error",
                    error={"code": "server_error", "message": str(exc)},
                )
            )

    return SyncBatchPushResponse(results=results)


@sync_router.get(
    "/pull",
    response_model=SyncPullResponse,
    summary="Incremental pull (cursor preferred; since for Flutter SyncManager)",
)
def pull(
    entity_type: str | None = Query(
        default=None,
        description="Flutter entity type key, e.g. customer, product",
    ),
    cursor: int | None = Query(
        default=None,
        ge=0,
        description="Return changes with sequence > cursor",
    ),
    since: datetime | None = Query(
        default=None,
        description="Flutter SyncManager _lastSyncedAt (UTC). Used when cursor omitted.",
    ),
    limit: int | None = Query(default=None, ge=1, le=2000),
    db: Session = Depends(get_db),
    auth: AuthContext = Depends(get_auth_context),
    settings: Settings = Depends(get_settings),
) -> SyncPullResponse:
    service = SyncService(db)
    page_limit = limit or settings.sync_pull_limit
    changes, next_cursor, has_more = service.pull(
        company_id=auth.company_id,
        entity_type=entity_type,
        cursor=cursor,
        since=since,
        limit=page_limit,
    )
    return SyncPullResponse(
        changes=changes,
        next_cursor=next_cursor,
        has_more=has_more,
    )


@sync_router.get(
    "/meta/{entity_type}/{entity_id}",
    response_model=RemoteEntityMetaOut | None,
    summary="Remote metadata probe (Flutter RemoteSyncApi.getMeta)",
)
def get_meta(
    entity_type: str,
    entity_id: uuid.UUID,
    db: Session = Depends(get_db),
    auth: AuthContext = Depends(get_auth_context),
) -> RemoteEntityMetaOut | None:
    service = SyncService(db)
    entity = service.get_meta(
        company_id=auth.company_id,
        entity_type=entity_type,
        entity_id=entity_id,
    )
    if entity is None:
        return None
    return RemoteEntityMetaOut(
        entity_id=str(entity.entity_uuid),
        version=entity.version,
        updated_at=entity.updated_at,
        payload=entity.payload,
    )
