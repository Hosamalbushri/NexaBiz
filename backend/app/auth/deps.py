from __future__ import annotations

import uuid
from dataclasses import dataclass

from fastapi import Depends, Header

from app.core.config import Settings, get_settings
from app.core.exceptions import UnauthorizedError


@dataclass(frozen=True)
class AuthContext:
    """Minimal experimental auth / tenant context."""

    company_id: uuid.UUID
    user_id: uuid.UUID
    device_id: uuid.UUID
    token: str


def _parse_uuid(value: str | None, fallback: str, label: str) -> uuid.UUID:
    raw = (value or fallback).strip()
    try:
        return uuid.UUID(raw)
    except ValueError as exc:
        raise UnauthorizedError(f"Invalid {label}") from exc


def get_auth_context(
    authorization: str | None = Header(default=None),
    x_company_id: str | None = Header(default=None, alias="X-Company-Id"),
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    x_device_id: str | None = Header(default=None, alias="X-Device-Id"),
    settings: Settings = Depends(get_settings),
) -> AuthContext:
    """
    Development authentication.

    Accepts: Authorization: Bearer <DEV_API_TOKEN>
    Optional tenant/device headers override defaults (for multi-device tests).
    """
    if not authorization or not authorization.lower().startswith("bearer "):
        raise UnauthorizedError("Missing or invalid Authorization header")

    token = authorization.split(" ", 1)[1].strip()
    if token != settings.dev_api_token:
        raise UnauthorizedError("Invalid API token")

    return AuthContext(
        company_id=_parse_uuid(x_company_id, settings.default_company_id, "company_id"),
        user_id=_parse_uuid(x_user_id, settings.default_user_id, "user_id"),
        device_id=_parse_uuid(x_device_id, settings.default_device_id, "device_id"),
        token=token,
    )
