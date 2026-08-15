from __future__ import annotations

import uuid
from typing import Any

from sqlalchemy.orm import Session

from app.auth.tokens import utcnow
from app.models.identity import AuditLog


def write_audit(
    db: Session,
    *,
    action: str,
    user_id: uuid.UUID | None = None,
    company_id: uuid.UUID | None = None,
    device_id: uuid.UUID | None = None,
    entity_type: str | None = None,
    entity_id: str | None = None,
    metadata: dict[str, Any] | None = None,
    ip_address: str | None = None,
    user_agent: str | None = None,
) -> None:
    db.add(
        AuditLog(
            id=uuid.uuid4(),
            user_id=user_id,
            company_id=company_id,
            device_id=device_id,
            action=action,
            entity_type=entity_type,
            entity_id=entity_id,
            metadata_json=metadata or {},
            ip_address=ip_address,
            user_agent=user_agent,
            created_at=utcnow(),
        )
    )
