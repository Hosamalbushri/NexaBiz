"""Seed permissions, system roles, demo company, and bootstrap admin."""

from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.auth.passwords import hash_password
from app.auth.permissions_catalog import ALL_PERMISSIONS, SYSTEM_ROLE_PERMISSIONS
from app.auth.tokens import utcnow
from app.core.config import Settings
from app.models.identity import (
    CompanyUser,
    Permission,
    Role,
    RolePermission,
    User,
)
from app.models.sync import Company, SyncSequence


def seed_identity(db: Session, settings: Settings) -> None:
    # Permissions
    code_to_perm: dict[str, Permission] = {}
    for code, description in ALL_PERMISSIONS:
        existing = db.execute(
            select(Permission).where(Permission.code == code)
        ).scalar_one_or_none()
        if existing is None:
            existing = Permission(
                id=uuid.uuid4(),
                code=code,
                description=description,
                created_at=utcnow(),
            )
            db.add(existing)
            db.flush()
        code_to_perm[code] = existing

    # System role templates (company_id = NULL)
    role_by_name: dict[str, Role] = {}
    for role_name, perm_codes in SYSTEM_ROLE_PERMISSIONS.items():
        role = db.execute(
            select(Role).where(Role.name == role_name, Role.company_id.is_(None))
        ).scalar_one_or_none()
        if role is None:
            role = Role(
                id=uuid.uuid4(),
                company_id=None,
                name=role_name,
                description=f"System role: {role_name}",
                system_role=True,
                created_at=utcnow(),
                updated_at=utcnow(),
            )
            db.add(role)
            db.flush()
        # Reset permissions for system roles to catalog defaults.
        existing_links = (
            db.execute(select(RolePermission).where(RolePermission.role_id == role.id))
            .scalars()
            .all()
        )
        for link in existing_links:
            db.delete(link)
        db.flush()
        for code in perm_codes:
            perm = code_to_perm.get(code)
            if perm is None:
                continue
            db.add(RolePermission(role_id=role.id, permission_id=perm.id))
        db.flush()
        role_by_name[role_name] = role

    # Demo company (stable id for Flutter dart-define defaults)
    company_id = uuid.UUID(settings.seed_company_id)
    company = db.get(Company, company_id)
    if company is None:
        company = Company(
            id=company_id,
            name=settings.seed_company_name,
            code=settings.seed_company_code,
            status="active",
            created_at=utcnow(),
            updated_at=utcnow(),
        )
        db.add(company)
        db.flush()
    else:
        company.name = settings.seed_company_name
        company.code = settings.seed_company_code
        company.status = "active"
        company.updated_at = utcnow()

    if db.get(SyncSequence, company_id) is None:
        db.add(SyncSequence(company_id=company_id, next_value=1))
        db.flush()

    # Clone company-scoped copies of system roles for Company A
    company_roles: dict[str, Role] = {}
    for role_name, template in role_by_name.items():
        if role_name == "Super Admin":
            continue
        existing = db.execute(
            select(Role).where(Role.company_id == company_id, Role.name == role_name)
        ).scalar_one_or_none()
        if existing is None:
            existing = Role(
                id=uuid.uuid4(),
                company_id=company_id,
                name=role_name,
                description=template.description,
                system_role=True,
                created_at=utcnow(),
                updated_at=utcnow(),
            )
            db.add(existing)
            db.flush()
            # Copy permissions from template
            template_perms = (
                db.execute(
                    select(RolePermission.permission_id).where(
                        RolePermission.role_id == template.id
                    )
                )
                .scalars()
                .all()
            )
            for pid in template_perms:
                db.add(RolePermission(role_id=existing.id, permission_id=pid))
            db.flush()
        company_roles[role_name] = existing

    # Bootstrap super admin
    admin = db.execute(
        select(User).where(User.email == settings.seed_admin_email.lower())
    ).scalar_one_or_none()
    if admin is None:
        admin = db.get(User, uuid.UUID(settings.default_user_id))
    if admin is None:
        admin = User(
            id=uuid.UUID(settings.default_user_id),
            name=settings.seed_admin_name,
            email=settings.seed_admin_email.lower(),
            password_hash=hash_password(settings.seed_admin_password),
            status="active",
            is_super_admin=True,
            created_at=utcnow(),
            updated_at=utcnow(),
        )
        db.add(admin)
        db.flush()
    else:
        admin.email = settings.seed_admin_email.lower()
        admin.name = settings.seed_admin_name
        admin.is_super_admin = True
        admin.status = "active"
        admin.password_hash = hash_password(settings.seed_admin_password)
        admin.updated_at = utcnow()
        db.flush()

    # Demo sales employee Ahmed for acceptance scenario
    ahmed_email = "ahmed@example.com"
    ahmed = db.execute(select(User).where(User.email == ahmed_email)).scalar_one_or_none()
    if ahmed is None:
        ahmed = User(
            id=uuid.uuid4(),
            name="Ahmed",
            email=ahmed_email,
            password_hash=hash_password("AhmedSales!123"),
            status="active",
            is_super_admin=False,
            created_at=utcnow(),
            updated_at=utcnow(),
        )
        db.add(ahmed)
        db.flush()

    sales_role = company_roles.get("Sales Employee")
    if sales_role is not None:
        membership = db.execute(
            select(CompanyUser).where(
                CompanyUser.company_id == company_id,
                CompanyUser.user_id == ahmed.id,
            )
        ).scalar_one_or_none()
        if membership is None:
            db.add(
                CompanyUser(
                    id=uuid.uuid4(),
                    company_id=company_id,
                    user_id=ahmed.id,
                    role_id=sales_role.id,
                    status="active",
                    created_at=utcnow(),
                    updated_at=utcnow(),
                )
            )
        else:
            membership.role_id = sales_role.id
            membership.status = "active"

    # Also attach admin as Company Admin for convenience
    admin_role = company_roles.get("Company Admin")
    if admin_role is not None:
        membership = db.execute(
            select(CompanyUser).where(
                CompanyUser.company_id == company_id,
                CompanyUser.user_id == admin.id,
            )
        ).scalar_one_or_none()
        if membership is None:
            db.add(
                CompanyUser(
                    id=uuid.uuid4(),
                    company_id=company_id,
                    user_id=admin.id,
                    role_id=admin_role.id,
                    status="active",
                    created_at=utcnow(),
                    updated_at=utcnow(),
                )
            )

    db.flush()
