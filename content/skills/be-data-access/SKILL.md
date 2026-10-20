---
name: be-data-access
description: Write or review database access code. Use when asked about N+1, transactions, race conditions, locking, indexes, slow queries, pagination, upserts, or publishing events from a write. Not schema changes, see be-migrations. ORM specifics, see be-fastapi, be-django, be-node, be-symfony.
targets: [all]
---
## Data access

Decide what a query loads before it runs. Let the database enforce invariants. ORM specifics live in [[be-fastapi]], [[be-django]], [[be-node]], [[be-symfony]].

### Workflow
1. List what the request needs: rows, relations, columns. Load exactly that, in a fixed number of queries.
2. Relations: eager-load or batch (`WHERE id = ANY($1)`). A query inside a loop is N+1.
3. Select only needed columns. Never `SELECT *` on wide tables or hot paths.
4. Put invariants in the schema: `UNIQUE`, `FOREIGN KEY`, `NOT NULL`, `CHECK`. App-level checks alone race.
5. Writes that depend on a prior read: pick a concurrency strategy (below). Never read-then-write unguarded.
6. Open the transaction late, close it early. Fetch inputs first, then `BEGIN`, write, `COMMIT`.
7. Side effects (email, webhook, enqueue) run after commit, or go through an outbox.
8. Filter, join, or sort on a column? Confirm an index serves it: `EXPLAIN (ANALYZE, BUFFERS) <query>`. Look for Seq Scan on big tables and rows removed by filter.
9. Test with realistic row counts and two concurrent sessions ([[cq-testing]]). Slow in prod: [[cq-debug]].

### Read-modify-write races
Postgres default isolation is READ COMMITTED: each statement sees the latest committed data, so two transactions can both read the same balance.
```sql
-- pessimistic: lock the row until commit
BEGIN;
SELECT balance FROM accounts WHERE id = $1 FOR UPDATE;
UPDATE accounts SET balance = balance - $2 WHERE id = $1;
COMMIT;

-- optimistic: no lock held; app retries on 0 rows affected
UPDATE docs SET body = $3, version = version + 1
WHERE id = $1 AND version = $2;
```
- Prefer a single atomic statement (`SET balance = balance - $2 WHERE balance >= $2`) when it fits.
- Pessimistic for hot contention and short transactions; optimistic for low contention and user-edit flows.
- Lock rows in a consistent order to avoid deadlocks. Use `FOR UPDATE SKIP LOCKED` for job-queue tables.
- Upsert with `INSERT … ON CONFLICT (email) DO UPDATE SET name = EXCLUDED.name`, not select-then-insert.

### Events: transactional outbox
Never dual-write DB and broker: one succeeds, one fails, state diverges.
1. In the same transaction as the change, `INSERT` an event row into `outbox`.
2. A relay process reads unsent rows, publishes, marks them sent.
3. Delivery is at-least-once, so consumers dedupe ([[be-reliability]]).

### Rules
- No network call inside a transaction: it holds locks and a pooled connection while waiting.
- Paginate every list. Keyset: `WHERE (created_at, id) < ($1, $2) ORDER BY created_at DESC, id DESC LIMIT 50`.
- Index foreign keys (Postgres does not do it for you) and every filter/sort column. Match composite order to the query.
- Bulk work in batches (500-5000 rows), not row-by-row and not one giant transaction.

### Avoid → Use instead
| Avoid | Use instead |
|---|---|
| `SELECT count(*)` to test existence | `SELECT EXISTS (SELECT 1 FROM t WHERE …)` |
| `OFFSET 100000` deep pages | Keyset pagination |
| Float for money | `numeric(12,2)` or integer cents |
| `timestamp` without time zone | `timestamptz` |
| Select-then-insert for uniqueness | `UNIQUE` + `ON CONFLICT` |
| Check-then-act in app code | Constraint, `FOR UPDATE`, or version column |
| Publish to broker inside the transaction | Outbox row, publish after commit |

### Not this
Schema changes and backfills: [[be-migrations]]. Endpoint shape and pagination contract: [[be-api-design]]. Injection and authz: [[be-security]].
