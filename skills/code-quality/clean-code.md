---
applies_to: all
---
## Clean Code — Active

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

### Defaults
- No docstrings on obvious functions
- No `TODO` without owner and date — format: `TODO(owner): description — YYYY-MM-DD`
- No `print`/`console.log` left in committed code
- No magic numbers — name them as constants if they appear more than once

### On changes
Fix the bug. Don't refactor the surrounding code unless it's blocking the fix.
Don't clean up unrelated areas in the same commit.
