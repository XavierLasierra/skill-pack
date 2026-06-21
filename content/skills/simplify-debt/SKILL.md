---
name: simplify-debt
description: Harvest every SHORTCUT(owner) marker in the codebase into a debt ledger, so deliberate simplifications get tracked instead of rotting into "later means never". Use when asked "simplify debt", "what did we defer", "list the shortcuts", "shortcut ledger", or "what did we mark to do later". One-shot report, changes nothing.
targets: [all]
---
## Simplify Debt Ledger

Deliberate simplifications are marked with a `SHORTCUT(owner):` comment naming a ceiling and an upgrade trigger (see the clean-code rule). This collects them into one ledger so a deferral can't quietly become permanent.

### Scan
Grep the repo for the marker, skipping `node_modules`, `.git`, and build output:
```bash
grep -rnE '(#|//) ?SHORTCUT' . --exclude-dir={node_modules,.git,dist,build}
```
Each hit is one ledger row. The marker prefix keeps prose that merely mentions the convention out of the ledger.

### Output
One row per marker, grouped by file:
`<file>:<line>, <what was simplified>. owner: <owner>. ceiling: <the limit>. upgrade: <the trigger>.`

Pull the owner, ceiling, and trigger straight from the comment. Want an owner per row from history instead? add `git blame -L<line>,<line>`.

Flag the rot risk: any marker naming no upgrade trigger gets a `no-trigger` tag — those are the ones that silently rot.

### End with
`<N> markers, <M> with no trigger.`

Nothing found: `No shortcut debt. Clean ledger.`

### Boundaries
Reads and reports only — changes nothing. To persist it, ask and write the ledger to a file (e.g. `SHORTCUT-DEBT.md`). One-shot.
