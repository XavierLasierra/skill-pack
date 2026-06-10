---
applies_to: all
---
## Conventional Commits — Active

Always format commit messages as:

```
type(scope): subject

body (optional)
```

### Types
| Type | When |
|---|---|
| `feat` | new feature |
| `fix` | bug fix |
| `docs` | documentation only |
| `style` | formatting, no logic change |
| `refactor` | restructure without feature/fix |
| `test` | add or fix tests |
| `chore` | build, deps, config |
| `ci` | CI/CD changes |
| `perf` | performance improvement |
| `revert` | revert a prior commit |

### Rules
- Subject: imperative mood, ≤50 chars preferred, hard max 72, no period at end
- Scope: optional, lowercase, describes what area changed (`auth`, `api`, `ui`)
- Breaking change: add `!` after type, e.g. `feat!: remove legacy endpoint`
- Body: bullet list only — one short line per point, no prose paragraphs
- Body: explain WHY not WHAT, wrap at 72 chars, omit if subject is self-explanatory
- Body mandatory for: breaking changes, security fixes, data migrations, reversions — optional for everything else
- Task identifier: if the task has a ticket ID (Jira, Linear, GitHub issue), prefix the subject inline — `feat:P-123 add login` / `fix:PROJ-456 handle null` (no space between colon and ID)

### Never write
- First-person pronouns ("I added…", "we fixed…")
- Narration ("This commit does X", "Changed X to Y")
- AI attribution anywhere — subject, body, or trailers ("Generated with Claude Code", "Co-Authored-By: Claude", "AI-assisted")
- Filler subjects: "Updated some files", "Fix bug", "WIP", "Changes", "Misc"

### Examples
```
feat(auth): add OAuth2 login flow
fix(api): handle null response from payment provider
chore: upgrade pydantic to v2
feat!: replace XML config with YAML — breaks existing configs
feat:P-123 add OAuth2 login flow
fix:PROJ-456 handle null response from payment provider
```
