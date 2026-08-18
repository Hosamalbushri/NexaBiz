"""Guards that prevent cross-tenant IDOR and privilege escalation."""

from __future__ import annotations

import uuid

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.auth.deps import AuthContext
from app.auth.errors import PermissionDeniedError
from app.auth.permissions_catalog import PLATFORM_USERS_MANAGE
from app.core.exceptions import NotFoundError, ValidationAppError
from app.models.identity import CompanyUser, Permission, Role, RolePermission, User


def can_manage_all_tenants(auth: AuthContext) -> bool:
    return auth.user.is_super_admin or PLATFORM_USERS_MANAGE in auth.permissions


def require_company_scope(auth: AuthContext, company_id: uuid.UUID) -> None:
    """Block cross-tenant company administration unless platform-scoped."""
    if can_manage_all_tenants(auth):
        return
    if auth.company_id != company_id:
        raise PermissionDeniedError(
            "Cannot manage another company",
            details={"company_id": str(company_id)},
        )


def role_permission_codes(db: Session, role_id: uuid.UUID) -> set[str]:
    return set(
        db.execute(
            select(Permission.code)
            .join(RolePermission, RolePermission.permission_id == Permission.id)
            .where(RolePermission.role_id == role_id)
        )
        .scalars()
        .all()
    )


def filter_assignable_permission_codes(
    auth: AuthContext, codes: list[str]
) -> list[str]:
    """Company admins must not grant platform.* permissions via custom roles."""
    if can_manage_all_tenants(auth):
        return codes
    return [code for code in codes if not code.startswith("platform.")]


def require_viewable_role(
    db: Session,
    auth: AuthContext,
    role_id: uuid.UUID,
) -> Role:
    """Load a role visible in the actor's tenant context."""
    role = db.get(Role, role_id)
    if role is None:
        raise NotFoundError("Role not found")
    if can_manage_all_tenants(auth):
        return role
    company_id = auth.require_company_id
    if role.company_id is None or role.company_id == company_id:
        return role
    raise NotFoundError("Role not found")


def require_manageable_role(
    db: Session,
    auth: AuthContext,
    role_id: uuid.UUID,
) -> Role:
    """Load a role the actor may mutate (patch/delete)."""
    role = require_viewable_role(db, auth, role_id)
    if can_manage_all_tenants(auth):
        return role
    company_id = auth.require_company_id
    if role.company_id != company_id:
        raise PermissionDeniedError("Cannot modify platform system roles")
    if role.system_role:
        raise PermissionDeniedError("Cannot modify system roles")
    return role


def require_assignable_role(
    db: Session,
    auth: AuthContext,
    role_id: uuid.UUID,
    *,
    company_id: uuid.UUID,
) -> Role:
    """Block assignment of Super Admin / platform-scoped roles by company admins."""
    role = db.get(Role, role_id)
    if role is None:
        raise NotFoundError("Role not found")
    require_company_scope(auth, company_id)
    if can_manage_all_tenants(auth):
        return role
    if role.name == "Super Admin":
        raise PermissionDeniedError("Cannot assign Super Admin role")
    codes = role_permission_codes(db, role.id)
    if any(code.startswith("platform.") for code in codes):
        raise PermissionDeniedError("Cannot assign platform-scoped roles")
    if role.company_id is not None and role.company_id != company_id:
        raise NotFoundError("Role not found")
    return role


def require_manageable_user(
    db: Session,
    auth: AuthContext,
    user_id: uuid.UUID,
) -> User:
    """
    Load a user the actor may administer.

    Company admins may only touch users who belong to their current company.
    Platform operators / super admins may touch any user.
    """
    user = db.get(User, user_id)
    if user is None:
        raise NotFoundError("User not found")
    if can_manage_all_tenants(auth):
        return user
    company_id = auth.require_company_id
    membership = db.execute(
        select(CompanyUser).where(
            CompanyUser.company_id == company_id,
            CompanyUser.user_id == user_id,
        )
    ).scalar_one_or_none()
    if membership is None:
        # Hide existence across tenants.
        raise NotFoundError("User not found")
    return user


def count_active_super_admins(
    db: Session, *, excluding_user_id: uuid.UUID | None = None
) -> int:
    q = select(func.count()).select_from(User).where(
        User.is_super_admin.is_(True),
        User.status == "active",
    )
    if excluding_user_id is not None:
        q = q.where(User.id != excluding_user_id)
    return int(db.execute(q).scalar_one())


def count_active_company_admins(
    db: Session,
    company_id: uuid.UUID,
    *,
    excluding_user_id: uuid.UUID | None = None,
) -> int:
    """Count active memberships whose role name contains 'Admin'."""
    q = (
        select(func.count())
        .select_from(CompanyUser)
        .join(Role, Role.id == CompanyUser.role_id)
        .join(User, User.id == CompanyUser.user_id)
        .where(
            CompanyUser.company_id == company_id,
            CompanyUser.status == "active",
            User.status == "active",
            Role.name.ilike("%admin%"),
        )
    )
    if excluding_user_id is not None:
        q = q.where(User.id != excluding_user_id)
    return int(db.execute(q).scalar_one())


def ensure_not_last_admin(
    db: Session,
    user: User,
    *,
    company_id: uuid.UUID | None,
    next_status: str | None = None,
) -> None:
    """Raise if deactivating/suspending this user would leave zero admins."""
    if next_status in (None, "active"):
        return
    if user.is_super_admin and user.status == "active":
        remaining = count_active_super_admins(db, excluding_user_id=user.id)
        if remaining < 1:
            raise ValidationAppError(
                "Cannot deactivate or suspend the last active super administrator"
            )
    if company_id is not None and user.status == "active":
        # Only relevant if this user currently holds an admin membership.
        membership = db.execute(
            select(CompanyUser)
            .join(Role, Role.id == CompanyUser.role_id)
            .where(
                CompanyUser.company_id == company_id,
                CompanyUser.user_id == user.id,
                CompanyUser.status == "active",
                Role.name.ilike("%admin%"),
            )
        ).scalar_one_or_none()
        if membership is not None:
            remaining = count_active_company_admins(
                db, company_id, excluding_user_id=user.id
            )
            if (
                remaining < 1
                and count_active_super_admins(db, excluding_user_id=user.id) < 1
            ):
                raise ValidationAppError(
                    "Cannot remove the last administrator for this company"
                )
