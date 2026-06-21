# skill-pack

Behavioral skills, rules, agents, and commands for **Claude Code** and the **Antigravity CLI (`agy`)** — installed natively into each tool.

One source of truth (`content/`). The installer emits each piece into the native home each tool expects: rules into the global context file, skills as real `SKILL.md` skills, subagents into the agents dir, slash commands as commands. No drift, no copies to maintain.

---

## Install

```bash
git clone https://github.com/XavierLasierra/skill-pack
cd skill-pack
bash install.sh
```

Auto-detects Claude Code and Antigravity. Re-running **syncs**: updates changed items, removes deleted ones, adds new ones.

```bash
bash install.sh --tools claude        # one tool only
bash install.sh --tools antigravity
bash uninstall.sh                      # remove everything it added
```

---

## What's in the pack

Items are grouped by category prefix: **`pm-`** (product planning), **`cq-`** (code quality), **`git-`** (version control & release), **`flow-`** (workflow & meta). Agents use the **`sp-`** namespace; hooks keep fixed names.

| Type | Item | Claude | Antigravity |
|---|---|:--:|:--:|
| **rule** | `cq-clean-code` | ✅ | ✅ |
| **rule** | `git-conventional-commits` | ✅ | ✅ |
| **rule** | `git-workflow` | ✅ | ✅ |
| **rule** | `flow-model-usage` (Claude model tiers) | ✅ | — |
| **rule** | `flow-concise` (full spec, switchable) | ✅ | — |
| **rule** | `flow-concise-base` (always-on, static) | — | ✅ |
| **skill** | `cq-code-review` | ✅ | ✅ |
| **skill** | `cq-simplify-review` (over-engineering only) | ✅ | ✅ |
| **skill** | `cq-simplify-debt` (shortcut ledger) | ✅ | ✅ |
| **skill** | `git-changelog` | ✅ | ✅ |
| **skill** | `git-pull-request` | ✅ | ✅ |
| **skill** | `pm-product-brief` (kickoff one-pager) | ✅ | ✅ |
| **skill** | `pm-product-spec` (PRD) | ✅ | ✅ |
| **skill** | `pm-roadmap` (Now/Next/Later) | ✅ | ✅ |
| **skill** | `pm-backlog` (epics → stories) | ✅ | ✅ |
| **skill** | `pm-work-ticket` (tracker-agnostic ticket) | ✅ | ✅ |
| **command** | `/flow-handoff` | ✅ | ✅ |
| **command** | `/flow-concise` | ✅ | — |
| **agent** | `sp-reviewer`, `sp-investigator`, `sp-builder` | ✅ | ✅ |
| **hook** | concise reinjection + statusline | ✅ | — |

**rule** = always-on behavioral default (injected into the global context file).
**skill** = on-demand procedure the model activates by description (native `SKILL.md`).
**command** = user-invoked `/slash` (Antigravity auto-converts commands to slash-skills).
**agent** = subagent for bounded tasks.

---

## Where each piece lands

| Type | Claude Code | Antigravity CLI |
|---|---|---|
| rules | `~/.claude/CLAUDE.md` (marker blocks) | `~/.gemini/AGENTS.md` (marker blocks) |
| skills | `~/.claude/skills/<n>/SKILL.md` | plugin `sp` → `skills/<n>/SKILL.md` |
| agents | `~/.claude/agents/<n>.md` | plugin `sp` → `agents/<n>.md` |
| commands | `~/.claude/commands/<n>.md` | plugin `sp` → `commands/` (→ skills) |
| hooks | `~/.claude/settings.json` + `~/.skill-pack/hooks/` | — |

On Antigravity everything except rules is packaged as a native plugin named **`sp`**, registered with `agy plugin install`. Check it with `agy plugin list`.

### Tool-specific items

- **`flow-concise` vs `flow-concise-base`** — both tools are concise by default. Claude gets the full `flow-concise` rule (lite/full/ultra levels + examples) plus live switching via `/flow-concise` and a per-turn reinjection hook. Antigravity gets `flow-concise-base` (a compact always-on rule in `AGENTS.md`) — concise by default but no live switching, because agy's hooks only fire on tool events (`PreToolUse`/`PostToolUse`/`Stop`) with no per-turn reinjection equivalent.
- **`flow-model-usage`** — describes Claude's Haiku/Opus/Sonnet routing; irrelevant to Antigravity's Gemini models.

---

## Concise mode

Both tools default to concise output.

**Claude Code** — full system with live intensity switching:

```
/flow-concise lite    # drop filler only, keep sentence structure
/flow-concise full    # drop articles, filler, pleasantries, hedging (default)
/flow-concise ultra   # maximum compression, noun phrases and imperatives
/flow-concise off     # disable
/flow-concise         # show current level
```

Active level persists in `~/.skill-pack/concise-level`, is reinjected every turn by a hook, and shows in the status bar.

**Antigravity** — the `concise-base` rule in `~/.gemini/AGENTS.md` keeps output concise by default. No live switching: agy has no per-turn hook, so the level is fixed (equivalent to Claude's `full`).

## Agents

| Agent | When to use | Model (Claude) |
|---|---|---|
| `sp-investigator` | Find where code is defined, list callers, map a directory | Haiku |
| `sp-builder` | Surgical 1–2 file edits: typos, renames, single-function rewrites | Haiku |
| `sp-reviewer` | Review a diff, PR, or file for bugs and risks | Sonnet |

Claude keeps the `model`/`tools` frontmatter; the Antigravity plugin strips Claude-specific keys (Antigravity assigns its own model/tools).

---

## Source layout

```
content/
  rules/      <cat>-<name>.md          → CLAUDE.md / AGENTS.md blocks
  skills/     <cat>-<name>/SKILL.md    → native skills
  commands/   <cat>-<name>.md          → slash commands
  agents/     sp-<name>.md             → subagents
  hooks/      *.sh                     → Claude hooks (fixed names)
```

Files are flat within each type; the **category prefix** (`pm-`/`cq-`/`git-`/`flow-`) groups them — it survives into the destination name, so `/flow-handoff` autocompletes alongside other `flow-` commands. See `AGENTS.md` for the full convention.

Every file carries a `targets` frontmatter key controlling which tools receive it:

```yaml
---
targets: [all]          # both tools (default if omitted)
---
```
```yaml
---
targets: [claude]       # Claude only
---
```

Skills additionally require `name` and `description` (both tools trigger-match on these). Add a file, run `bash install.sh`, and it's picked up automatically.

---

## How it works

- **Rules** are wrapped in markers in the global context file so install/uninstall touch nothing else:
  ```
  # >>> skill-pack:rules/cq-clean-code
  …
  # <<< skill-pack:rules/cq-clean-code
  ```
  Re-running syncs: **Updated** (content changed), **Removed stale** (deleted or no longer targets the tool), **Installed** (new).
- **Skills / agents / commands** are written into each tool's native directory (Antigravity via its plugin). They sync by content diff.
- No API key, no network, no server — just files each tool already reads.

---

## Contributing

Enable the pre-commit hook once per clone (native git, no dependencies):

```bash
git config core.hooksPath .githooks
```

On every commit it runs `scripts/validate.sh` — checks each `content/` item has the required frontmatter (`name`, `description`, valid `targets`) and that the README pack table is in sync — plus `shellcheck` on the shell scripts if installed (`brew install shellcheck`). Run it any time with `bash scripts/validate.sh`.
