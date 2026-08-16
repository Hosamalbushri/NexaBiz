"""Guards that prevent removing the last administrative access."""

from __future__ import annotations

import uuid

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.auth.deps import AuthContext
from app.auth.errors import PermissionDeniedError
from app.auth.permissions_catalog import PLATFORM_USERS_MANAGE
from app.core.exceptions import NotFoundError, ValidationAppError
from app.models.identity import CompanyUser, Role, User


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


def count_active_super_admins(db: Session, *, excluding_user_id: uuid.UUID | None = None) -> int:
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
            if remaining < 1 and count_active_super_admins(db, excluding_user_id=user.id) < 1:
                raise ValidationAppError(
                    "Cannot remove the last administrator for this company"
                )
