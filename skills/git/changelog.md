---
applies_to: all
---
## Git Changelog Tag — Active

When asked to tag a release or create a changelog, generate an annotated git tag whose message is a structured changelog derived from commits since the previous tag.

### Steps

1. **Find the previous tag**
   ```bash
   git describe --tags --abbrev=0
   ```
   If no prior tag exists, use the first commit: `git rev-list --max-parents=0 HEAD`

2. **Collect commits since that tag** (no merges, subject line only)
   ```bash
   git log <prev-tag>..HEAD --no-merges --format="%s"
   ```

3. **Classify each commit** by its conventional-commit prefix:
   - `feat`, `feat!` → **Features**
   - `fix` → **Bug Fixes**
   - `perf` → **Improvements**
   - `feat!` or any commit containing `BREAKING CHANGE` → also add to **Breaking Changes**
   - Everything else (`chore`, `docs`, `refactor`, `test`, `ci`, `style`) → omit from changelog

4. **Extract ticket IDs** from the subject and append in parentheses:
   - Jira: `[A-Z]{2,}-\d+` (e.g., `PROJ-123`, `SP-42`)
   - GitHub issue: `#\d+`
   - Linear: same pattern as Jira

5. **Format the changelog message**
   ```
   v1.2.3 — YYYY-MM-DD

   Features
   - add OAuth2 login flow (P-123)
   - support dark mode theming

   Bug Fixes
   - handle null response from payment provider (PROJ-456)
   - fix race condition in session refresh (#88)

   Breaking Changes
   - replace XML config with YAML — existing configs must be migrated
   ```
   Omit any section that has no entries.

6. **Deliver the result** based on what the user asked:

   **Tag me** — user asked to create the tag (e.g. "tag v1.2.3", "create a release tag"):
   Confirm the changelog with the user, then run:
   ```bash
   git tag -a v1.2.3 -m "$(cat <<'EOF'
   v1.2.3 — 2026-01-15

   Features
   - add OAuth2 login flow (P-123)

   Bug Fixes
   - fix null crash on empty cart (PROJ-456)
   EOF
   )"
   ```

   **Message only** — user asked for the text (e.g. "give me the changelog", "what changed since last tag", "generate the tag message"):
   Print the formatted message as a code block. User runs the tag command themselves.

   When intent is ambiguous, default to **message only** and ask if they want you to tag.

### Rules
- Bullet text: lowercase, imperative mood, strip the commit-type prefix (`feat: ` → bullet text starts after the colon)
- Ticket IDs at the end of the bullet in `(ID)` — if multiple, space-separate: `(P-123 #45)`
- Date: today's date in `YYYY-MM-DD`
- If no classifiable commits exist, ask the user whether to tag anyway with an empty changelog
- Never push the tag without explicit user confirmation — `git push origin v1.2.3` is irreversible on shared remotes
