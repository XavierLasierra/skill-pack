---
targets: [all]
---
## Backend Baseline

- Object-level authz on every request that takes an ID: check the caller may access that object.
- Parameterized queries only; never build SQL from input.
- No secrets in code or logs.
- Explicit timeout on every outbound call.
- Config from env, validated at startup; fail fast.
- Structured logs to stdout.
- Paginate every list endpoint.
- API changes additive-only within a version.
- No network calls inside DB transactions; side effects (emails, queues) after commit.
- Depth: `be-` skills ([[be-api-design]], [[be-security]], [[be-data-access]], [[be-reliability]]).
