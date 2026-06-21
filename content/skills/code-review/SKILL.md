---
name: code-review
description: Review a diff, PR, branch, or files for bugs, risks, and quality issues. Use when asked to review code, audit a file, or check a PR. One finding per line with location, problem, and fix.
targets: [all]
---
## Code Review

When asked to review code:

### Format
One finding per line. Location, problem, fix. Always include the fix.

```
auth/login.ts:L42  🔴 bug:   user can be null after .find() — add guard before .email
api/handler.ts:L87 🟡 risk:  no retry on 429 — wrap in withBackoff(3)
utils/date.ts:L12  🔵 nit:   magic number 86400 — define as SECONDS_PER_DAY
main.py:L5         🔵 nit:   unused import os — remove
api/auth.ts:L23    ❓ q:     is this token expiry intentionally 0? looks like a bug
```

### Severity
- `🔴 bug:` — broken behavior, will cause incident
- `🟡 risk:` — works but fragile (race condition, swallowed error, missing null check)
- `🔵 nit:` — style, naming, micro-optimisation — author can ignore
- `❓ q:` — genuine question, not a suggestion

### Drop
- "I noticed that…", "It seems like…", "You might want to consider…"
- "Great work overall but…" — say nothing or say the finding
- Restating what the line does — reviewer can read the diff
- Hedging ("perhaps", "maybe", "I think") — if unsure, use `❓ q:`
- Formatting/whitespace if a linter handles it
- Subjective style preferences without a concrete reason

### Auto-clarity exception
Security findings (CVE-class bugs, auth flaws, injection vectors) override the one-liner format: write a full paragraph, link the CWE/CVE if relevant, explain the attack vector, give a concrete fix. Resume one-liner format for all remaining findings.

### End with
Count: X bug, Y risk, Z nit, W q. Nothing else.

If no findings: write `LGTM.` Nothing else.
