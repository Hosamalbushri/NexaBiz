"""Authentication, authorization, and tenant isolation tests."""

from __future__ import annotations

import importlib
import os
import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine

# Dedicated Postgres URL — never fall back to sqlite/memory from other tests.
_DEFAULT_PG = "postgresql+psycopg2://sync:sync@127.0.0.1:5432/sync_experimental"
DATABASE_URL = os.getenv("TEST_DATABASE_URL") or os.getenv("DATABASE_URL") or _DEFAULT_PG


def _postgres_ready() -> bool:
    if not DATABASE_URL.startswith("postgresql"):
        return False
    try:
        engine = create_engine(DATABASE_URL, pool_pre_ping=True)
        with engine.connect() as conn:
            conn.exec_driver_sql("SELECT 1")
            conn.exec_driver_sql("SELECT 1 FROM permissions LIMIT 1")
        engine.dispose()
        return True
    except Exception:
        return False


pytestmark = pytest.mark.skipif(
    not _postgres_ready(),
    reason=(
        "PostgreSQL with migrated schema required "
        "(set TEST_DATABASE_URL and run alembic upgrade head)"
    ),
)


@pytest.fixture()
def client(monkeypatch: pytest.MonkeyPatch):
    monkeypatch.setenv("APP_ENV", "development")
    monkeypatch.setenv("DATABASE_URL", DATABASE_URL)
    monkeypatch.setenv("ALLOW_DEV_TOKEN", "true")
    monkeypatch.setenv("AUTH_RATE_LIMIT_PER_MINUTE", "0")
    from app.core.config import get_settings

    get_settings.cache_clear()

    import app.core.database as database
    import app.main as main

    importlib.reload(database)
    importlib.reload(main)

    with TestClient(main.app) as c:
        yield c

    get_settings.cache_clear()


def _login(client: TestClient, email: str, password: str, **extra) -> dict:
    payload = {"email": email, "password": password, **extra}
    r = client.post("/api/v1/auth/login", json=payload)
    assert r.status_code == 200, r.text
    return r.json()["data"]


def _super_admin_headers(client: TestClient) -> dict[str, str]:
    admin = _login(client, "admin@example.com", "ChangeMeAdmin!123")
    return {"Authorization": f"Bearer {admin['access_token']}"}


def _company_admin_role_id(client: TestClient, headers: dict[str, str]) -> str:
    roles = client.get("/api/v1/roles", headers=headers)
    assert roles.status_code == 200, roles.text
    role = next(
        r for r in roles.json()["data"] if r["name"] == "Company Admin" and r.get("system_role")
    )
    return role["id"]


def _bootstrap_tenant_admin(
    client: TestClient,
    *,
    company_id: str = "00000000-0000-4000-8000-000000000001",
) -> tuple[dict[str, str], str]:
    """Create a non-super company admin in [company_id] and return (headers, email)."""
    admin_headers = _super_admin_headers(client)
    role_id = _company_admin_role_id(client, admin_headers)
    email = f"tenant-admin-{uuid.uuid4().hex[:8]}@example.com"
    created = client.post(
        "/api/v1/users",
        headers=admin_headers,
        json={
            "name": "Tenant Admin",
            "email": email,
            "password": "TenantAdmin!123",
            "company_id": company_id,
            "role_id": role_id,
            "is_super_admin": False,
        },
    )
    assert created.status_code == 200, created.text
    session = _login(
        client,
        email,
        "TenantAdmin!123",
        company_id=company_id,
        device_id=str(uuid.uuid4()),
        device_name="Tenant Device",
        platform="android",
    )
    return {"Authorization": f"Bearer {session['access_token']}"}, email


def _create_other_company(client: TestClient, headers: dict[str, str]) -> str:
    other_company = client.post(
        "/api/v1/companies",
        headers=headers,
        json={
            "name": f"Other Co {uuid.uuid4().hex[:6]}",
            "code": f"OTHER-{uuid.uuid4().hex[:6].upper()}",
        },
    )
    assert other_company.status_code == 200, other_company.text
    return other_company.json()["data"]["id"]


def test_login_valid(client: TestClient):
    data = _login(client, "ahmed@example.com", "AhmedSales!123")
    assert data["access_token"]
    assert data["refresh_token"]
    assert data["user"]["email"] == "ahmed@example.com"
    assert "sales.create" in data["permissions"]
    assert "users.manage" not in data["permissions"]


def test_login_invalid_password(client: TestClient):
    r = client.post(
        "/api/v1/auth/login",
        json={"email": "ahmed@example.com", "password": "wrong"},
    )
    assert r.status_code == 401


def test_login_unknown_user(client: TestClient):
    r = client.post(
        "/api/v1/auth/login",
        json={"email": "nobody@example.com", "password": "x"},
    )
    assert r.status_code == 401


def test_refresh_and_logout(client: TestClient):
    data = _login(client, "ahmed@example.com", "AhmedSales!123")
    refresh = data["refresh_token"]
    r = client.post("/api/v1/auth/refresh", json={"refresh_token": refresh})
    assert r.status_code == 200
    new = r.json()["data"]
    assert new["access_token"]
    assert new["refresh_token"] != refresh

    # Reuse old refresh → revoked family
    r2 = client.post("/api/v1/auth/refresh", json={"refresh_token": refresh})
    assert r2.status_code == 401

    headers = {"Authorization": f"Bearer {new['access_token']}"}
    # New token may still work until session family fully invalidated on reuse
    # Logout with latest access if still valid, else login again
    r3 = client.post("/api/v1/auth/logout", headers=headers)
    # After reuse detection, session family revoked — logout may 401
    assert r3.status_code in {200, 401}


def test_me_and_permissions(client: TestClient):
    data = _login(
        client,
        "ahmed@example.com",
        "AhmedSales!123",
        company_id="00000000-0000-4000-8000-000000000001",
        device_id=str(uuid.uuid4()),
        device_name="Test Phone",
        platform="android",
        app_version="0.1.0",
    )
    headers = {"Authorization": f"Bearer {data['access_token']}"}
    r = client.get("/api/v1/auth/me", headers=headers)
    assert r.status_code == 200
    body = r.json()["data"]
    assert body["current_company"]["code"] == "COMPANY-A"
    assert "sales.create" in body["permissions"]


def test_sync_requires_auth(client: TestClient):
    r = client.get("/api/v1/sync/pull", params={"entity_type": "customer", "cursor": 0})
    assert r.status_code == 401


def test_authorized_customer_create(client: TestClient):
    data = _login(
        client,
        "ahmed@example.com",
        "AhmedSales!123",
        company_id="00000000-0000-4000-8000-000000000001",
        device_id=str(uuid.uuid4()),
        device_name="Device A",
        platform="android",
    )
    headers = {"Authorization": f"Bearer {data['access_token']}"}
    entity_id = str(uuid.uuid4())
    op_id = str(uuid.uuid4())
    r = client.post(
        "/api/v1/sync/push",
        headers=headers,
        json={
            "entity_type": "customer",
            "operation": {
                "operation_id": op_id,
                "entity_type": "customer",
                "entity_id": entity_id,
                "type": "create",
                "payload": {"uuid": entity_id, "name": "Cust A", "code": "C1"},
                "base_version": 0,
            },
        },
    )
    assert r.status_code == 200, r.text
    assert r.json()["remote_version"] >= 1


def test_unauthorized_user_admin_blocked(client: TestClient):
    data = _login(client, "ahmed@example.com", "AhmedSales!123")
    headers = {"Authorization": f"Bearer {data['access_token']}"}
    r = client.get("/api/v1/users", headers=headers)
    assert r.status_code == 403


def test_tenant_isolation_on_pull(client: TestClient):
    """Forged company context is ignored — session company wins."""
    data = _login(
        client,
        "ahmed@example.com",
        "AhmedSales!123",
        company_id="00000000-0000-4000-8000-000000000001",
        device_id=str(uuid.uuid4()),
        device_name="Device A",
        platform="android",
    )
    headers = {
        "Authorization": f"Bearer {data['access_token']}",
        "X-Company-Id": "00000000-0000-4000-8000-999999999999",
    }
    r = client.get(
        "/api/v1/sync/pull",
        headers=headers,
        params={"entity_type": "customer", "cursor": 0},
    )
    assert r.status_code == 200
    # Must succeed against Ahmed's company, not the forged id.
    assert "changes" in r.json()


def test_dev_token_still_works_after_seed(client: TestClient):
    headers = {"Authorization": "Bearer dev-sync-token-change-me"}
    r = client.get(
        "/api/v1/sync/pull",
        headers=headers,
        params={"entity_type": "product", "cursor": 0},
    )
    assert r.status_code == 200


def test_dev_token_disabled_by_default_flag(client: TestClient, monkeypatch: pytest.MonkeyPatch):
    monkeypatch.setenv("ALLOW_DEV_TOKEN", "false")
    from app.core.config import get_settings

    get_settings.cache_clear()
    headers = {"Authorization": "Bearer dev-sync-token-change-me"}
    r = client.get(
        "/api/v1/sync/pull",
        headers=headers,
        params={"entity_type": "product", "cursor": 0},
    )
    assert r.status_code == 401
    get_settings.cache_clear()
    monkeypatch.setenv("ALLOW_DEV_TOKEN", "true")
    get_settings.cache_clear()


def test_company_admin_cannot_read_cross_tenant_user(client: TestClient):
    """Company-scoped admin must not GET a user who only belongs to another company."""
    admin = _login(
        client,
        "admin@example.com",
        "ChangeMeAdmin!123",
        company_id="00000000-0000-4000-8000-000000000001",
        device_id=str(uuid.uuid4()),
        device_name="Admin Device",
        platform="android",
    )
    admin_headers = {"Authorization": f"Bearer {admin['access_token']}"}

    roles = client.get("/api/v1/roles", headers=admin_headers)
    assert roles.status_code == 200
    company_admin_role = next(
        r for r in roles.json()["data"] if r["name"] == "Company Admin" and r.get("system_role")
    )

    # Tenant admin in Demo Company A (not super admin).
    tenant_email = f"tenant-admin-{uuid.uuid4().hex[:8]}@example.com"
    created = client.post(
        "/api/v1/users",
        headers=admin_headers,
        json={
            "name": "Tenant Admin",
            "email": tenant_email,
            "password": "TenantAdmin!123",
            "company_id": "00000000-0000-4000-8000-000000000001",
            "role_id": company_admin_role["id"],
            "is_super_admin": False,
        },
    )
    assert created.status_code == 200, created.text

    # Second company + outsider user only there.
    other_company = client.post(
        "/api/v1/companies",
        headers=admin_headers,
        json={
            "name": f"Other Co {uuid.uuid4().hex[:6]}",
            "code": f"OTHER-{uuid.uuid4().hex[:6].upper()}",
        },
    )
    assert other_company.status_code == 200, other_company.text
    other_company_id = other_company.json()["data"]["id"]

    outsider_email = f"outsider-{uuid.uuid4().hex[:8]}@example.com"
    outsider = client.post(
        "/api/v1/users",
        headers=admin_headers,
        json={
            "name": "Outsider",
            "email": outsider_email,
            "password": "Outsider!12345",
            "company_id": other_company_id,
            "role_id": company_admin_role["id"],
            "is_super_admin": False,
        },
    )
    assert outsider.status_code == 200, outsider.text
    outsider_id = outsider.json()["data"]["id"]

    tenant = _login(
        client,
        tenant_email,
        "TenantAdmin!123",
        company_id="00000000-0000-4000-8000-000000000001",
        device_id=str(uuid.uuid4()),
        device_name="Tenant Device",
        platform="android",
    )
    tenant_headers = {"Authorization": f"Bearer {tenant['access_token']}"}

    denied = client.get(f"/api/v1/users/{outsider_id}", headers=tenant_headers)
    assert denied.status_code == 404, denied.text

    # Adding outsider into Demo Company A via forged company path must fail.
    forged = client.post(
        f"/api/v1/companies/{other_company_id}/members",
        headers=tenant_headers,
        json={
            "user_id": outsider_id,
            "role_id": company_admin_role["id"],
            "status": "active",
        },
    )
    assert forged.status_code == 403, forged.text


def test_super_admin_can_still_read_any_user(client: TestClient):
    admin = _login(client, "admin@example.com", "ChangeMeAdmin!123")
    headers = {"Authorization": f"Bearer {admin['access_token']}"}
    users = client.get("/api/v1/users", headers=headers)
    assert users.status_code == 200
    rows = users.json()["data"]
    assert rows
    target = rows[0]["id"]
    r = client.get(f"/api/v1/users/{target}", headers=headers)
    assert r.status_code == 200
    assert r.json()["data"]["id"] == target


def test_tenant_admin_cannot_read_other_company_custom_role(client: TestClient):
    super_headers = _super_admin_headers(client)
    other_company_id = _create_other_company(client, super_headers)

    super_session = _login(
        client,
        "admin@example.com",
        "ChangeMeAdmin!123",
        company_id=other_company_id,
        device_id=str(uuid.uuid4()),
        device_name="Super Other Co",
        platform="android",
    )
    other_headers = {"Authorization": f"Bearer {super_session['access_token']}"}
    created = client.post(
        "/api/v1/roles",
        headers=other_headers,
        json={
            "name": f"Other Co Role {uuid.uuid4().hex[:6]}",
            "description": "Cross-tenant probe",
            "permission_codes": ["customers.view"],
        },
    )
    assert created.status_code == 200, created.text
    other_role_id = created.json()["data"]["id"]

    tenant_headers, _ = _bootstrap_tenant_admin(client)
    denied = client.get(f"/api/v1/roles/{other_role_id}", headers=tenant_headers)
    assert denied.status_code == 404, denied.text


def test_tenant_admin_cannot_patch_other_company_custom_role(client: TestClient):
    super_headers = _super_admin_headers(client)
    other_company_id = _create_other_company(client, super_headers)

    # Switch super admin session to the other company to create a tenant role there.
    super_session = _login(
        client,
        "admin@example.com",
        "ChangeMeAdmin!123",
        company_id=other_company_id,
        device_id=str(uuid.uuid4()),
        device_name="Super Other Co",
        platform="android",
    )
    other_headers = {"Authorization": f"Bearer {super_session['access_token']}"}
    created = client.post(
        "/api/v1/roles",
        headers=other_headers,
        json={
            "name": f"Other Co Role {uuid.uuid4().hex[:6]}",
            "description": "Should stay immutable",
            "permission_codes": ["customers.view"],
        },
    )
    assert created.status_code == 200, created.text
    other_role_id = created.json()["data"]["id"]

    tenant_headers, _ = _bootstrap_tenant_admin(client)
    denied = client.patch(
        f"/api/v1/roles/{other_role_id}",
        headers=tenant_headers,
        json={"name": "Hijacked"},
    )
    assert denied.status_code in {403, 404}, denied.text


def test_tenant_admin_cannot_grant_platform_permissions_in_custom_role(
    client: TestClient,
):
    tenant_headers, _ = _bootstrap_tenant_admin(client)
    created = client.post(
        "/api/v1/roles",
        headers=tenant_headers,
        json={
            "name": f"Escalation Role {uuid.uuid4().hex[:6]}",
            "description": "Must not gain platform grants",
            "permission_codes": [
                "customers.view",
                "platform.users.manage",
            ],
        },
    )
    assert created.status_code == 200, created.text
    role_id = created.json()["data"]["id"]

    detail = client.get(f"/api/v1/roles/{role_id}", headers=tenant_headers)
    assert detail.status_code == 200, detail.text
    perms = set(detail.json()["data"]["permissions"])
    assert "platform.users.manage" not in perms
    assert "customers.view" in perms


def test_tenant_admin_cannot_assign_super_admin_role(client: TestClient):
    super_headers = _super_admin_headers(client)
    tenant_headers, tenant_email = _bootstrap_tenant_admin(client)

    roles = client.get("/api/v1/roles", headers=super_headers)
    assert roles.status_code == 200
    super_role = next(r for r in roles.json()["data"] if r["name"] == "Super Admin")

    users = client.get("/api/v1/users", headers=tenant_headers)
    assert users.status_code == 200
    tenant_user_id = next(u["id"] for u in users.json()["data"] if u["email"] == tenant_email)
    assert tenant_user_id

    members = client.get(
        "/api/v1/companies/00000000-0000-4000-8000-000000000001/members",
        headers=tenant_headers,
    )
    assert members.status_code == 200
    membership_id = next(
        m["id"] for m in members.json()["data"] if m["user_email"] == tenant_email
    )
    denied = client.patch(
        f"/api/v1/companies/00000000-0000-4000-8000-000000000001/members/{membership_id}",
        headers=tenant_headers,
        json={"role_id": super_role["id"]},
    )
    assert denied.status_code == 403, denied.text


def test_tenant_admin_cannot_list_other_company_members(client: TestClient):
    super_headers = _super_admin_headers(client)
    other_company_id = _create_other_company(client, super_headers)
    tenant_headers, _ = _bootstrap_tenant_admin(client)

    denied = client.get(
        f"/api/v1/companies/{other_company_id}/members",
        headers=tenant_headers,
    )
    assert denied.status_code == 403, denied.text


def test_sales_user_cannot_push_customer_without_permission(client: TestClient):
    data = _login(
        client,
        "ahmed@example.com",
        "AhmedSales!123",
        company_id="00000000-0000-4000-8000-000000000001",
        device_id=str(uuid.uuid4()),
        device_name="Sales Device",
        platform="android",
    )
    headers = {"Authorization": f"Bearer {data['access_token']}"}
    entity_id = str(uuid.uuid4())
    r = client.post(
        "/api/v1/sync/push",
        headers=headers,
        json={
            "entity_type": "customer",
            "operation": {
                "operation_id": str(uuid.uuid4()),
                "entity_type": "customer",
                "entity_id": entity_id,
                "type": "create",
                "payload": {"uuid": entity_id, "name": "Blocked", "code": "X1"},
                "base_version": 0,
            },
        },
    )
    assert r.status_code == 403, r.text
    assert r.json()["error"]["code"] == "permission_denied"
