from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.audit.service import write_audit
from app.auth.deps import AuthContext, PermissionChecker, get_auth_context, require_company_context
from app.auth.passwords import hash_password
from app.auth.permissions_catalog import (
    DEVICES_REVOKE,
    DEVICES_VIEW,
    PERMISSIONS_MANAGE,
    PLATFORM_COMPANIES_MANAGE,
    PLATFORM_USERS_MANAGE,
    ROLES_CREATE,
    ROLES_DELETE,
    ROLES_MANAGE,
    ROLES_UPDATE,
    ROLES_VIEW,
    USERS_CREATE,
    USERS_DELETE,
    USERS_MANAGE,
    USERS_UPDATE,
    USERS_VIEW,
)
from app.auth.schemas import (
    CompanyCreateRequest,
    CompanyMembershipRequest,
    CompanyMembershipUpdateRequest,
    CompanyUpdateRequest,
    DeviceRegisterRequest,
    RoleCreateRequest,
    RoleUpdateRequest,
    UserCreateRequest,
    UserUpdateRequest,
)
from app.auth.service import AuthService
from app.auth.tokens import utcnow
from app.core.config import Settings, get_settings
from app.core.database import get_db
from app.core.exceptions import NotFoundError, ValidationAppError
from app.models.identity import (
    CompanyUser,
    Permission,
    Role,
    RolePermission,
    User,
)
from app.models.sync import Company, SyncSequence

users_router = APIRouter(prefix="/api/v1/users", tags=["users"])
roles_router = APIRouter(prefix="/api/v1/roles", tags=["roles"])
permissions_router = APIRouter(prefix="/api/v1/permissions", tags=["permissions"])
companies_router = APIRouter(prefix="/api/v1/companies", tags=["companies"])
devices_router = APIRouter(prefix="/api/v1/devices", tags=["devices"])


def _user_out(user: User) -> dict:
    return {
        "id": str(user.id),
        "name": user.name,
        "email": user.email,
        "phone": user.phone,
        "status": user.status,
        "is_super_admin": user.is_super_admin,
        "created_at": user.created_at.isoformat() if user.created_at else None,
        "updated_at": user.updated_at.isoformat() if user.updated_at else None,
    }


@users_router.get("")
def list_users(
    db: Session = Depends(get_db),
    auth: AuthContext = Depends(
        PermissionChecker(USERS_VIEW, USERS_MANAGE, PLATFORM_USERS_MANAGE, any_of=True)
    ),
) -> dict:
    if auth.user.is_super_admin or PLATFORM_USERS_MANAGE in auth.permissions:
        rows = db.execute(select(User).order_by(User.created_at.desc())).scalars().all()
    else:
        company_id = auth.require_company_id
        user_ids = (
            db.execute(
                select(CompanyUser.user_id).where(CompanyUser.company_id == company_id)
            )
            .scalars()
            .all()
        )
        rows = (
            db.execute(select(User).where(User.id.in_(user_ids)).order_by(User.name))
            .scalars()
            .all()
            if user_ids
            else []
        )
    return {"data": [_user_out(u) for u in rows]}


@users_router.post("")
def create_user(
    body: UserCreateRequest,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
    auth: AuthContext = Depends(
        PermissionChecker(USERS_CREATE, USERS_MANAGE, PLATFORM_USERS_MANAGE, any_of=True)
    ),
) -> dict:
    if body.is_super_admin and not auth.user.is_super_admin:
        raise ValidationAppError("Only super admins can create super admins")
    service = AuthService(db, settings)
    try:
        user = service.create_user(
            name=body.name,
            email=str(body.email),
            password=body.password,
            phone=body.phone,
            status=body.status,
            is_super_admin=body.is_super_admin and auth.user.is_super_admin,
        )
        company_id = body.company_id or auth.company_id
        if company_id is not None and body.role_id is not None:
            db.add(
                CompanyUser(
                    id=uuid.uuid4(),
                    company_id=company_id,
                    user_id=user.id,
                    role_id=body.role_id,
                    status="active",
                    created_at=utcnow(),
                    updated_at=utcnow(),
                )
            )
        write_audit(
            db,
            action="user.created",
            user_id=auth.user.id,
            company_id=company_id,
            entity_type="user",
            entity_id=str(user.id),
        )
        db.commit()
        return {"data": _user_out(user)}
    except Exception:
        db.rollback()
        raise


@users_router.get("/{user_id}")
def get_user(
    user_id: uuid.UUID,
    db: Session = Depends(get_db),
    auth: AuthContext = Depends(
        PermissionChecker(USERS_VIEW, USERS_MANAGE, PLATFORM_USERS_MANAGE, any_of=True)
    ),
) -> dict:
    user = db.get(User, user_id)
    if user is None:
        raise NotFoundError("User not found")
    return {"data": _user_out(user)}


@users_router.patch("/{user_id}")
def update_user(
    user_id: uuid.UUID,
    body: UserUpdateRequest,
    db: Session = Depends(get_db),
    auth: AuthContext = Depends(
        PermissionChecker(USERS_UPDATE, USERS_MANAGE, PLATFORM_USERS_MANAGE, any_of=True)
    ),
) -> dict:
    user = db.get(User, user_id)
    if user is None:
        raise NotFoundError("User not found")
    if body.name is not None:
        user.name = body.name
    if body.phone is not None:
        user.phone = body.phone
    if body.status is not None:
        user.status = body.status
        write_audit(
            db,
            action="user.status_changed",
            user_id=auth.user.id,
            company_id=auth.company_id,
            entity_type="user",
            entity_id=str(user.id),
            metadata={"status": body.status},
        )
    if body.password is not None:
        user.password_hash = hash_password(body.password)
    user.updated_at = utcnow()
    try:
        db.commit()
        return {"data": _user_out(user)}
    except Exception:
        db.rollback()
        raise


@users_router.delete("/{user_id}")
def delete_user(
    user_id: uuid.UUID,
    db: Session = Depends(get_db),
    auth: AuthContext = Depends(
        PermissionChecker(USERS_DELETE, USERS_MANAGE, PLATFORM_USERS_MANAGE, any_of=True)
    ),
) -> dict:
    user = db.get(User, user_id)
    if user is None:
        raise NotFoundError("User not found")
    user.status = "inactive"
    user.updated_at = utcnow()
    write_audit(
        db,
        action="user.deactivated",
        user_id=auth.user.id,
        company_id=auth.company_id,
        entity_type="user",
        entity_id=str(user.id),
    )
    try:
        db.commit()
        return {"data": {"ok": True}}
    except Exception:
        db.rollback()
        raise


@roles_router.get("")
def list_roles(
    db: Session = Depends(get_db),
    auth: AuthContext = Depends(
        PermissionChecker(ROLES_VIEW, ROLES_MANAGE, any_of=True)
    ),
) -> dict:
    company_id = auth.company_id
    q = select(Role).where(
        (Role.company_id == company_id) | (Role.company_id.is_(None))
    )
    rows = db.execute(q.order_by(Role.name)).scalars().all()
    return {
        "data": [
            {
                "id": str(r.id),
                "name": r.name,
                "description": r.description,
                "system_role": r.system_role,
                "company_id": str(r.company_id) if r.company_id else None,
            }
            for r in rows
        ]
    }


@roles_router.post("")
def create_role(
    body: RoleCreateRequest,
    db: Session = Depends(get_db),
    auth: AuthContext = Depends(
        PermissionChecker(ROLES_CREATE, ROLES_MANAGE, any_of=True)
    ),
) -> dict:
    company_id = auth.require_company_id
    role = Role(
        id=uuid.uuid4(),
        company_id=company_id,
        name=body.name,
        description=body.description,
        system_role=False,
        created_at=utcnow(),
        updated_at=utcnow(),
    )
    db.add(role)
    db.flush()
    _set_role_permissions(db, role.id, body.permission_codes)
    write_audit(
        db,
        action="role.created",
        user_id=auth.user.id,
        company_id=company_id,
        entity_type="role",
        entity_id=str(role.id),
    )
    try:
        db.commit()
        return {"data": {"id": str(role.id), "name": role.name}}
    except Exception:
        db.rollback()
        raise


@roles_router.get("/{role_id}")
def get_role(
    role_id: uuid.UUID,
    db: Session = Depends(get_db),
    auth: AuthContext = Depends(
        PermissionChecker(ROLES_VIEW, ROLES_MANAGE, any_of=True)
    ),
) -> dict:
    role = db.get(Role, role_id)
    if role is None:
        raise NotFoundError("Role not found")
    codes = (
        db.execute(
            select(Permission.code)
            .join(RolePermission, RolePermission.permission_id == Permission.id)
            .where(RolePermission.role_id == role.id)
        )
        .scalars()
        .all()
    )
    return {
        "data": {
            "id": str(role.id),
            "name": role.name,
            "description": role.description,
            "system_role": role.system_role,
            "permissions": list(codes),
        }
    }


@roles_router.patch("/{role_id}")
def update_role(
    role_id: uuid.UUID,
    body: RoleUpdateRequest,
    db: Session = Depends(get_db),
    auth: AuthContext = Depends(
        PermissionChecker(ROLES_UPDATE, ROLES_MANAGE, any_of=True)
    ),
) -> dict:
    role = db.get(Role, role_id)
    if role is None:
        raise NotFoundError("Role not found")
    if role.system_role and role.company_id is None and not auth.user.is_super_admin:
        raise ValidationAppError("Cannot modify platform system roles")
    if body.name is not None:
        role.name = body.name
    if body.description is not None:
        role.description = body.description
    if body.permission_codes is not None:
        _set_role_permissions(db, role.id, body.permission_codes)
        write_audit(
            db,
            action="role.permissions_changed",
            user_id=auth.user.id,
            company_id=auth.company_id,
            entity_type="role",
            entity_id=str(role.id),
            metadata={"permissions": body.permission_codes},
        )
    role.updated_at = utcnow()
    try:
        db.commit()
        return {"data": {"id": str(role.id), "name": role.name}}
    except Exception:
        db.rollback()
        raise


@roles_router.delete("/{role_id}")
def delete_role(
    role_id: uuid.UUID,
    db: Session = Depends(get_db),
    auth: AuthContext = Depends(
        PermissionChecker(ROLES_DELETE, ROLES_MANAGE, any_of=True)
    ),
) -> dict:
    role = db.get(Role, role_id)
    if role is None:
        raise NotFoundError("Role not found")
    if role.system_role:
        raise ValidationAppError("Cannot delete system roles")
    db.delete(role)
    try:
        db.commit()
        return {"data": {"ok": True}}
    except Exception:
        db.rollback()
        raise


@permissions_router.get("")
def list_permissions(
    db: Session = Depends(get_db),
    auth: AuthContext = Depends(
        PermissionChecker(ROLES_VIEW, PERMISSIONS_MANAGE, any_of=True)
    ),
) -> dict:
    rows = db.execute(select(Permission).order_by(Permission.code)).scalars().all()
    return {
        "data": [
            {"id": str(p.id), "code": p.code, "description": p.description}
            for p in rows
        ]
    }


@companies_router.get("")
def list_companies(
    db: Session = Depends(get_db),
    auth: AuthContext = Depends(get_auth_context),
) -> dict:
    if auth.user.is_super_admin or PLATFORM_COMPANIES_MANAGE in auth.permissions:
        rows = db.execute(select(Company).order_by(Company.name)).scalars().all()
    else:
        ids = (
            db.execute(
                select(CompanyUser.company_id).where(
                    CompanyUser.user_id == auth.user.id,
                    CompanyUser.status == "active",
                )
            )
            .scalars()
            .all()
        )
        rows = (
            db.execute(select(Company).where(Company.id.in_(ids)).order_by(Company.name))
            .scalars()
            .all()
            if ids
            else []
        )
    return {
        "data": [
            {
                "id": str(c.id),
                "name": c.name,
                "code": c.code,
                "status": c.status,
            }
            for c in rows
        ]
    }


@companies_router.post("")
def create_company(
    body: CompanyCreateRequest,
    db: Session = Depends(get_db),
    auth: AuthContext = Depends(
        PermissionChecker(PLATFORM_COMPANIES_MANAGE)
    ),
) -> dict:
    existing = db.execute(
        select(Company).where(Company.code == body.code.strip().upper())
    ).scalar_one_or_none()
    if existing is not None:
        raise ValidationAppError("Company code already exists")
    company = Company(
        id=uuid.uuid4(),
        name=body.name.strip(),
        code=body.code.strip().upper(),
        status=body.status,
        created_at=utcnow(),
        updated_at=utcnow(),
    )
    db.add(company)
    db.flush()
    db.add(SyncSequence(company_id=company.id, next_value=1))
    write_audit(
        db,
        action="company.created",
        user_id=auth.user.id,
        company_id=company.id,
        entity_type="company",
        entity_id=str(company.id),
    )
    try:
        db.commit()
        return {
            "data": {
                "id": str(company.id),
                "name": company.name,
                "code": company.code,
                "status": company.status,
            }
        }
    except Exception:
        db.rollback()
        raise


@companies_router.patch("/{company_id}")
def update_company(
    company_id: uuid.UUID,
    body: CompanyUpdateRequest,
    db: Session = Depends(get_db),
    auth: AuthContext = Depends(
        PermissionChecker(PLATFORM_COMPANIES_MANAGE, "companies.update", any_of=True)
    ),
) -> dict:
    company = db.get(Company, company_id)
    if company is None:
        raise NotFoundError("Company not found")
    if (
        not auth.user.is_super_admin
        and PLATFORM_COMPANIES_MANAGE not in auth.permissions
        and auth.company_id != company_id
    ):
        raise ValidationAppError("Cannot update another company")
    if body.name is not None:
        company.name = body.name
    if body.status is not None:
        company.status = body.status
    company.updated_at = utcnow()
    try:
        db.commit()
        return {
            "data": {
                "id": str(company.id),
                "name": company.name,
                "code": company.code,
                "status": company.status,
            }
        }
    except Exception:
        db.rollback()
        raise


@companies_router.get("/{company_id}/members")
def list_members(
    company_id: uuid.UUID,
    db: Session = Depends(get_db),
    auth: AuthContext = Depends(
        PermissionChecker(USERS_VIEW, USERS_MANAGE, any_of=True)
    ),
) -> dict:
    if (
        not auth.user.is_super_admin
        and auth.company_id != company_id
        and PLATFORM_USERS_MANAGE not in auth.permissions
    ):
        raise ValidationAppError("Cannot view members of another company")
    rows = (
        db.execute(select(CompanyUser).where(CompanyUser.company_id == company_id))
        .scalars()
        .all()
    )
    data = []
    for m in rows:
        user = db.get(User, m.user_id)
        role = db.get(Role, m.role_id) if m.role_id else None
        data.append(
            {
                "id": str(m.id),
                "user_id": str(m.user_id),
                "user_email": user.email if user else None,
                "user_name": user.name if user else None,
                "role_id": str(m.role_id) if m.role_id else None,
                "role_name": role.name if role else None,
                "status": m.status,
            }
        )
    return {"data": data}


@companies_router.post("/{company_id}/members")
def add_member(
    company_id: uuid.UUID,
    body: CompanyMembershipRequest,
    db: Session = Depends(get_db),
    auth: AuthContext = Depends(
        PermissionChecker(USERS_CREATE, USERS_MANAGE, PLATFORM_USERS_MANAGE, any_of=True)
    ),
) -> dict:
    company = db.get(Company, company_id)
    if company is None:
        raise NotFoundError("Company not found")
    existing = db.execute(
        select(CompanyUser).where(
            CompanyUser.company_id == company_id,
            CompanyUser.user_id == body.user_id,
        )
    ).scalar_one_or_none()
    if existing is not None:
        raise ValidationAppError("User already a member")
    membership = CompanyUser(
        id=uuid.uuid4(),
        company_id=company_id,
        user_id=body.user_id,
        role_id=body.role_id,
        status=body.status,
        created_at=utcnow(),
        updated_at=utcnow(),
    )
    db.add(membership)
    write_audit(
        db,
        action="company.member_added",
        user_id=auth.user.id,
        company_id=company_id,
        entity_type="company_user",
        entity_id=str(membership.id),
        metadata={"user_id": str(body.user_id), "role_id": str(body.role_id)},
    )
    try:
        db.commit()
        return {"data": {"id": str(membership.id)}}
    except Exception:
        db.rollback()
        raise


@companies_router.patch("/{company_id}/members/{membership_id}")
def update_member(
    company_id: uuid.UUID,
    membership_id: uuid.UUID,
    body: CompanyMembershipUpdateRequest,
    db: Session = Depends(get_db),
    auth: AuthContext = Depends(
        PermissionChecker(USERS_UPDATE, USERS_MANAGE, any_of=True)
    ),
) -> dict:
    membership = db.get(CompanyUser, membership_id)
    if membership is None or membership.company_id != company_id:
        raise NotFoundError("Membership not found")
    if body.role_id is not None:
        membership.role_id = body.role_id
        write_audit(
            db,
            action="role.assignment_changed",
            user_id=auth.user.id,
            company_id=company_id,
            entity_type="company_user",
            entity_id=str(membership.id),
            metadata={"role_id": str(body.role_id)},
        )
    if body.status is not None:
        membership.status = body.status
    membership.updated_at = utcnow()
    try:
        db.commit()
        return {"data": {"id": str(membership.id), "status": membership.status}}
    except Exception:
        db.rollback()
        raise


@companies_router.delete("/{company_id}/members/{membership_id}")
def remove_member(
    company_id: uuid.UUID,
    membership_id: uuid.UUID,
    db: Session = Depends(get_db),
    auth: AuthContext = Depends(
        PermissionChecker(USERS_DELETE, USERS_MANAGE, any_of=True)
    ),
) -> dict:
    membership = db.get(CompanyUser, membership_id)
    if membership is None or membership.company_id != company_id:
        raise NotFoundError("Membership not found")
    membership.status = "inactive"
    membership.updated_at = utcnow()
    try:
        db.commit()
        return {"data": {"ok": True}}
    except Exception:
        db.rollback()
        raise


@devices_router.get("")
def list_devices(
    db: Session = Depends(get_db),
    auth: AuthContext = Depends(
        PermissionChecker(DEVICES_VIEW)
    ),
) -> dict:
    from app.models.identity import Device

    company_id = auth.require_company_id
    rows = (
        db.execute(
            select(Device)
            .where(Device.company_id == company_id)
            .order_by(Device.created_at.desc())
        )
        .scalars()
        .all()
    )
    return {
        "data": [
            {
                "id": str(d.id),
                "device_identifier": str(d.device_identifier),
                "device_name": d.device_name,
                "platform": d.platform,
                "app_version": d.app_version,
                "status": d.status,
                "user_id": str(d.user_id),
                "last_seen_at": d.last_seen_at.isoformat() if d.last_seen_at else None,
            }
            for d in rows
        ]
    }


@devices_router.post("/register")
def register_device(
    body: DeviceRegisterRequest,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
    auth: AuthContext = Depends(require_company_context),
) -> dict:
    service = AuthService(db, settings)
    try:
        device = service.register_device(
            user=auth.user,
            company_id=auth.require_company_id,
            device_identifier=body.device_id,
            device_name=body.device_name,
            platform=body.platform,
            app_version=body.app_version,
        )
        db.commit()
        return {
            "data": {
                "id": str(device.id),
                "device_identifier": str(device.device_identifier),
                "status": device.status,
            }
        }
    except Exception:
        db.rollback()
        raise


@devices_router.post("/{device_id}/revoke")
def revoke_device(
    device_id: uuid.UUID,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
    auth: AuthContext = Depends(PermissionChecker(DEVICES_REVOKE)),
) -> dict:
    service = AuthService(db, settings)
    try:
        device = service.revoke_device(
            actor=auth.user,
            company_id=auth.require_company_id,
            device_id=device_id,
        )
        db.commit()
        return {"data": {"id": str(device.id), "status": device.status}}
    except Exception:
        db.rollback()
        raise


def _set_role_permissions(
    db: Session, role_id: uuid.UUID, codes: list[str]
) -> None:
    existing = (
        db.execute(select(RolePermission).where(RolePermission.role_id == role_id))
        .scalars()
        .all()
    )
    for row in existing:
        db.delete(row)
    db.flush()
    if not codes:
        return
    perms = (
        db.execute(select(Permission).where(Permission.code.in_(codes))).scalars().all()
    )
    for perm in perms:
        db.add(RolePermission(role_id=role_id, permission_id=perm.id))
    db.flush()
