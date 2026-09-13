# NEXABIZ ERP — SYNCHRONIZATION SCHEMA SPECIFICATION (SYNC_SCHEMA.md)

## 1. Executive Summary & Semantic Requirement

The NexaBiz Synchronization Architecture governs offline-first local data persistence and server synchronization.

### Non-Negotiable Semantic Requirement
> After a successful local authoritative business commit, required synchronization intent must remain durably recoverable according to the final sync architecture.

Local SQLite transactions MUST NOT depend on immediate remote network availability. Once a transaction is committed locally, its sync intent MUST be durably recorded so that background synchronization workers can transmit changes to the Laravel backend without data loss or duplication.

---

## 2. Current Codebase Evidence & Decision D-11 Status

### 2.1 Current Codebase Evidence
Forensic analysis of the current codebase identifies two existing synchronization persistence mechanisms:
1. **SQLite `sync_operations`**: Relational table in SQLite.
2. **Hive `sync_queue`**: Key-value queue managed via Hive.

### 2.2 Decision D-11 Status
```text
UNRESOLVED UNDER DECISION D-11
Neither SQLite sync_operations nor Hive sync_queue is declared the final canonical authority.
The physical synchronization storage model remains UNRESOLVED under D-11.
```

---

## 3. Sync Identity & Idempotency Rules (Decision D-12 Resolved)

1. **Global Technical Identity**: All synced entities use **UUID v7 (RFC 9562)** as their canonical global entity identity (`entity_id`). Clients generate UUID v7 locally without requiring server roundtrips.
2. **Company Scope Guarantee**: Sync payload processing on the Laravel backend strictly enforces tenant isolation (`company_id`). No sync operation from Company A may mutate Company B state.
3. **Refined Idempotency Model**: Every sync operation carries an explicit `idempotency_key` (UUID v7 or deterministic action hash: `SHA256(company_id:action_type:source_document_id:sequence)`). Operation identity is strictly decoupled from entity identity. Remote endpoints reject duplicate submission attempts without re-executing side effects.
