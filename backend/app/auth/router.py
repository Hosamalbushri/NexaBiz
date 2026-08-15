from __future__ import annotations

from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from app.auth.deps import AuthContext, get_auth_context
from app.auth.schemas import LoginRequest, RefreshRequest, SwitchCompanyRequest
from app.auth.service import AuthService
from app.core.config import Settings, get_settings
from app.core.database import get_db

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])


def _client_meta(request: Request) -> tuple[str | None, str | None]:
    ip = request.client.host if request.client else None
    ua = request.headers.get("user-agent")
    return ip, ua


@router.post("/login")
def login(
    body: LoginRequest,
    request: Request,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> dict:
    ip, ua = _client_meta(request)
    service = AuthService(db, settings)
    try:
        result = service.login(
            email=str(body.email),
            password=body.password,
            company_id=body.company_id,
            device_identifier=body.device_id,
            device_name=body.device_name,
            platform=body.platform,
            app_version=body.app_version,
            ip_address=ip,
            user_agent=ua,
        )
        db.commit()
        return {"data": result}
    except Exception:
        db.rollback()
        raise


@router.post("/refresh")
def refresh(
    body: RefreshRequest,
    request: Request,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> dict:
    ip, ua = _client_meta(request)
    service = AuthService(db, settings)
    try:
        result = service.refresh(
            refresh_token=body.refresh_token,
            ip_address=ip,
            user_agent=ua,
        )
        db.commit()
        return {"data": result}
    except Exception:
        db.rollback()
        raise


@router.post("/logout")
def logout(
    request: Request,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
    auth: AuthContext = Depends(get_auth_context),
) -> dict:
    ip, ua = _client_meta(request)
    if auth.session is not None:
        service = AuthService(db, settings)
        try:
            service.logout(
                session_id=auth.session.id,
                user_id=auth.user.id,
                ip_address=ip,
                user_agent=ua,
            )
            db.commit()
        except Exception:
            db.rollback()
            raise
    return {"data": {"ok": True}}


@router.get("/me")
def me(
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
    auth: AuthContext = Depends(get_auth_context),
) -> dict:
    service = AuthService(db, settings)
    return {
        "data": service.me(
            user=auth.user,
            company_id=auth.company_id,
            device_id=auth.device_id,
        )
    }


@router.post("/switch-company")
def switch_company(
    body: SwitchCompanyRequest,
    request: Request,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
    auth: AuthContext = Depends(get_auth_context),
) -> dict:
    if auth.session is None:
        from app.core.exceptions import ValidationAppError

        raise ValidationAppError("Company switch requires a JWT session")
    ip, ua = _client_meta(request)
    service = AuthService(db, settings)
    try:
        result = service.switch_company(
            user=auth.user,
            session=auth.session,
            company_id=body.company_id,
            ip_address=ip,
            user_agent=ua,
        )
        db.commit()
        return {"data": result}
    except Exception:
        db.rollback()
        raise
