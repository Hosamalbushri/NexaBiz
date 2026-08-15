from __future__ import annotations

import uuid
from dataclasses import dataclass, field

from fastapi import Depends, Header, Request
from sqlalchemy.orm import Session

from app.auth.authorization import load_permission_codes, require_permissions
from app.auth.tokens import decode_access_token
from app.core.config import Settings, get_settings
from app.core.database import get_db
from app.core.exceptions import UnauthorizedError, ValidationAppError
from app.models.identity import AuthSession, Device, User
from app.models.sync import Company


@dataclass
class AuthContext:
    """Authenticated request context. company_id comes from the session, never the client."""

    user: User
    session: AuthSession | None
    company_id: uuid.UUID | None
    device_id: uuid.UUID | None
    permissions: set[str] = field(default_factory=set)
    token: str = ""
    is_dev_token: bool = False

    @property
    def user_id(self) -> uuid.UUID:
        return self.user.id

    @property
    def require_company_id(self) -> uuid.UUID:
        if self.company_id is None:
            raise ValidationAppError("Company context required")
        return self.company_id


def _bearer_token(authorization: str | None) -> str:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise UnauthorizedError("Missing or invalid Authorization header")
    token = authorization.split(" ", 1)[1].strip()
    if not token:
        raise UnauthorizedError("Missing or invalid Authorization header")
    return token


def get_auth_context(
    request: Request,
    authorization: str | None = Header(default=None),
    x_device_id: str | None = Header(default=None, alias="X-Device-Id"),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> AuthContext:
    """
    Resolve authentication.

    Preferred: JWT access token issued by /auth/login.
    Legacy (dev only): shared DEV_API_TOKEN — still requires a real company
    from seed defaults; does not trust client-supplied company headers.
    """
    token = _bearer_token(authorization)

    # Legacy development token fallback.
    if settings.allow_dev_token and token == settings.dev_api_token:
        user = db.get(User, uuid.UUID(settings.default_user_id))
        company = db.get(Company, uuid.UUID(settings.default_company_id))
        if user is None or company is None:
            raise UnauthorizedError(
                "Dev token configured but seed identity is missing. Run migrations/seed."
            )
        device_uuid: uuid.UUID | None = None
        if x_device_id:
            try:
                device_uuid = uuid.UUID(x_device_id.strip())
            except ValueError as exc:
                raise UnauthorizedError("Invalid X-Device-Id") from exc
        permissions = load_permission_codes(db, user=user, company_id=company.id)
        return AuthContext(
            user=user,
            session=None,
            company_id=company.id,
            device_id=device_uuid,
            permissions=permissions,
            token=token,
            is_dev_token=True,
        )

    try:
        payload = decode_access_token(token, settings)
    except Exception as exc:
        raise UnauthorizedError("Invalid or expired access token") from exc

    if payload.get("typ") != "access":
        raise UnauthorizedError("Invalid token type")

    try:
        user_id = uuid.UUID(str(payload["sub"]))
        session_id = uuid.UUID(str(payload["sid"]))
    except (KeyError, ValueError) as exc:
        raise UnauthorizedError("Invalid token claims") from exc

    user = db.get(User, user_id)
    if user is None:
        raise UnauthorizedError("User not found")
    if user.status != "active":
        raise UnauthorizedError("User cannot authenticate")

    session = db.get(AuthSession, session_id)
    if session is None or session.user_id != user.id:
        raise UnauthorizedError("Session not found")
    if session.status != "active":
        raise UnauthorizedError("Session revoked")

    company_id: uuid.UUID | None = session.company_id
    device_id: uuid.UUID | None = session.device_id

    if device_id is not None:
        device = db.get(Device, device_id)
        if device is None or device.status != "active":
            raise UnauthorizedError("Device is revoked or blocked")

    if company_id is not None:
        company = db.get(Company, company_id)
        if company is None or company.status != "active":
            raise UnauthorizedError("Company is not available")

    permissions = load_permission_codes(db, user=user, company_id=company_id)
    request.state.auth_context = AuthContext(
        user=user,
        session=session,
        company_id=company_id,
        device_id=device_id,
        permissions=permissions,
        token=token,
    )
    return request.state.auth_context


def require_auth(auth: AuthContext = Depends(get_auth_context)) -> AuthContext:
    return auth


def require_company_context(
    auth: AuthContext = Depends(get_auth_context),
) -> AuthContext:
    auth.require_company_id
    return auth


class PermissionChecker:
    def __init__(self, *codes: str, any_of: bool = False) -> None:
        self.codes = codes
        self.any_of = any_of

    def __call__(self, auth: AuthContext = Depends(get_auth_context)) -> AuthContext:
        require_permissions(auth.permissions, *self.codes, any_of=self.any_of)
        return auth
