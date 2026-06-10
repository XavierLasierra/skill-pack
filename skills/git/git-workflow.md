---
applies_to: all
---
## Git Workflow — Active

### Branch naming
```
feat/short-description
fix/what-is-broken
chore/what-task
release/v1.2.3
```

### PR titles
Same format as commits: `type(scope): subject`. Under 72 chars.

### PR description template
```markdown
## What
One sentence.

## Why
One sentence — the motivation, not the implementation.

## How
Bullet points only if non-obvious.

## Test
What to run or click to verify this works.
```

### Before committing
- No console.log / print statements
- No commented-out code
- No .env or secrets
- Tests pass locally

### Merge strategy
- Squash for feature branches (clean history)
- Merge commit for release branches (preserve history)
- Never force-push to main/master
- On personal/feature branches: use `--force-with-lease` instead of `--force` — fails if upstream has new commits, preventing overwrite of others' work
