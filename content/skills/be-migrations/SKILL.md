---
name: be-migrations
description: Plan and review database schema migrations. Use when asked to "add a column", "rename a table", "drop a column", "backfill", "add an index", "make it NOT NULL", or review a migration diff. Not query tuning or transactions, see be-data-access.
targets: [all]
---
## Migrations

A migration must run while the previous app version is still serving traffic. Change schema in small steps across separate deploys. Tool specifics: [[be-django]], [[be-symfony]], [[be-fastapi]], [[be-node]].

### Workflow
1. Generate the migration with the project's tool. Never hand-edit the schema in prod.
2. Read the generated diff. Autogenerate lies: a rename often appears as drop + add (data loss). Check defaults, nullability, type changes, and dropped objects.
3. Classify each statement safe or unsafe (checklist below).
4. Unsafe change: split into expand, backfill, contract (parallel change), each its own deploy.
5. Verify old and new app versions both work against every intermediate schema.
6. Backfill data in a separate batched job, not inside the schema migration.
7. Set `SET lock_timeout = '5s'` so a blocked DDL fails fast instead of queueing every query behind it.
8. Test up (and down if supported) on a copy of prod-like data and size. Time it.
9. Run as one-off release step before or after the rollout, never on boot of every replica.

### Expand / backfill / contract
Rename `users.name` to `full_name`:
1. Deploy 1 (expand): add `full_name` nullable. App writes both columns, reads old.
2. Backfill `full_name` in batches. Then switch reads to `full_name`.
3. Deploy 2 (contract): stop writing `name`. Deploy 3: drop `name`.

### Add NOT NULL safely (Postgres)
```sql
ALTER TABLE orders ADD COLUMN status text;               -- nullable, no rewrite
-- backfill in batches, app writes status on new rows
ALTER TABLE orders ADD CONSTRAINT orders_status_nn
  CHECK (status IS NOT NULL) NOT VALID;                  -- instant, enforces new rows
ALTER TABLE orders VALIDATE CONSTRAINT orders_status_nn; -- scans, weak lock
ALTER TABLE orders ALTER COLUMN status SET NOT NULL;     -- uses validated CHECK, no scan (PG 12+)
ALTER TABLE orders DROP CONSTRAINT orders_status_nn;
```
Online index: `CREATE INDEX CONCURRENTLY idx_orders_user ON orders (user_id);` Cannot run inside a transaction block, so disable the tool's per-migration transaction. A failed run leaves an `INVALID` index: drop it and retry.

### Safety checklist
- Column drop or type change: no running code still reads it.
- New column with default: fine on PG 11+ for constants; volatile defaults rewrite the table.
- New `UNIQUE`: build the index concurrently, then `ADD CONSTRAINT … UNIQUE USING INDEX`. New `FK`: add `NOT VALID`, then `VALIDATE CONSTRAINT`.
- Large table: no full-table `UPDATE` in one statement. Batch by primary key range.
- Locks: most `ALTER TABLE` forms take ACCESS EXCLUSIVE. Keep it to metadata-only changes.
- MySQL: DDL implicitly commits, no transactional DDL. A failed migration leaves a half-applied state, so keep each migration to one statement.
- Rollback plan: prefer roll-forward. Dropped data cannot come back, so take a backup first.

### Rules
- Never edit a migration that already shipped. Add a new one.
- One logical change per migration.
- Backfills are idempotent and resumable.

### Output contract
```
1. migration 0042_add_full_name   deploy A  expand: add nullable column
2. job backfill_full_name         after A   batches of 1000, idempotent
3. app release                    deploy B  read full_name, write both
4. migration 0043_drop_name       deploy C  contract, after B is 100%
```

### Not this
Query and transaction design: [[be-data-access]].
