---
name: be-observability
description: Add logging, metrics, and tracing to a backend. Use when asked to instrument a service or endpoint, set up OpenTelemetry, structured logs, request IDs, RED metrics, alerts, or to stop logging secrets. Not debugging a live issue, see cq-debug.
targets: [all]
---
## Observability

Make behavior answerable from outside: what failed, for whom, how often, how slow. Use OpenTelemetry (opentelemetry.io) so the backend is swappable.

### Workflow: instrument a service or endpoint
1. Initialize the OpenTelemetry SDK once at startup. Set `service.name`, version, environment as resource attributes. Prefer auto-instrumentation for HTTP server/client, DB, and queue libraries.
2. Name attributes by OTel semantic conventions (`http.request.method`, `http.route`, `db.system.name`), not invented keys.
3. Propagate the W3C `traceparent` header on every inbound and outbound call and through job payloads/message headers.
4. Logs: structured JSON to stdout, one event per line. Every line carries `trace_id` and `span_id` (or a request ID if no tracing). The platform ships logs; the app never writes files.
5. Metrics per endpoint (RED): request rate, error rate, duration histogram. Per pool or queue (USE): utilization, saturation, errors.
6. Add custom spans only around meaningful units: a business operation, an external call.
7. Define alerts on user-visible symptoms, then verify by triggering a failure once in staging.

### Logs
- Levels: `error` needs a human to act. `warn` is unexpected but handled. `info` is a business or lifecycle event. `debug` is off in prod by default.
- Log once, where the error is handled. Do not log and rethrow: one failure becomes five lines. Lower layers add context to the error; the boundary logs it.
- Message is a constant string; variable data goes in fields: `{"msg":"payment failed","order_id":"o_42","reason":"card_declined"}`.
- Never log secrets, tokens, passwords, full card numbers, or raw PII. Redact at the logger (denylist of field names plus `Authorization`/`Cookie` headers), not at each call site ([[be-security]]).

### Metrics
- Label cardinality must be bounded. Labels: route template (`/users/{id}`), method, status class. Never user IDs, emails, raw URLs, or error text. Each unique combination is a stored series.
- Durations: histogram with explicit buckets, not average. Alert on p95/p99.
- Count outcomes (`result=ok|error|timeout`) so error ratio is computable.

### Alerts
- Page on symptoms (SLO burn rate, error ratio, latency over target), not causes (CPU, one pod restart).
- Every page is actionable and links to a runbook. Noisy alert: fix or delete it.
- Causes (saturation, queue depth, DLQ size) go on dashboards and tickets (Google SRE book, ch. 6).

### Rules
- Telemetry must never break a request: exporters are async, failures swallowed.
- Sample traces if volume requires; keeping every error trace needs tail sampling (head sampling decides before the outcome is known).
- Same IDs flow from the edge to the DB call, so one request is one trace.

### Avoid → Use instead
| Avoid | Use instead |
|---|---|
| `print` / unstructured text logs | JSON logs with trace_id |
| `log.error(e); throw e` | Log once at the handler |
| Label `user_id` or raw path | Route template, bounded enum |
| Average latency | Histogram, p95/p99 |
| Alert on CPU > 80% | Alert on SLO burn |
| Log request body | Log IDs and sizes |

### Not this
Debugging a live issue: [[cq-debug]]. Retry and timeout logging: [[be-reliability]].
