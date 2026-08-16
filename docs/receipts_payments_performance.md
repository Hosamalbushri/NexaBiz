# Receipts & Payments — performance notes

## Measured (in-memory Drift / SQLite)

Command:

```bash
flutter test test/receipts_payments_benchmark_test.dart
```

Sample run on this machine (2026-08-16):

| Size | Seed (ms) | Filtered list page (ms) | Dashboard aggregate (ms) |
|------|-----------|-------------------------|-------------------------|
| 100 | 292 | 21 | 3 |
| 1_000 | 980 | 7 | 2 |
| 10_000 | 5_147 | 27 | 17 |
| 100_000 | 39_781 | 222 | 158 |

Notes:

- Seed time is dominated by per-row inserts (realistic write path including sync enqueue metadata).
- List query is page size 30 with SQL `LIKE` search — not a full table load into Dart.
- Dashboard uses one SQL aggregate statement.

## NOT MEASURED

| Metric | Reason |
|--------|--------|
| 1_000_000 rows | Out of default CI time/memory budget |
| Form UI latency / FPS | Needs device instrumentation |
| Process memory under Flutter UI | Needs profiling tools |
| Sync round-trip latency | Depends on network/backend |
| Debounce UX feel | Subjective (UI debounce = 300ms) |

## Strategy (implemented)

- Dashboard: single SQL aggregate query
- List: indexed filters + offset pagination (page size 30) + projection columns
- Search: SQL `LIKE` on number/party/reference — not in-Dart filtering of full sets
- Soft-delete / cancel excluded from list aggregates
