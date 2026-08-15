from __future__ import annotations

import uuid
from datetime import timedelta
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.audit.service import write_audit
from app.auth.authorization import load_permission_codes
from app.auth.passwords import hash_password, verify_password
from app.auth.tokens import (
    create_access_token,
    generate_refresh_token,
    hash_token,
    utcnow,
)
from app.core.config import Settings
from app.core.exceptions import (
    ForbiddenError,
    NotFoundError,
    UnauthorizedError,
    ValidationAppError,
)
from app.models.identity import AuthSession, CompanyUser, Device, Role, User
from app.models.sync import Company, SyncSequence


class AuthService:
    def __init__(self, db: Session, settings: Settings) -> None:
        self.db = db
        self.settings = settings

    def get_user_by_email(self, email: str) -> User | None:
        return self.db.execute(
            select(User).where(User.email == email.strip().lower())
        ).scalar_one_or_none()

    def get_user(self, user_id: uuid.UUID) -> User | None:
        return self.db.get(User, user_id)

    def list_company_memberships(self, user_id: uuid.UUID) -> list[CompanyUser]:
        return list(
            self.db.execute(
                select(CompanyUser).where(
                    CompanyUser.user_id == user_id,
                    CompanyUser.status == "active",
                )
            )
            .scalars()
            .all()
        )

    def ensure_sync_sequence(self, company_id: uuid.UUID) -> None:
        seq = self.db.get(SyncSequence, company_id)
        if seq is None:
            self.db.add(SyncSequence(company_id=company_id, next_value=1))
            self.db.flush()

    def _assert_user_can_authenticate(self, user: User) -> None:
        if user.status == "inactive":
            raise UnauthorizedError("User is inactive")
        if user.status == "suspended":
            raise UnauthorizedError("User is suspended")
        if user.status != "active":
            raise UnauthorizedError("User cannot authenticate")

    def login(
        self,
        *,
        email: str,
        password: str,
        company_id: uuid.UUID | None = None,
        device_identifier: uuid.UUID | None = None,
        device_name: str | None = None,
        platform: str | None = None,
        app_version: str | None = None,
        ip_address: str | None = None,
        user_agent: str | None = None,
    ) -> dict[str, Any]:
        user = self.get_user_by_email(email)
        if user is None or not verify_password(password, user.password_hash):
            write_audit(
                self.db,
                action="auth.login_failed",
                metadata={"email": email.strip().lower()},
                ip_address=ip_address,
                user_agent=user_agent,
            )
            raise UnauthorizedError("Invalid email or password")

        self._assert_user_can_authenticate(user)

        memberships = self.list_company_memberships(user.id)
        companies = []
        for m in memberships:
            company = self.db.get(Company, m.company_id)
            if company is None or company.status != "active":
                continue
            role = self.db.get(Role, m.role_id) if m.role_id else None
            companies.append(
                {
                    "id": str(company.id),
                    "name": company.name,
                    "code": company.code,
                    "role": role.name if role else None,
                }
            )

        selected_company_id = company_id
        if selected_company_id is None and len(companies) == 1:
            selected_company_id = uuid.UUID(companies[0]["id"])

        if selected_company_id is not None:
            if not user.is_super_admin and not any(
                c["id"] == str(selected_company_id) for c in companies
            ):
                raise ForbiddenError("Not a member of the requested company")
            company = self.db.get(Company, selected_company_id)
            if company is None or company.status != "active":
                raise ValidationAppError("Company is not available")
            self.ensure_sync_sequence(selected_company_id)

        device: Device | None = None
        if device_identifier is not None and selected_company_id is not None:
            device = self._register_or_touch_device(
                user_id=user.id,
                company_id=selected_company_id,
                device_identifier=device_identifier,
                device_name=device_name or "Unknown device",
                platform=platform or "unknown",
                app_version=app_version,
            )

        session, refresh_raw = self._create_session(
            user=user,
            company_id=selected_company_id,
            device_id=device.id if device else None,
        )
        access_token, expires_in = create_access_token(
            settings=self.settings,
            user_id=user.id,
            session_id=session.id,
            company_id=selected_company_id,
            device_id=device.id if device else None,
            is_super_admin=user.is_super_admin,
        )

        user.last_login_at = utcnow()
        permissions = load_permission_codes(
            self.db, user=user, company_id=selected_company_id
        )
        roles = self._role_names(user, selected_company_id)

        write_audit(
            self.db,
            action="auth.login",
            user_id=user.id,
            company_id=selected_company_id,
            device_id=device.id if device else None,
            ip_address=ip_address,
            user_agent=user_agent,
        )

        return {
            "access_token": access_token,
            "refresh_token": refresh_raw,
            "token_type": "bearer",
            "expires_in": expires_in,
            "user": self._user_public(user),
            "companies": companies,
            "current_company_id": str(selected_company_id)
            if selected_company_id
            else None,
            "roles": roles,
            "permissions": sorted(permissions),
            "device": self._device_public(device) if device else None,
            "session_id": str(session.id),
        }

    def refresh(
        self,
        *,
        refresh_token: str,
        ip_address: str | None = None,
        user_agent: str | None = None,
    ) -> dict[str, Any]:
        token_hash = hash_token(refresh_token)
        session = self.db.execute(
            select(AuthSession).where(AuthSession.refresh_token_hash == token_hash)
        ).scalar_one_or_none()
        if session is None:
            raise UnauthorizedError("Invalid refresh token")

        if session.status != "active":
            # Possible reuse after rotation — revoke family.
            self._revoke_family(session.family_id, reason="refresh_reuse")
            write_audit(
                self.db,
                action="auth.refresh_reuse_detected",
                user_id=session.user_id,
                company_id=session.company_id,
                device_id=session.device_id,
                metadata={"family_id": str(session.family_id)},
                ip_address=ip_address,
                user_agent=user_agent,
            )
            raise UnauthorizedError("Refresh token reuse detected")

        if session.expires_at <= utcnow():
            session.status = "expired"
            session.revoked_at = utcnow()
            raise UnauthorizedError("Refresh token expired")

        user = self.get_user(session.user_id)
        if user is None:
            raise UnauthorizedError("User not found")
        self._assert_user_can_authenticate(user)

        if session.device_id is not None:
            device = self.db.get(Device, session.device_id)
            if device is None or device.status != "active":
                raise UnauthorizedError("Device is revoked or blocked")

        # Rotate refresh token.
        session.status = "rotated"
        session.revoked_at = utcnow()
        new_session, refresh_raw = self._create_session(
            user=user,
            company_id=session.company_id,
            device_id=session.device_id,
            family_id=session.family_id,
        )
        session.replaced_by_id = new_session.id

        access_token, expires_in = create_access_token(
            settings=self.settings,
            user_id=user.id,
            session_id=new_session.id,
            company_id=session.company_id,
            device_id=session.device_id,
            is_super_admin=user.is_super_admin,
        )

        write_audit(
            self.db,
            action="auth.refresh",
            user_id=user.id,
            company_id=session.company_id,
            device_id=session.device_id,
            ip_address=ip_address,
            user_agent=user_agent,
        )

        return {
            "access_token": access_token,
            "refresh_token": refresh_raw,
            "token_type": "bearer",
            "expires_in": expires_in,
            "session_id": str(new_session.id),
            "current_company_id": str(session.company_id)
            if session.company_id
            else None,
        }

    def logout(
        self,
        *,
        session_id: uuid.UUID,
        user_id: uuid.UUID,
        ip_address: str | None = None,
        user_agent: str | None = None,
    ) -> None:
        session = self.db.get(AuthSession, session_id)
        if session is None or session.user_id != user_id:
            return
        if session.status == "active":
            session.status = "revoked"
            session.revoked_at = utcnow()
        write_audit(
            self.db,
            action="auth.logout",
            user_id=user_id,
            company_id=session.company_id,
            device_id=session.device_id,
            ip_address=ip_address,
            user_agent=user_agent,
        )

    def switch_company(
        self,
        *,
        user: User,
        session: AuthSession,
        company_id: uuid.UUID,
        ip_address: str | None = None,
        user_agent: str | None = None,
    ) -> dict[str, Any]:
        if not user.is_super_admin:
            membership = self.db.execute(
                select(CompanyUser).where(
                    CompanyUser.user_id == user.id,
                    CompanyUser.company_id == company_id,
                    CompanyUser.status == "active",
                )
            ).scalar_one_or_none()
            if membership is None:
                raise ForbiddenError("Not a member of the requested company")

        company = self.db.get(Company, company_id)
        if company is None or company.status != "active":
            raise NotFoundError("Company not found")

        self.ensure_sync_sequence(company_id)

        # Rotate session into new company context.
        session.status = "rotated"
        session.revoked_at = utcnow()
        device_id = session.device_id
        if device_id is not None:
            device = self.db.get(Device, device_id)
            if device is not None and device.company_id != company_id:
                # Re-bind device row for new company if needed.
                device = self._register_or_touch_device(
                    user_id=user.id,
                    company_id=company_id,
                    device_identifier=device.device_identifier,
                    device_name=device.device_name,
                    platform=device.platform,
                    app_version=device.app_version,
                )
                device_id = device.id

        new_session, refresh_raw = self._create_session(
            user=user,
            company_id=company_id,
            device_id=device_id,
            family_id=session.family_id,
        )
        session.replaced_by_id = new_session.id

        access_token, expires_in = create_access_token(
            settings=self.settings,
            user_id=user.id,
            session_id=new_session.id,
            company_id=company_id,
            device_id=device_id,
            is_super_admin=user.is_super_admin,
        )
        permissions = load_permission_codes(self.db, user=user, company_id=company_id)
        roles = self._role_names(user, company_id)

        write_audit(
            self.db,
            action="auth.switch_company",
            user_id=user.id,
            company_id=company_id,
            device_id=device_id,
            ip_address=ip_address,
            user_agent=user_agent,
        )

        return {
            "access_token": access_token,
            "refresh_token": refresh_raw,
            "token_type": "bearer",
            "expires_in": expires_in,
            "current_company_id": str(company_id),
            "roles": roles,
            "permissions": sorted(permissions),
            "session_id": str(new_session.id),
            "company": {
                "id": str(company.id),
                "name": company.name,
                "code": company.code,
            },
        }

    def me(self, *, user: User, company_id: uuid.UUID | None, device_id: uuid.UUID | None) -> dict[str, Any]:
        permissions = load_permission_codes(self.db, user=user, company_id=company_id)
        roles = self._role_names(user, company_id)
        company = self.db.get(Company, company_id) if company_id else None
        device = self.db.get(Device, device_id) if device_id else None
        memberships = []
        for m in self.list_company_memberships(user.id):
            c = self.db.get(Company, m.company_id)
            if c is None:
                continue
            role = self.db.get(Role, m.role_id) if m.role_id else None
            memberships.append(
                {
                    "id": str(c.id),
                    "name": c.name,
                    "code": c.code,
                    "role": role.name if role else None,
                }
            )
        return {
            "user": self._user_public(user),
            "current_company": {
                "id": str(company.id),
                "name": company.name,
                "code": company.code,
            }
            if company
            else None,
            "companies": memberships,
            "roles": roles,
            "permissions": sorted(permissions),
            "device": self._device_public(device) if device else None,
        }

    def _create_session(
        self,
        *,
        user: User,
        company_id: uuid.UUID | None,
        device_id: uuid.UUID | None,
        family_id: uuid.UUID | None = None,
    ) -> tuple[AuthSession, str]:
        raw = generate_refresh_token()
        session = AuthSession(
            id=uuid.uuid4(),
            user_id=user.id,
            company_id=company_id,
            device_id=device_id,
            refresh_token_hash=hash_token(raw),
            family_id=family_id or uuid.uuid4(),
            status="active",
            expires_at=utcnow()
            + timedelta(seconds=self.settings.refresh_token_ttl_seconds),
            created_at=utcnow(),
            last_used_at=utcnow(),
        )
        self.db.add(session)
        self.db.flush()
        return session, raw

    def _revoke_family(self, family_id: uuid.UUID, *, reason: str) -> None:
        rows = (
            self.db.execute(
                select(AuthSession).where(
                    AuthSession.family_id == family_id,
                    AuthSession.status == "active",
                )
            )
            .scalars()
            .all()
        )
        now = utcnow()
        for row in rows:
            row.status = "revoked"
            row.revoked_at = now

    def _register_or_touch_device(
        self,
        *,
        user_id: uuid.UUID,
        company_id: uuid.UUID,
        device_identifier: uuid.UUID,
        device_name: str,
        platform: str,
        app_version: str | None,
    ) -> Device:
        device = self.db.execute(
            select(Device).where(
                Device.company_id == company_id,
                Device.device_identifier == device_identifier,
            )
        ).scalar_one_or_none()
        now = utcnow()
        if device is None:
            device = Device(
                id=uuid.uuid4(),
                user_id=user_id,
                company_id=company_id,
                device_name=device_name,
                platform=platform,
                app_version=app_version,
                device_identifier=device_identifier,
                status="active",
                last_seen_at=now,
                created_at=now,
            )
            self.db.add(device)
            self.db.flush()
            write_audit(
                self.db,
                action="device.registered",
                user_id=user_id,
                company_id=company_id,
                device_id=device.id,
                entity_type="device",
                entity_id=str(device.id),
            )
            return device

        if device.status in {"revoked", "blocked"}:
            raise UnauthorizedError("Device is revoked or blocked")

        device.user_id = user_id
        device.device_name = device_name
        device.platform = platform
        device.app_version = app_version
        device.last_seen_at = now
        self.db.flush()
        return device

    def register_device(
        self,
        *,
        user: User,
        company_id: uuid.UUID,
        device_identifier: uuid.UUID,
        device_name: str,
        platform: str,
        app_version: str | None,
    ) -> Device:
        return self._register_or_touch_device(
            user_id=user.id,
            company_id=company_id,
            device_identifier=device_identifier,
            device_name=device_name,
            platform=platform,
            app_version=app_version,
        )

    def revoke_device(
        self,
        *,
        actor: User,
        company_id: uuid.UUID,
        device_id: uuid.UUID,
    ) -> Device:
        device = self.db.get(Device, device_id)
        if device is None or device.company_id != company_id:
            raise NotFoundError("Device not found")
        device.status = "revoked"
        device.revoked_at = utcnow()
        # Revoke sessions bound to this device.
        sessions = (
            self.db.execute(
                select(AuthSession).where(
                    AuthSession.device_id == device.id,
                    AuthSession.status == "active",
                )
            )
            .scalars()
            .all()
        )
        for s in sessions:
            s.status = "revoked"
            s.revoked_at = utcnow()
        write_audit(
            self.db,
            action="device.revoked",
            user_id=actor.id,
            company_id=company_id,
            device_id=device.id,
            entity_type="device",
            entity_id=str(device.id),
        )
        return device

    def _role_names(self, user: User, company_id: uuid.UUID | None) -> list[str]:
        if user.is_super_admin:
            return ["Super Admin"]
        if company_id is None:
            return []
        membership = self.db.execute(
            select(CompanyUser).where(
                CompanyUser.user_id == user.id,
                CompanyUser.company_id == company_id,
                CompanyUser.status == "active",
            )
        ).scalar_one_or_none()
        if membership is None or membership.role_id is None:
            return []
        role = self.db.get(Role, membership.role_id)
        return [role.name] if role else []

    @staticmethod
    def _user_public(user: User) -> dict[str, Any]:
        return {
            "id": str(user.id),
            "name": user.name,
            "email": user.email,
            "phone": user.phone,
            "status": user.status,
            "is_super_admin": user.is_super_admin,
            "email_verified_at": user.email_verified_at.isoformat()
            if user.email_verified_at
            else None,
            "last_login_at": user.last_login_at.isoformat()
            if user.last_login_at
            else None,
        }

    @staticmethod
    def _device_public(device: Device) -> dict[str, Any]:
        return {
            "id": str(device.id),
            "device_identifier": str(device.device_identifier),
            "device_name": device.device_name,
            "platform": device.platform,
            "app_version": device.app_version,
            "status": device.status,
            "last_seen_at": device.last_seen_at.isoformat()
            if device.last_seen_at
            else None,
        }

    def create_user(
        self,
        *,
        name: str,
        email: str,
        password: str,
        phone: str | None = None,
        status: str = "active",
        is_super_admin: bool = False,
    ) -> User:
        existing = self.get_user_by_email(email)
        if existing is not None:
            raise ValidationAppError("Email already registered")
        user = User(
            id=uuid.uuid4(),
            name=name.strip(),
            email=email.strip().lower(),
            phone=phone,
            password_hash=hash_password(password),
            status=status,
            is_super_admin=is_super_admin,
            created_at=utcnow(),
            updated_at=utcnow(),
        )
        self.db.add(user)
        self.db.flush()
        return user
