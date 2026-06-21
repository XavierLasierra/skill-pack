# AGENTS.md — building skill-pack content

Guide for adding or changing content in this repo. Read before creating a new rule, skill, command, agent, or hook.

## What this repo is

One source of truth — `content/` — installed natively into **Claude Code** and the **Antigravity CLI (`agy`)** by `install.sh`. No copies, no drift. Each piece is emitted into the home each tool expects (rules → global context file, skills → native `SKILL.md`, etc.).

## Layout (do not change the top level)

```
content/
  rules/      <cat>-<name>.md       → CLAUDE.md / AGENTS.md marker blocks
  skills/     <cat>-<name>/SKILL.md → native skills
  commands/   <cat>-<name>.md       → /slash commands
  agents/     sp-<name>.md          → subagents
  hooks/      *.sh                  → Claude hooks (fixed names)
```

The top-level split is by **type**. The installer and `scripts/validate.sh` glob each type flatly (`content/skills/*/`, `content/rules/*.md`, …). **Keep it flat — no subfolders.** All destinations are flat, global namespaces, so names must be unique across the whole pack.

## Category prefix convention

Group by a category **prefix** on the name (not subfolders — the prefix is the only thing that survives to the destination, where you actually invoke things):

| Prefix | Category | Examples |
|---|---|---|
| `pm-` | product planning | `pm-product-brief`, `pm-roadmap`, `pm-work-ticket` |
| `cq-` | code quality | `cq-code-review`, `cq-simplify-debt`, `cq-clean-code` |
| `git-` | version control & release | `git-changelog`, `git-pull-request`, `git-workflow` |
| `flow-` | workflow & meta | `flow-handoff`, `flow-concise`, `flow-model-usage` |
| `fe-` | frontend | `fe-react-component` |

Exceptions: **agents** use the `sp-` (skill-pack) namespace; **hooks** keep fixed names (`session-start`, `user-prompt-submit`, `statusline`) — they're referenced by name in `install.sh`/`uninstall.sh`.

Adding a new category? Pick a short lowercase code, add a row here and to the README table, and apply it consistently.

Names are `kebab-case`. The prefix becomes part of the user-facing name: a command `flow-handoff.md` is invoked as `/flow-handoff` and autocompletes next to other `flow-` commands.

**Tool-specific items carry a `-claude` / `-agy` suffix.** When a rule (or skill) exists in two tool-targeted variants because the behavior differs per tool, name them `<cat>-<name>-claude` and `<cat>-<name>-agy` with matching `targets`. Example: `flow-model-usage-claude` (Claude routing) and `flow-model-usage-agy` (agy model-fit warning). A single item targeting both tools needs no suffix.

## Frontmatter

Every file carries `targets` controlling which tools receive it:

```yaml
---
targets: [all]          # both tools (also the default if the key is omitted)
targets: [claude]       # Claude only
targets: [antigravity]  # Antigravity only
---
```

Valid values: `all`, `claude`, `antigravity`. Validation rejects anything else.

- **Skills** (`SKILL.md`) additionally require `name` and `description`. **`name` must equal the directory name** (including prefix) — both tools trigger-match on it.
- **Agents** require `name` and `description`; may keep Claude-only `model`/`tools` keys (the Antigravity build strips them).
- **Commands** require `description`.
- **Rules** need only `targets`.

## Cross-references

When one piece references another, use the **full prefixed name**:

- Wiki-links between skills: `[[pm-product-spec]]`, not `[[product-spec]]`.
- Slash commands in prose: `` `/cq-simplify-debt` ``, `` `/flow-concise` ``.

After renaming anything, grep for stale references: `grep -rn '\[\[' content/` and `grep -rnoE '/[a-z-]+' content/`.

## Adding a new piece

1. Create the file/dir under the right type, with the category prefix.
2. Add `targets` (+ `name`/`description` where required). For skills, set `name:` to the dir name.
3. Add a row to the **README pack table** — `validate.sh` fails if any item's basename is missing from it.
4. Run `bash scripts/validate.sh`.
5. Run `bash install.sh` to sync into your tools.

## Renaming / removing — uninstall first

Skills/commands/agents are keyed by name at the destination. Re-installing after a rename self-heals (prune removes stale items), **but to be safe — especially for the Antigravity plugin — run `bash uninstall.sh` before renaming, then `bash install.sh` after.** This guarantees no orphaned duplicates in `~/.claude/` or the `sp` plugin.

## Validation

Pre-commit hook (enable once per clone):

```bash
git config core.hooksPath .githooks
```

Runs `scripts/validate.sh` on every commit — checks required frontmatter, valid `targets`, and README sync — plus `shellcheck` on shell scripts if installed. Run it anytime with `bash scripts/validate.sh`.

## Writing style for content

- Match the existing voice: dense, imperative, example-driven. No filler.
- Rules are always-on defaults — keep them short; every line costs context budget on every turn.
- Skills are on-demand procedures — the `description` is the trigger, so make it match how a user would ask.
- Don't duplicate a rule inside a skill; cross-link with `[[name]]` instead.
- Keep `concise-level` and other internal state-file paths intact when editing hooks — they are not user-facing commands.
