from __future__ import annotations

import hashlib
import secrets
import uuid
from datetime import datetime, timedelta, timezone
from typing import Any

import jwt

from app.core.config import Settings


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def hash_token(raw: str) -> str:
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def generate_refresh_token() -> str:
    return secrets.token_urlsafe(48)


def create_access_token(
    *,
    settings: Settings,
    user_id: uuid.UUID,
    session_id: uuid.UUID,
    company_id: uuid.UUID | None,
    device_id: uuid.UUID | None = None,
    is_super_admin: bool = False,
) -> tuple[str, int]:
    expires_in = settings.access_token_ttl_seconds
    now = utcnow()
    payload: dict[str, Any] = {
        "sub": str(user_id),
        "sid": str(session_id),
        "typ": "access",
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(seconds=expires_in)).timestamp()),
        "iss": settings.jwt_issuer,
    }
    if company_id is not None:
        payload["cid"] = str(company_id)
    if device_id is not None:
        payload["did"] = str(device_id)
    if is_super_admin:
        payload["sa"] = True
    token = jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)
    return token, expires_in


def decode_access_token(token: str, settings: Settings) -> dict[str, Any]:
    return jwt.decode(
        token,
        settings.jwt_secret,
        algorithms=[settings.jwt_algorithm],
        issuer=settings.jwt_issuer,
        options={"require": ["exp", "sub", "sid", "typ"]},
    )
