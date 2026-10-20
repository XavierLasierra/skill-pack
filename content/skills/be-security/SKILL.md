---
name: be-security
description: Harden a backend endpoint or feature. Use when asked for "security checklist", "OWASP", "authz bug", "mass assignment", "SSRF", "password hashing", "JWT", "secrets", "CORS", "rate limiting". Not general code review, see cq-code-review.
targets: [all]
---
## Backend Security

Checklist pass over an endpoint or feature, mapped to OWASP API Security Top 10 (2023). Fix at the layer that owns the check.

### Workflow
1. List the endpoint's inputs, identities, objects touched, and outbound calls.
2. Walk the table below; mark each risk pass, fail, or n/a.
3. Fix fails. Add a test that proves the denial ([[cq-testing]]).
4. Record accepted risks with an owner.

| Risk | Check | Fix |
|---|---|---|
| API1 BOLA | Does every ID in path, query, or body get an ownership check? | Scope queries by caller (`WHERE id=? AND owner_id=?`); 404 on miss |
| API2 Broken authn | Login, reset, and token endpoints brute-force limited? Tokens verified? | Rate limit, lockout/backoff, MFA, verify signature and claims |
| API3 Property-level authz | Can a client write `role`, `is_admin`, `owner_id`, or read internal fields? | Allowlist input and output schemas ([[be-api-design]]) |
| API4 Resource consumption | Body size, page size, upload size, query cost, third-party spend capped? | Rate limits, size limits, `page_size` max, timeouts |
| API5 Function-level authz | Admin or privileged routes check role, not just login? | Deny by default; central policy per route |
| API6 Sensitive flows | Signup, checkout, coupon, and invite flows abusable at scale? | Per-account and per-IP limits, step-up checks |
| API7 SSRF | Server fetches a user-supplied URL? | See SSRF rule |
| API8 Misconfig | Debug off, headers set, CORS tight, verbose errors off, TLS only? | Hardened defaults per environment |
| API9 Inventory | Old versions, debug and internal routes still exposed? | Maintain a spec; retire or protect old versions |
| API10 Unsafe consumption | Third-party responses trusted? | Validate against a schema; timeouts; no blind redirects |

### Rules
- Passwords: Argon2id (m=19 MiB, t=2, p=1), or scrypt, or bcrypt cost >= 10 (silently truncates past 72 bytes: reject longer input, don't hand-roll a pre-hash). Never roll your own crypto.
- JWT: pin the algorithm, reject `none`, verify `iss`, `aud`, `exp`. Short-lived access token, rotated refresh token, no secrets in the payload. First-party web apps: prefer opaque server-side sessions.
- Secrets: from env or a secret manager, never in repo or logs. Rotate on any leak.
- SSRF: allowlist scheme and host. Resolve DNS, then block private, loopback, link-local, and cloud metadata IPs (`169.254.169.254`) on the resolved address. Do not follow redirects.
- Rate limits and max body size on every public endpoint.
- CORS: explicit origin allowlist; never `*` with credentials.
- Queries parameterized; no string-built SQL, shell, or paths ([[be-data-access]]).

### Not this
- General review of a diff: [[cq-code-review]].
- Logging redaction and audit trails: [[be-observability]].

Sources: OWASP API Security Top 10 2023, OWASP ASVS 5.0, OWASP Password Storage Cheat Sheet.
