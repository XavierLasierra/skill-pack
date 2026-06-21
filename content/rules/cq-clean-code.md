---
targets: [all]
---
## Clean Code

### Before writing code
The best code is the code never written. Stop at the first rung that holds:
1. Does this need to be built at all? (YAGNI)
2. Does the standard library already do it? Use it.
3. Does a native platform feature cover it? Use it.
4. Does an already-installed dependency solve it? Use it.
5. Can it be one line? Make it one line.
6. Only then: write the minimum code that works.

Never lazy about: input validation at trust boundaries, error handling that prevents data loss, security, accessibility, anything explicitly requested.

### Write
- Names that explain intent — no abbreviations except universally understood ones: loop counters (i, j, k), counts (n), errors (err), context (ctx)
- Functions that do one thing
- The simplest solution that works — no premature abstraction
- Error handling only at system boundaries (user input, external APIs, file I/O)

### Don't write
- Comments that explain WHAT — the code does that
- Comments referencing the current task, PR, or caller ("added for X flow", "handles Y case")
- Defensive null checks for things that can't be null given the code above
- Feature flags, backwards-compat shims, or `_old`/`_v2` variants
- Abstractions for hypothetical future requirements — three similar lines beats a premature helper
- Nested ternaries or chained optional access deeper than two levels — split into named variables
- Nested `if` blocks where an early `return` would flatten the code

### Deliberate shortcuts
A deliberate simplification with a known ceiling is the one comment exception to "no WHAT comments". Mark it so the deferral can't rot into permanent:
`SHORTCUT(owner): <what's simplified> — ceiling: <the limit>; upgrade: <the trigger to revisit>`
Name both the ceiling (global lock, O(n²) scan, naive heuristic) and the trigger. No ceiling means it's not a shortcut, it's a bug. Harvest them with `/cq-simplify-debt`.

### Defaults
- No docstrings on obvious functions
- No `TODO` without owner and date — format: `TODO(owner): description — YYYY-MM-DD`
- No `print`/`console.log` left in committed code
- No magic numbers — name them as constants if they appear more than once

### On changes
Fix the bug. Don't refactor the surrounding code unless it's blocking the fix.
Don't clean up unrelated areas in the same commit.
