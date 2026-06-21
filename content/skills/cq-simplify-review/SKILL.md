---
name: cq-simplify-review
description: Review a diff or files for over-engineering only — what to delete, not what's broken. Finds reinvented stdlib, needless dependencies, speculative abstractions, dead flexibility. One line per finding, ends with a net line count. Use when asked "review for over-engineering", "what can we delete", "is this over-engineered", "simplify review". Complements correctness review (code-review) and applies nothing (use /simplify to apply).
targets: [all]
---
## Simplify Review

Review a diff for unnecessary complexity only. The best outcome is the diff getting shorter. Lists findings — applies nothing (route fixes to `/simplify`). Correctness, security, and performance are out of scope — route those to `code-review`.

### Format
`L<line>: <tag> <what>. <replacement>.` — or `<file>:L<line>: …` for multi-file diffs.

Tags:
- `delete:` dead code, unused flexibility, speculative feature. Replacement: nothing.
- `stdlib:` hand-rolled thing the standard library ships. Name the function.
- `native:` dependency or code doing what the platform already does. Name the feature.
- `yagni:` abstraction with one implementation, config nobody sets, layer with one caller.
- `shrink:` same logic, fewer lines. Show the shorter form.

### Examples
```
L12-38: stdlib: 27-line email validator. "@" in addr is enough — real check is the confirmation mail.
L4:     native: moment.js for one format call. Intl.DateTimeFormat, 0 deps.
repo.py:L88: yagni: AbstractRepository with one implementation. Inline until a second exists.
L52-71: delete: retry wrapper around an idempotent local call. Nothing replaces it.
L30-44: shrink: manual loop builds dict. dict(zip(keys, values)), 1 line.
```

### Drop
- "have you considered…", "might be more complex than necessary…", hedging
- Restating what the line does
- Flagging a single smoke test or `assert`-based self-check — that's the minimum, not bloat

### End with
`net: -<N> lines possible.`

If nothing to cut: write `Lean already. Ship.` Nothing else.
