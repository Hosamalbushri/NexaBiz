# Experimental Sync — Architecture Diagrams

> **Label:** experimental — not production-ready.

## 1. Backend architecture

```mermaid
flowchart TB
  subgraph Flutter
    SM[SyncManager]
    Q[SyncQueue]
    H[SyncEntityHandlers]
    API[RemoteSyncApi]
    HTTP[HttpRemoteSyncApi]
    MEM[InMemoryRemoteSyncApi]
    SM --> Q
    SM --> H
    H --> API
    API --> HTTP
    API --> MEM
  end

  subgraph Backend["backend/ FastAPI"]
    R[sync router]
    S[SyncService]
    AUTH[Bearer + company/user/device]
    R --> AUTH --> S
  end

  subgraph PG[(PostgreSQL)]
    E[sync_entities]
    C[sync_changes]
    O[sync_operations]
    T[companies / sync_sequences]
  end

  HTTP -->|HTTP JSON| R
  S --> E
  S --> C
  S --> O
  S --> T
```

## 2. Database schema

```mermaid
erDiagram
  companies ||--o{ sync_entities : owns
  companies ||--o{ sync_changes : owns
  companies ||--o{ sync_operations : owns
  companies ||--|| sync_sequences : has

  companies {
    uuid id PK
    string name
    timestamptz created_at
  }

  sync_entities {
    int id PK
    uuid company_id FK
    string entity_type
    uuid entity_uuid
    int version
    jsonb payload
    timestamptz created_at
    timestamptz updated_at
    timestamptz deleted_at
  }

  sync_changes {
    int id PK
    bigint sequence
    uuid company_id FK
    string entity_type
    uuid entity_uuid
    string operation
    int version
    jsonb payload
    bool deleted
    timestamptz created_at
  }

  sync_operations {
    int id PK
    uuid company_id FK
    uuid operation_id
    string entity_type
    uuid entity_uuid
    string operation_type
    string status
    jsonb result
    uuid user_id
    uuid device_id
    timestamptz processed_at
  }

  sync_sequences {
    uuid company_id PK
    bigint next_value
  }
```

## 3. Synchronization sequence (push then pull)

```mermaid
sequenceDiagram
  participant UI as Flutter UI
  participant Local as Local DB
  participant Queue as SyncQueue
  participant Mgr as SyncManager
  participant Http as HttpRemoteSyncApi
  participant API as FastAPI
  participant DB as PostgreSQL

  UI->>Local: Create Customer Ahmed
  Local->>Queue: enqueue CREATE (pending)
  Mgr->>Queue: peekReady
  Mgr->>Http: push(operation)
  Http->>API: POST /api/v1/sync/push
  API->>DB: insert sync_entities + sync_changes + sync_operations
  API-->>Http: SyncUploadAck version=1
  Http-->>Mgr: ack
  Mgr->>Local: markLocalSynced
  Mgr->>Queue: remove op

  Note over Mgr,DB: Device B
  Mgr->>Http: pull(entityType, since/cursor)
  Http->>API: GET /api/v1/sync/pull
  API->>DB: select sync_changes > cursor
  API-->>Http: changes + next_cursor
  Http-->>Mgr: SyncRemoteChange[]
  Mgr->>Local: applyRemoteChange
```

## 4. Offline → online

```mermaid
sequenceDiagram
  participant User
  participant App as Flutter (offline)
  participant Queue as SyncQueue
  participant Net as Connectivity
  participant API as Backend

  User->>App: Edit while offline
  App->>App: Local DB update + UI
  App->>Queue: UPDATE pending
  Net-->>App: online
  App->>API: push pending ops (retry/backoff on failure)
  API-->>App: ack or conflict
```

## 5. Conflict flow

```mermaid
sequenceDiagram
  participant A as Device A
  participant B as Device B
  participant API as Backend

  A->>API: UPDATE base_version=1 → success version=2
  B->>API: UPDATE base_version=1
  API-->>B: 409 conflict + server_record (version 2)
  B->>B: SyncStatus.conflict (no silent overwrite)
```

## 6. Two-device sync

```mermaid
flowchart LR
  A[Device A] -->|CREATE Ahmed| S[(Same company DB)]
  B[Device B] -->|PULL| S
  B -->|UPDATE Ahmed| S
  A -->|PULL update| S
```
