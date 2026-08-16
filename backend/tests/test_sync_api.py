from __future__ import annotations

import os
import uuid
from typing import Generator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import JSON, Uuid, create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

os.environ["DEV_API_TOKEN"] = "test-token"
os.environ["ALLOW_DEV_TOKEN"] = "true"
# Rewrite docker-compose hostname so host-side pytest can reach published Postgres.
_db = os.environ.get("DATABASE_URL", "")
if not _db or "@db:" in _db or "@db/" in _db:
    os.environ["DATABASE_URL"] = os.environ.get(
        "TEST_DATABASE_URL",
        "postgresql+psycopg2://sync:sync@localhost:5432/sync_experimental",
    )
os.environ.setdefault(
    "DEFAULT_COMPANY_ID", "00000000-0000-4000-8000-000000000001"
)
os.environ.setdefault(
    "DEFAULT_USER_ID", "00000000-0000-4000-8000-000000000002"
)
os.environ.setdefault(
    "DEFAULT_DEVICE_ID", "00000000-0000-4000-8000-000000000003"
)

from app.core.config import get_settings
from app.core.database import Base, get_db
from app.main import app
from app.auth.seed import seed_identity
from app.models import sync as sync_models  # noqa: F401
from app.models import identity as identity_models  # noqa: F401

get_settings.cache_clear()


def _sqlite_friendly_metadata() -> None:
    """Adapt PostgreSQL-specific column types for in-memory SQLite tests."""
    for table in Base.metadata.tables.values():
        for column in table.columns:
            type_name = column.type.__class__.__name__
            if type_name == "JSONB":
                column.type = JSON()
            elif type_name == "UUID":
                column.type = Uuid(as_uuid=True)


@pytest.fixture()
def db_session() -> Generator[Session, None, None]:
    engine = create_engine(
        "sqlite+pysqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    _sqlite_friendly_metadata()
    Base.metadata.create_all(bind=engine)
    TestingSession = sessionmaker(bind=engine, autocommit=False, autoflush=False)
    session = TestingSession()
    seed_identity(session, get_settings())
    session.commit()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=engine)
        engine.dispose()


@pytest.fixture()
def client(db_session: Session) -> Generator[TestClient, None, None]:
    def _override_db() -> Generator[Session, None, None]:
        yield db_session

    app.dependency_overrides[get_db] = _override_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


@pytest.fixture()
def auth_headers() -> dict[str, str]:
    return {
        "Authorization": "Bearer test-token",
        "X-Company-Id": "00000000-0000-4000-8000-000000000001",
        "X-User-Id": "00000000-0000-4000-8000-000000000002",
        "X-Device-Id": "00000000-0000-4000-8000-0000000000a1",
    }


def _op(
    *,
    entity_type: str = "customer",
    entity_id: uuid.UUID | None = None,
    op_type: str = "create",
    base_version: int = 0,
    payload: dict | None = None,
    operation_id: uuid.UUID | None = None,
) -> dict:
    eid = entity_id or uuid.uuid4()
    return {
        "operation_id": str(operation_id or uuid.uuid4()),
        "entity_type": entity_type,
        "entity_id": str(eid),
        "type": op_type,
        "base_version": base_version,
        "payload": payload
        or {
            "uuid": str(eid),
            "customerCode": "CUS-0001",
            "name": "Ahmed",
            "isActive": True,
            "dataSource": "local",
        },
    }


def test_health(client: TestClient) -> None:
    response = client.get("/health")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert body["database"] == "ok"


def test_unauthorized(client: TestClient) -> None:
    response = client.post(
        "/api/v1/sync/push",
        json={"entity_type": "customer", "operation": _op()},
    )
    assert response.status_code == 401
    assert response.json()["error"]["code"] == "unauthorized"


def test_create_entity(client: TestClient, auth_headers: dict[str, str]) -> None:
    op = _op()
    response = client.post(
        "/api/v1/sync/push",
        headers=auth_headers,
        json={"entity_type": "customer", "operation": op},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["remote_version"] == 1
    assert body["entity_id"] == op["entity_id"]
    assert body["server_payload"]["name"] == "Ahmed"


def test_update_entity(client: TestClient, auth_headers: dict[str, str]) -> None:
    entity_id = uuid.uuid4()
    client.post(
        "/api/v1/sync/push",
        headers=auth_headers,
        json={"entity_type": "customer", "operation": _op(entity_id=entity_id)},
    )
    update = _op(
        entity_id=entity_id,
        op_type="update",
        base_version=1,
        payload={
            "uuid": str(entity_id),
            "customerCode": "CUS-0001",
            "name": "Ahmed Updated",
            "isActive": True,
            "dataSource": "local",
        },
    )
    response = client.post(
        "/api/v1/sync/push",
        headers=auth_headers,
        json={"entity_type": "customer", "operation": update},
    )
    assert response.status_code == 200
    assert response.json()["remote_version"] == 2
    assert response.json()["server_payload"]["name"] == "Ahmed Updated"


def test_update_missing_entity_upserts(
    client: TestClient, auth_headers: dict[str, str]
) -> None:
    """Local update against unknown remote UUID must create (InMemory parity)."""
    entity_id = uuid.uuid4()
    update = _op(
        entity_id=entity_id,
        entity_type="product",
        op_type="update",
        base_version=3,
        payload={
            "uuid": str(entity_id),
            "itemCode": "P-100",
            "name": "Local-only product",
            "price": 12.5,
        },
    )
    response = client.post(
        "/api/v1/sync/push",
        headers=auth_headers,
        json={"entity_type": "product", "operation": update},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["entity_id"] == str(entity_id)
    assert body["remote_version"] == 4
    assert body["server_payload"]["name"] == "Local-only product"

    meta = client.get(
        f"/api/v1/sync/meta/product/{entity_id}",
        headers=auth_headers,
    )
    assert meta.status_code == 200
    assert meta.json()["version"] == 4


def test_soft_delete(client: TestClient, auth_headers: dict[str, str]) -> None:
    entity_id = uuid.uuid4()
    client.post(
        "/api/v1/sync/push",
        headers=auth_headers,
        json={"entity_type": "customer", "operation": _op(entity_id=entity_id)},
    )
    delete = _op(entity_id=entity_id, op_type="delete", base_version=1)
    response = client.post(
        "/api/v1/sync/push",
        headers=auth_headers,
        json={"entity_type": "customer", "operation": delete},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["remote_version"] == 2
    assert body["server_payload"]["deleted"] is True

    pull = client.get(
        "/api/v1/sync/pull",
        headers=auth_headers,
        params={"entity_type": "customer", "cursor": 0},
    )
    assert pull.status_code == 200
    changes = pull.json()["changes"]
    assert any(c["deleted"] for c in changes if c["entity_id"] == str(entity_id))


def test_duplicate_operation_idempotent(
    client: TestClient, auth_headers: dict[str, str]
) -> None:
    op = _op()
    first = client.post(
        "/api/v1/sync/push",
        headers=auth_headers,
        json={"entity_type": "customer", "operation": op},
    )
    second = client.post(
        "/api/v1/sync/push",
        headers=auth_headers,
        json={"entity_type": "customer", "operation": op},
    )
    assert first.status_code == 200
    assert second.status_code == 200
    assert first.json()["remote_version"] == second.json()["remote_version"]

    pull = client.get(
        "/api/v1/sync/pull",
        headers=auth_headers,
        params={"entity_type": "customer", "cursor": 0},
    )
    creates = [
        c
        for c in pull.json()["changes"]
        if c["entity_id"] == op["entity_id"] and c["operation"] == "create"
    ]
    assert len(creates) == 1


def test_create_idempotent_when_server_already_advanced(
    client: TestClient, auth_headers: dict[str, str]
) -> None:
    """Second device create with stale base_version must not 409."""
    entity_id = uuid.uuid4()
    payload = {
        "uuid": str(entity_id),
        "name": "Cash",
        "accountCode": "1100",
        "isActive": True,
    }
    first = client.post(
        "/api/v1/sync/push",
        headers=auth_headers,
        json={
            "entity_type": "account",
            "operation": _op(
                entity_type="account",
                entity_id=entity_id,
                payload=payload,
            ),
        },
    )
    assert first.status_code == 200
    assert first.json()["remote_version"] == 1

    # Simulate device A update bumping server to v2.
    updated = client.post(
        "/api/v1/sync/push",
        headers=auth_headers,
        json={
            "entity_type": "account",
            "operation": _op(
                entity_type="account",
                entity_id=entity_id,
                op_type="update",
                base_version=1,
                payload={**payload, "name": "Cash (renamed)"},
            ),
        },
    )
    assert updated.status_code == 200
    assert updated.json()["remote_version"] == 2

    # Device B still has a pending seed create (base_version=1 historically).
    second_create = client.post(
        "/api/v1/sync/push",
        headers=auth_headers,
        json={
            "entity_type": "account",
            "operation": _op(
                entity_type="account",
                entity_id=entity_id,
                op_type="create",
                base_version=1,
                payload=payload,
            ),
        },
    )
    assert second_create.status_code == 200
    body = second_create.json()
    assert body["remote_version"] == 2
    assert body["entity_id"] == str(entity_id)


def test_version_conflict(client: TestClient, auth_headers: dict[str, str]) -> None:
    entity_id = uuid.uuid4()
    client.post(
        "/api/v1/sync/push",
        headers=auth_headers,
        json={"entity_type": "customer", "operation": _op(entity_id=entity_id)},
    )
    client.post(
        "/api/v1/sync/push",
        headers=auth_headers,
        json={
            "entity_type": "customer",
            "operation": _op(
                entity_id=entity_id,
                op_type="update",
                base_version=1,
                payload={
                    "uuid": str(entity_id),
                    "name": "From A",
                    "customerCode": "CUS-0001",
                    "isActive": True,
                    "dataSource": "local",
                },
            ),
        },
    )
    conflict = client.post(
        "/api/v1/sync/push",
        headers=auth_headers,
        json={
            "entity_type": "customer",
            "operation": _op(
                entity_id=entity_id,
                op_type="update",
                base_version=1,
                payload={
                    "uuid": str(entity_id),
                    "name": "From B",
                    "customerCode": "CUS-0001",
                    "isActive": True,
                    "dataSource": "local",
                },
            ),
        },
    )
    assert conflict.status_code == 409
    err = conflict.json()["error"]
    assert err["code"] == "conflict"
    assert err["details"]["server_version"] == 2
    assert err["details"]["client_base_version"] == 1
    assert err["details"]["server_record"]["name"] == "From A"


def test_pull_and_cursor(client: TestClient, auth_headers: dict[str, str]) -> None:
    for name in ("A", "B", "C"):
        eid = uuid.uuid4()
        client.post(
            "/api/v1/sync/push",
            headers=auth_headers,
            json={
                "entity_type": "customer",
                "operation": _op(
                    entity_id=eid,
                    payload={
                        "uuid": str(eid),
                        "name": name,
                        "customerCode": f"CUS-{name}",
                        "isActive": True,
                        "dataSource": "local",
                    },
                ),
            },
        )

    page1 = client.get(
        "/api/v1/sync/pull",
        headers=auth_headers,
        params={"entity_type": "customer", "cursor": 0, "limit": 2},
    ).json()
    assert len(page1["changes"]) == 2
    assert page1["has_more"] is True
    cursor = page1["next_cursor"]

    page2 = client.get(
        "/api/v1/sync/pull",
        headers=auth_headers,
        params={"entity_type": "customer", "cursor": cursor, "limit": 10},
    ).json()
    assert len(page2["changes"]) == 1
    assert page2["has_more"] is False


def test_multiple_devices(client: TestClient, auth_headers: dict[str, str]) -> None:
    device_a = {
        **auth_headers,
        "X-Device-Id": "00000000-0000-4000-8000-0000000000a1",
    }
    device_b = {
        **auth_headers,
        "X-Device-Id": "00000000-0000-4000-8000-0000000000b2",
    }
    entity_id = uuid.uuid4()

    create = client.post(
        "/api/v1/sync/push",
        headers=device_a,
        json={"entity_type": "customer", "operation": _op(entity_id=entity_id)},
    )
    assert create.status_code == 200

    pull_b = client.get(
        "/api/v1/sync/pull",
        headers=device_b,
        params={"entity_type": "customer", "cursor": 0},
    ).json()
    assert any(
        c["entity_id"] == str(entity_id) and c["payload"]["name"] == "Ahmed"
        for c in pull_b["changes"]
    )

    update = client.post(
        "/api/v1/sync/push",
        headers=device_b,
        json={
            "entity_type": "customer",
            "operation": _op(
                entity_id=entity_id,
                op_type="update",
                base_version=1,
                payload={
                    "uuid": str(entity_id),
                    "name": "Ahmed From B",
                    "customerCode": "CUS-0001",
                    "isActive": True,
                    "dataSource": "local",
                },
            ),
        },
    )
    assert update.status_code == 200
    assert update.json()["remote_version"] == 2

    pull_a = client.get(
        "/api/v1/sync/pull",
        headers=device_a,
        params={"entity_type": "customer", "cursor": 1},
    ).json()
    assert any(
        c["entity_id"] == str(entity_id) and c["payload"]["name"] == "Ahmed From B"
        for c in pull_a["changes"]
    )


def test_batch_push_partial_conflict(
    client: TestClient, auth_headers: dict[str, str]
) -> None:
    entity_id = uuid.uuid4()
    client.post(
        "/api/v1/sync/push",
        headers=auth_headers,
        json={"entity_type": "customer", "operation": _op(entity_id=entity_id)},
    )
    other = uuid.uuid4()
    batch = client.post(
        "/api/v1/sync/push/batch",
        headers=auth_headers,
        json={
            "operations": [
                _op(
                    entity_id=other,
                    payload={
                        "uuid": str(other),
                        "name": "New",
                        "customerCode": "CUS-NEW",
                        "isActive": True,
                        "dataSource": "local",
                    },
                ),
                _op(
                    entity_id=entity_id,
                    op_type="update",
                    base_version=0,
                    payload={
                        "uuid": str(entity_id),
                        "name": "Stale",
                        "customerCode": "CUS-0001",
                        "isActive": True,
                        "dataSource": "local",
                    },
                ),
            ]
        },
    )
    assert batch.status_code == 200
    results = batch.json()["results"]
    assert results[0]["status"] == "success"
    assert results[1]["status"] == "conflict"


def test_failed_request_retry_same_operation_id(
    client: TestClient, auth_headers: dict[str, str]
) -> None:
    op = _op()
    r1 = client.post(
        "/api/v1/sync/push",
        headers=auth_headers,
        json={"entity_type": "customer", "operation": op},
    )
    r2 = client.post(
        "/api/v1/sync/push",
        headers=auth_headers,
        json={"entity_type": "customer", "operation": op},
    )
    assert r1.json() == r2.json()


def test_client_company_header_cannot_switch_tenant(
    client: TestClient, auth_headers: dict[str, str]
) -> None:
    """Dev-token company comes from seed identity; forged X-Company-Id is ignored."""
    forged = {
        **auth_headers,
        "X-Company-Id": "00000000-0000-4000-8000-0000000000aa",
    }
    entity_id = uuid.uuid4()
    created = client.post(
        "/api/v1/sync/push",
        headers=forged,
        json={"entity_type": "customer", "operation": _op(entity_id=entity_id)},
    )
    assert created.status_code == 200, created.text

    pull = client.get(
        "/api/v1/sync/pull",
        headers=auth_headers,
        params={"entity_type": "customer", "cursor": 0},
    )
    assert pull.status_code == 200
    assert any(
        c["entity_id"] == str(entity_id) for c in pull.json()["changes"]
    ), pull.text


def test_get_meta(client: TestClient, auth_headers: dict[str, str]) -> None:
    entity_id = uuid.uuid4()
    client.post(
        "/api/v1/sync/push",
        headers=auth_headers,
        json={"entity_type": "customer", "operation": _op(entity_id=entity_id)},
    )
    meta = client.get(
        f"/api/v1/sync/meta/customer/{entity_id}",
        headers=auth_headers,
    )
    assert meta.status_code == 200
    body = meta.json()
    assert body["entity_id"] == str(entity_id)
    assert body["version"] == 1


def test_product_and_inventory_entity_types(
    client: TestClient, auth_headers: dict[str, str]
) -> None:
    product_id = uuid.uuid4()
    inv_id = uuid.uuid4()
    p = client.post(
        "/api/v1/sync/push",
        headers=auth_headers,
        json={
            "entity_type": "product",
            "operation": {
                "operation_id": str(uuid.uuid4()),
                "entity_type": "product",
                "entity_id": str(product_id),
                "type": "create",
                "base_version": 0,
                "payload": {
                    "uuid": str(product_id),
                    "itemCode": "SKU-1",
                    "name": "Widget",
                    "packSize": 12,
                    "price": 9.5,
                },
            },
        },
    )
    i = client.post(
        "/api/v1/sync/push",
        headers=auth_headers,
        json={
            "entity_type": "inventory_item",
            "operation": {
                "operation_id": str(uuid.uuid4()),
                "entity_type": "inventory_item",
                "entity_id": str(inv_id),
                "type": "create",
                "base_version": 0,
                "payload": {
                    "id": str(inv_id),
                    "itemCode": "SKU-1",
                    "itemName": "Widget",
                    "systemQuantity": 10,
                    "actualQuantity": 9,
                },
            },
        },
    )
    assert p.status_code == 200
    assert i.status_code == 200


def test_journal_entry_entity_type(
    client: TestClient, auth_headers: dict[str, str]
) -> None:
    entry_id = uuid.uuid4()
    line_id = uuid.uuid4()
    account_id = uuid.uuid4()
    r = client.post(
        "/api/v1/sync/push",
        headers=auth_headers,
        json={
            "entity_type": "journal_entry",
            "operation": {
                "operation_id": str(uuid.uuid4()),
                "entity_type": "journal_entry",
                "entity_id": str(entry_id),
                "type": "create",
                "base_version": 0,
                "payload": {
                    "uuid": str(entry_id),
                    "voucherNumber": "J-1",
                    "voucherType": "بيع نقدي",
                    "currencyCode": "SAR",
                    "isPosted": True,
                    "sourceType": "sale",
                    "sourceId": str(uuid.uuid4()),
                    "lines": [
                        {
                            "uuid": str(line_id),
                            "accountUuid": str(account_id),
                            "accountCode": "4100",
                            "debit": 0,
                            "credit": 50,
                            "currencyCode": "SAR",
                            "sortOrder": 0,
                        }
                    ],
                },
            },
        },
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["entity_id"] == str(entry_id)
    assert body["remote_version"] == 1

    pull = client.get(
        "/api/v1/sync/pull",
        headers=auth_headers,
        params={"entity_type": "journal_entry", "cursor": 0},
    )
    assert pull.status_code == 200
    changes = pull.json()["changes"]
    assert any(c["entity_id"] == str(entry_id) for c in changes)
