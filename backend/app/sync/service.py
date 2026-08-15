from __future__ import annotations

import copy
import uuid
from datetime import datetime, timezone
from typing import Any

from sqlalchemy import select, text
from sqlalchemy.orm import Session

from app.core.exceptions import ConflictError, NotFoundError, ValidationAppError
from app.core.logging import sync_logger
from app.models.sync import (
    Company,
    SyncChange,
    SyncEntity,
    SyncOperationRecord,
    SyncSequence,
)
from app.sync.schemas import (
    SUPPORTED_ENTITY_TYPES,
    SyncOperationIn,
    SyncOperationType,
    SyncRemoteChangeOut,
    SyncUploadAckOut,
)


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


class SyncService:
    """
    Generic experimental sync engine.

    Adapts to Flutter RemoteSyncApi / InMemoryRemoteSyncApi semantics:
    - UUID identity
    - server-authoritative versions
    - soft deletes
    - conflict when server.version > base_version
    - idempotent by operation_id
    """

    def __init__(self, db: Session) -> None:
        self.db = db

    def ensure_company(self, company_id: uuid.UUID) -> Company:
        company = self.db.get(Company, company_id)
        if company is not None:
            return company
        company = Company(id=company_id, name=f"Dev Company {company_id}")
        self.db.add(company)
        self.db.flush()
        self.db.add(SyncSequence(company_id=company_id, next_value=1))
        self.db.flush()
        return company

    def _next_sequence(self, company_id: uuid.UUID) -> int:
        seq = self.db.get(SyncSequence, company_id)
        if seq is None:
            seq = SyncSequence(company_id=company_id, next_value=1)
            self.db.add(seq)
            self.db.flush()
        # Lock row for concurrent device safety.
        locked = self.db.execute(
            select(SyncSequence)
            .where(SyncSequence.company_id == company_id)
            .with_for_update()
        ).scalar_one()
        value = locked.next_value
        locked.next_value = value + 1
        self.db.flush()
        return value

    def _get_entity(
        self,
        company_id: uuid.UUID,
        entity_type: str,
        entity_uuid: uuid.UUID,
        *,
        for_update: bool = False,
    ) -> SyncEntity | None:
        stmt = select(SyncEntity).where(
            SyncEntity.company_id == company_id,
            SyncEntity.entity_type == entity_type,
            SyncEntity.entity_uuid == entity_uuid,
        )
        if for_update:
            stmt = stmt.with_for_update()
        return self.db.execute(stmt).scalar_one_or_none()

    def _validate_operation(self, op: SyncOperationIn) -> None:
        if op.entity_type not in SUPPORTED_ENTITY_TYPES:
            raise ValidationAppError(
                f"Unsupported entity_type: {op.entity_type}",
                details={"supported": sorted(SUPPORTED_ENTITY_TYPES)},
            )
        if op.base_version < 0:
            raise ValidationAppError("base_version must be >= 0")

    def _payload_for_store(
        self,
        op: SyncOperationIn,
        *,
        deleted: bool,
        version: int,
        updated_at: datetime,
        deleted_at: datetime | None,
    ) -> dict[str, Any]:
        payload = copy.deepcopy(op.payload) if op.payload else {}
        # Normalize identity keys used by Flutter handlers.
        if op.entity_type == "inventory_item":
            payload["id"] = str(op.entity_id)
        else:
            payload["uuid"] = str(op.entity_id)
        payload["version"] = version
        payload["updatedAt"] = int(updated_at.timestamp() * 1000)
        if deleted:
            payload["deleted"] = True
            if deleted_at is not None:
                payload["deletedAt"] = int(deleted_at.timestamp() * 1000)
        elif "deleted" in payload:
            payload.pop("deleted", None)
        return payload

    def _ack_from_entity(
        self,
        entity: SyncEntity,
        *,
        operation_id: uuid.UUID | None = None,
    ) -> SyncUploadAckOut:
        return SyncUploadAckOut(
            entity_id=str(entity.entity_uuid),
            remote_version=entity.version,
            remote_updated_at=entity.updated_at,
            server_payload=copy.deepcopy(entity.payload),
            status="success",
            operation_id=str(operation_id) if operation_id else None,
        )

    def _record_change(
        self,
        *,
        company_id: uuid.UUID,
        entity: SyncEntity,
        operation: str,
    ) -> int:
        sequence = self._next_sequence(company_id)
        change = SyncChange(
            sequence=sequence,
            company_id=company_id,
            entity_type=entity.entity_type,
            entity_uuid=entity.entity_uuid,
            operation=operation,
            version=entity.version,
            payload=copy.deepcopy(entity.payload),
            deleted=entity.deleted_at is not None,
            created_at=utcnow(),
        )
        self.db.add(change)
        self.db.flush()
        return sequence

    def _save_operation_result(
        self,
        *,
        company_id: uuid.UUID,
        user_id: uuid.UUID | None,
        device_id: uuid.UUID | None,
        op: SyncOperationIn,
        status: str,
        result: dict[str, Any],
    ) -> None:
        record = SyncOperationRecord(
            company_id=company_id,
            operation_id=op.operation_id,
            entity_type=op.entity_type,
            entity_uuid=op.entity_id,
            operation_type=op.type.value,
            status=status,
            result=result,
            user_id=user_id,
            device_id=device_id,
            processed_at=utcnow(),
        )
        self.db.add(record)
        self.db.flush()

    def get_prior_operation(
        self, company_id: uuid.UUID, operation_id: uuid.UUID
    ) -> SyncOperationRecord | None:
        return self.db.execute(
            select(SyncOperationRecord).where(
                SyncOperationRecord.company_id == company_id,
                SyncOperationRecord.operation_id == operation_id,
            )
        ).scalar_one_or_none()

    def push_operation(
        self,
        *,
        company_id: uuid.UUID,
        user_id: uuid.UUID,
        device_id: uuid.UUID,
        op: SyncOperationIn,
    ) -> SyncUploadAckOut:
        self.ensure_company(company_id)
        self._validate_operation(op)

        prior = self.get_prior_operation(company_id, op.operation_id)
        if prior is not None:
            sync_logger.info(
                "PUSH duplicate operation_id=%s entity_type=%s status=%s",
                op.operation_id,
                op.entity_type,
                prior.status,
            )
            if prior.status == "success":
                return SyncUploadAckOut.model_validate(prior.result)
            if prior.status == "conflict":
                details = prior.result
                raise ConflictError(
                    details.get("message", "Synchronization conflict"),
                    entity_type=details.get("entity_type", op.entity_type),
                    entity_id=details.get("entity_id", str(op.entity_id)),
                    server_version=int(details.get("server_version", 0)),
                    client_base_version=int(
                        details.get("client_base_version", op.base_version)
                    ),
                    server_record=details.get("server_record") or {},
                    server_updated_at=details.get("server_updated_at"),
                )
            raise ValidationAppError(
                f"Previous operation ended with status={prior.status}"
            )

        sync_logger.info(
            "PUSH received operation_id=%s entity_type=%s entity_id=%s type=%s base_version=%s",
            op.operation_id,
            op.entity_type,
            op.entity_id,
            op.type.value,
            op.base_version,
        )

        try:
            ack = self._apply_mutation(
                company_id=company_id,
                op=op,
            )
        except ConflictError as exc:
            self._save_operation_result(
                company_id=company_id,
                user_id=user_id,
                device_id=device_id,
                op=op,
                status="conflict",
                result={
                    "message": exc.message,
                    **exc.details,
                },
            )
            sync_logger.info(
                "PUSH conflict operation_id=%s entity_type=%s entity_id=%s",
                op.operation_id,
                op.entity_type,
                op.entity_id,
            )
            raise

        self._save_operation_result(
            company_id=company_id,
            user_id=user_id,
            device_id=device_id,
            op=op,
            status="success",
            result=ack.model_dump(mode="json"),
        )
        sync_logger.info(
            "PUSH success operation_id=%s entity_type=%s entity_id=%s version=%s",
            op.operation_id,
            op.entity_type,
            op.entity_id,
            ack.remote_version,
        )
        return ack

    def _raise_conflict(
        self,
        *,
        entity: SyncEntity,
        op: SyncOperationIn,
    ) -> None:
        raise ConflictError(
            f"Remote version {entity.version} > base {op.base_version}",
            entity_type=op.entity_type,
            entity_id=str(op.entity_id),
            server_version=entity.version,
            client_base_version=op.base_version,
            server_record=copy.deepcopy(entity.payload),
            server_updated_at=entity.updated_at.isoformat(),
        )

    def _apply_mutation(
        self,
        *,
        company_id: uuid.UUID,
        op: SyncOperationIn,
    ) -> SyncUploadAckOut:
        existing = self._get_entity(
            company_id, op.entity_type, op.entity_id, for_update=True
        )
        now = utcnow()

        # Match InMemoryRemoteSyncApi conflict rule.
        if existing is not None and existing.version > op.base_version:
            self._raise_conflict(entity=existing, op=op)

        if op.type == SyncOperationType.create:
            if existing is not None:
                # Idempotent create for same UUID when versions are compatible:
                # return current authoritative state (no duplicate row).
                return self._ack_from_entity(existing, operation_id=op.operation_id)

            version = (op.base_version or 0) + 1
            payload = self._payload_for_store(
                op,
                deleted=False,
                version=version,
                updated_at=now,
                deleted_at=None,
            )
            entity = SyncEntity(
                company_id=company_id,
                entity_type=op.entity_type,
                entity_uuid=op.entity_id,
                version=version,
                payload=payload,
                created_at=now,
                updated_at=now,
                deleted_at=None,
            )
            self.db.add(entity)
            self.db.flush()
            self._record_change(
                company_id=company_id, entity=entity, operation="create"
            )
            return self._ack_from_entity(entity, operation_id=op.operation_id)

        if existing is None:
            if op.type == SyncOperationType.delete:
                # Tombstone create for delete of unknown entity (offline race).
                version = (op.base_version or 0) + 1
                payload = self._payload_for_store(
                    op,
                    deleted=True,
                    version=version,
                    updated_at=now,
                    deleted_at=now,
                )
                entity = SyncEntity(
                    company_id=company_id,
                    entity_type=op.entity_type,
                    entity_uuid=op.entity_id,
                    version=version,
                    payload=payload,
                    created_at=now,
                    updated_at=now,
                    deleted_at=now,
                )
                self.db.add(entity)
                self.db.flush()
                self._record_change(
                    company_id=company_id, entity=entity, operation="delete"
                )
                return self._ack_from_entity(entity, operation_id=op.operation_id)
            raise NotFoundError(
                f"Entity {op.entity_type}/{op.entity_id} not found for {op.type.value}"
            )

        next_version = existing.version + 1
        deleted = op.type == SyncOperationType.delete
        deleted_at = now if deleted else None
        payload = self._payload_for_store(
            op,
            deleted=deleted,
            version=next_version,
            updated_at=now,
            deleted_at=deleted_at,
        )
        existing.version = next_version
        existing.payload = payload
        existing.updated_at = now
        existing.deleted_at = deleted_at if deleted else existing.deleted_at
        if not deleted and existing.deleted_at is not None:
            # Update after soft-delete restores the row.
            existing.deleted_at = None
            payload.pop("deleted", None)
            payload.pop("deletedAt", None)
            existing.payload = payload

        self.db.flush()
        self._record_change(
            company_id=company_id,
            entity=existing,
            operation=op.type.value,
        )
        return self._ack_from_entity(existing, operation_id=op.operation_id)

    def pull(
        self,
        *,
        company_id: uuid.UUID,
        entity_type: str | None,
        cursor: int | None,
        since: datetime | None,
        limit: int,
    ) -> tuple[list[SyncRemoteChangeOut], int, bool]:
        self.ensure_company(company_id)

        if entity_type is not None and entity_type not in SUPPORTED_ENTITY_TYPES:
            raise ValidationAppError(
                f"Unsupported entity_type: {entity_type}",
                details={"supported": sorted(SUPPORTED_ENTITY_TYPES)},
            )

        sync_logger.info(
            "PULL requested company=%s entity_type=%s cursor=%s since=%s limit=%s",
            company_id,
            entity_type,
            cursor,
            since.isoformat() if since else None,
            limit,
        )

        stmt = select(SyncChange).where(SyncChange.company_id == company_id)
        if entity_type:
            stmt = stmt.where(SyncChange.entity_type == entity_type)

        effective_cursor = cursor if cursor is not None else 0
        if cursor is not None:
            stmt = stmt.where(SyncChange.sequence > effective_cursor)
        elif since is not None:
            stmt = stmt.where(SyncChange.created_at > since)

        stmt = stmt.order_by(SyncChange.sequence.asc()).limit(limit + 1)
        rows = list(self.db.execute(stmt).scalars().all())
        has_more = len(rows) > limit
        rows = rows[:limit]

        changes = [
            SyncRemoteChangeOut(
                entity_id=str(row.entity_uuid),
                entity_type=row.entity_type,
                version=row.version,
                updated_at=row.created_at,
                payload=copy.deepcopy(row.payload),
                deleted=row.deleted,
                sequence=row.sequence,
                operation=row.operation,
            )
            for row in rows
        ]

        if rows:
            next_cursor = rows[-1].sequence
        elif cursor is not None:
            next_cursor = cursor
        else:
            # No changes: expose current high-water mark.
            seq = self.db.get(SyncSequence, company_id)
            next_cursor = (seq.next_value - 1) if seq and seq.next_value > 1 else 0

        sync_logger.info(
            "PULL returned n=%s next_cursor=%s has_more=%s",
            len(changes),
            next_cursor,
            has_more,
        )
        return changes, next_cursor, has_more

    def get_meta(
        self,
        *,
        company_id: uuid.UUID,
        entity_type: str,
        entity_id: uuid.UUID,
    ) -> SyncEntity | None:
        self.ensure_company(company_id)
        if entity_type not in SUPPORTED_ENTITY_TYPES:
            raise ValidationAppError(f"Unsupported entity_type: {entity_type}")
        return self._get_entity(company_id, entity_type, entity_id)

    def database_ok(self) -> bool:
        try:
            self.db.execute(text("SELECT 1"))
            return True
        except Exception:
            return False
