"""Authorization helpers — always check permissions, never role names."""

from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.auth.permissions_catalog import SYNC_ENTITY_PERMISSIONS, SYNC_EXECUTE
from app.auth.errors import PermissionDeniedError
from app.models.identity import (
    CompanyUser,
    Permission,
    RolePermission,
    User,
)


def load_permission_codes(
    db: Session,
    *,
    user: User,
    company_id: uuid.UUID | None,
) -> set[str]:
    if user.is_super_admin:
        rows = db.execute(select(Permission.code)).scalars().all()
        return set(rows)

    if company_id is None:
        return set()

    membership = db.execute(
        select(CompanyUser).where(
            CompanyUser.company_id == company_id,
            CompanyUser.user_id == user.id,
            CompanyUser.status == "active",
        )
    ).scalar_one_or_none()
    if membership is None or membership.role_id is None:
        return set()

    rows = db.execute(
        select(Permission.code)
        .join(RolePermission, RolePermission.permission_id == Permission.id)
        .where(RolePermission.role_id == membership.role_id)
    ).scalars().all()
    return set(rows)


def require_permissions(
    permissions: set[str],
    *required: str,
    any_of: bool = False,
) -> None:
    if not required:
        return
    if any_of:
        if not any(code in permissions for code in required):
            raise PermissionDeniedError(
                "Permission denied",
                details={"required_any_of": list(required)},
            )
        return
    missing = [code for code in required if code not in permissions]
    if missing:
        raise PermissionDeniedError(
            f"Missing permission(s): {', '.join(missing)}",
            details={"missing": missing, "required": list(required)},
        )


def sync_permission_for(entity_type: str, operation: str) -> str | None:
    return SYNC_ENTITY_PERMISSIONS.get((entity_type, operation))


def require_sync_operation_permission(
    permissions: set[str],
    *,
    entity_type: str,
    operation: str,
) -> None:
    require_permissions(permissions, SYNC_EXECUTE)
    entity_perm = sync_permission_for(entity_type, operation)
    if entity_perm is not None:
        require_permissions(permissions, entity_perm)
