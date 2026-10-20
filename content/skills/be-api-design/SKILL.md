---
name: be-api-design
description: Design or add an HTTP API endpoint. Use when asked to "add an endpoint", "design this API", "REST/OpenAPI", "error format", "pagination", "idempotency", or version an API. Not auth hardening, see be-security; not schema or queries, see be-data-access.
targets: [all]
---
## API Design

Add an endpoint end to end, contract first. Stack-agnostic; framework deltas live in [[be-fastapi]], [[be-django]], [[be-node]], [[be-symfony]].

### Workflow
1. Contract first: write the OpenAPI 3.1 operation (path, schemas, responses, errors) and agree on it before code.
2. Pick resource + method. Plural noun, no verbs in the path.
3. Validate input at the boundary. Separate input and output schemas; allowlist fields so clients cannot set `id`, `role`, `owner_id`.
4. Authz: caller may act on this object ([[be-security]]).
5. Handler parses and returns; business logic lives in a service.
6. Map every failure to a problem response (below).
7. Lists: paginate. Non-idempotent POST that must be retry-safe: add `Idempotency-Key`.
8. Tests: happy path, validation, authz denial, not found, conflict ([[cq-testing]]).
9. Update the spec and examples; the contract is the docs.

### Rules
- Resources: `/orders`, `/orders/{id}`, `/orders/{id}/items`. GET safe and idempotent; PUT replaces; PATCH partial; DELETE idempotent.
- Non-CRUD actions: custom method, `POST /orders/{id}:cancel` (Google AIP-136).
- Status: 201 + `Location` on create; 204 no body; 400 malformed, 422 well-formed but invalid; 401 unauthenticated, 403 forbidden; 404 also to hide existence of others' objects; 409 state conflict; 429 + `Retry-After`.
- Errors: RFC 9457 `application/problem+json`. Never leak stack traces or SQL.
```json
{
  "type": "https://api.example.com/problems/validation",
  "title": "Validation failed",
  "status": 422,
  "detail": "2 fields are invalid.",
  "instance": "/orders",
  "errors": [{ "pointer": "/items/0/quantity", "detail": "must be >= 1" }]
}
```
- Pagination: cursor with opaque token. Request `page_size` (server-capped), response `next_page_token`. Offset only for small admin lists.
- Idempotency-Key: store key + request fingerprint + response. Same key, different payload: 422. Same key still in flight: 409. Expire after ~24h. The IETF draft expired; this follows Stripe's practice.
- Versioning: additive changes only (new optional fields, new endpoints). Clients are tolerant readers and ignore unknown fields. Breaking change: new major version (`/v2`).
- Timestamps ISO-8601 UTC (`2026-10-20T14:03:00Z`). IDs are strings. One casing convention across the API.

### Avoid → Use instead
| Avoid | Use instead |
|---|---|
| `POST /createOrder` | `POST /orders` |
| 200 with `{"error": ...}` | Real status + problem body |
| `?page=5` on large tables | Cursor token |
| Binding request body straight to the DB model | Input schema, then map to model |
| Removing or renaming a field | Add the new field, deprecate the old, remove in next major |
| 403 for another user's object | 404 |

### Not this
- Authn, JWT, SSRF, rate limits: [[be-security]].
- Transactions, indexes, N+1: [[be-data-access]].
- Timeouts, retries: [[be-reliability]].

Sources: Google AIP, Zalando RESTful API Guidelines, RFC 9457.
