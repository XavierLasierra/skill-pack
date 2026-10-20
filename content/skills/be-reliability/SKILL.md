---
name: be-reliability
description: Make a backend resilient. Use when asked about timeouts, retries, backoff, circuit breakers, background jobs, queues, dead-letter, idempotent consumers, graceful shutdown, or health/readiness probes. Not DB races or outbox design, see be-data-access.
targets: [all]
---
## Reliability

Every dependency will be slow or down eventually. Bound the damage: time limits, careful retries, idempotent work, clean shutdown.

### Workflow: outbound calls
1. Set an explicit timeout on every call (connect and total). Library defaults are often infinite.
2. Propagate the caller's deadline downstream. Do not start work that cannot finish before it expires.
3. Retry only idempotent or keyed (`Idempotency-Key`) requests, and only transient failures: 5xx, 429, timeout, connection reset. Never retry other 4xx.
4. Retry at one layer only. Three layers with 3 attempts each is 27 calls per request.
5. Cap attempts and add a retry budget (for example retries at most 10% of requests) so an outage is not amplified.
6. Honor `Retry-After` when present.
7. Flaky dependency: wrap in a circuit breaker (closed, open after N failures, half-open probe) with a fallback: cached value, degraded result, or fast error.
8. Isolate with bulkheads: separate connection pools or concurrency limits per dependency.

```
def call_with_retry(op, max_attempts=4, base=0.1, cap=5.0):
    for attempt in range(max_attempts):
        try:
            return op(timeout=2.0)
        except TransientError:
            if attempt == max_attempts - 1:
                raise
            sleep(random.uniform(0, min(cap, base * 2 ** attempt)))   # full jitter
```

### Workflow: background jobs
1. Payload carries IDs, not blobs. The job loads fresh state.
2. Delivery is at-least-once: make the consumer idempotent. Dedupe by message ID, or write via natural-key upsert ([[be-data-access]]).
3. Enqueue after the transaction commits, or use the outbox. Enqueue-before-commit lets the worker run before the data exists.
4. Set max attempts with backoff, then move to a dead-letter queue. Alert on DLQ depth, and keep a replay path.
5. Long jobs checkpoint progress so a retry resumes, not restarts.
6. Per-job timeout shorter than the queue's visibility timeout.

### Workflow: process lifecycle
1. On SIGTERM: stop accepting new work, drain in-flight within a deadline (shorter than the orchestrator's kill grace period), close pools, exit 0.
2. Liveness answers "is this process wedged?" and checks nothing external. Readiness answers "send me traffic?".
3. Readiness must not check downstream dependencies transitively: one outage would pull every replica out of rotation. Check only local needs (started, pool usable).

### Rules
- Timeouts are budgets: client timeout greater than server work time, less than caller's deadline.
- Log each retry with attempt number and cause ([[be-observability]]).
- Test failure paths: timeout, 5xx, partial failure, duplicate delivery ([[cq-testing]]).

### Avoid → Use instead
| Avoid | Use instead |
|---|---|
| No timeout | Explicit connect + total timeout |
| Fixed-delay or immediate retry | Capped exponential backoff, full jitter |
| Retrying non-idempotent POST | Idempotency key, or do not retry |
| Retry in client, gateway, and SDK | One retry layer |
| Whole object in queue message | Entity ID |
| Infinite redelivery | Max attempts + DLQ |
| Readiness pings the database and 3 APIs | Local readiness only |

### Not this
Debugging an active incident: [[cq-debug]]. Endpoint idempotency contract: [[be-api-design]].
