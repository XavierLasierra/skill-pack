---
targets: [all]
---
## Git Workflow

### Branch naming
```
feat/short-description
fix/what-is-broken
chore/what-task
release/v1.2.3
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
