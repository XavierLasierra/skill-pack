---
name: git-commit
description: Turn working-tree changes into clean, atomic commits. Use when asked "commit this", "commit my changes", "split into commits", or "write a commit message". Not PR title/description, see git-pull-request.
targets: [all]
---
## Git Commit

Turn a dirty working tree into atomic, reviewable commits. Message format lives in [[git-conventional-commits]], branch rules in [[git-workflow]] — follow both, don't restate here.

### 1. Check the branch
`git branch --show-current`. On `main`/`master`: create a branch first (`git switch -c feat/short-description`). Never commit to main directly.

### 2. Inspect everything
```
git status --short
git diff              # unstaged
git diff --staged     # already staged
```
Read the full diff. Know what each hunk does before staging it. Check untracked files too — `git diff` does not show them.

### 3. Exclude what must not ship
Never stage:
- Secrets: `.env*`, `*.pem`, keys, tokens, credentials in config or fixtures
- Build artifacts and deps: `dist/`, `build/`, `node_modules/`, `__pycache__/`, `.DS_Store`
- Debug leftovers: `console.log`/`print`, commented-out code

Found one? Add it to `.gitignore` (separate `chore:` commit). A secret already staged or committed counts as leaked — rotate it, don't just delete it.

### 4. Split into atomic commits
One logical change per commit. Each commit builds and passes tests on its own. Split when the diff mixes: feature + refactor, fix + formatting, unrelated files, deps bump + code.

Stage by path — works everywhere:
```
git add src/auth/login.ts src/auth/login.test.ts
```
Same file holds two changes? `git add -p` is interactive and may be unavailable to agents. Use a patch instead:
```
git diff src/api.ts > /tmp/api.patch   # edit the patch to keep only wanted hunks
git apply --cached --recount /tmp/api.patch   # --recount fixes hunk headers after edits
```
Verify the split: `git diff --staged` shows only this commit's change.

### 5. Verify before committing
Run the project's tests and linters on the staged state. Fix failures first.

Hook failing? Fix the cause. Never `--no-verify`.

### 6. Commit
Message per [[git-conventional-commits]]. Subject says what the change does; body (only if needed) says why.
```
git commit -m "fix(auth): reject expired refresh tokens"
```
Repeat 4-6 for each remaining change. End with `git status` clean and `git log --oneline -n <count>` as a sanity check.

### History rules
- Pushed commits are immutable: no `--amend`, `rebase`, or `reset` on them. Add a new commit or `git revert <sha>`.
- Unpushed fix to the last commit: `git commit --amend` is fine.
- Forgot a file in an unpushed commit: stage it, `git commit --amend --no-edit`.

### Not this
PR title and description: use [[git-pull-request]].
