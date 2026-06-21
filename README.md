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

| Type | Item | Claude | Antigravity |
|---|---|:--:|:--:|
| **rule** | `clean-code` | ✅ | ✅ |
| **rule** | `conventional-commits` | ✅ | ✅ |
| **rule** | `git-workflow` | ✅ | ✅ |
| **rule** | `model-usage` (Claude model tiers) | ✅ | — |
| **rule** | `concise` (full spec, switchable) | ✅ | — |
| **rule** | `concise-base` (always-on, static) | — | ✅ |
| **skill** | `code-review` | ✅ | ✅ |
| **skill** | `simplify-review` (over-engineering only) | ✅ | ✅ |
| **skill** | `simplify-debt` (shortcut ledger) | ✅ | ✅ |
| **skill** | `changelog` | ✅ | ✅ |
| **skill** | `pull-request` | ✅ | ✅ |
| **command** | `/handoff` | ✅ | ✅ |
| **command** | `/concise` | ✅ | — |
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

- **`concise` vs `concise-base`** — both tools are concise by default. Claude gets the full `concise` rule (lite/full/ultra levels + examples) plus live switching via `/concise` and a per-turn reinjection hook. Antigravity gets `concise-base` (a compact always-on rule in `AGENTS.md`) — concise by default but no live switching, because agy's hooks only fire on tool events (`PreToolUse`/`PostToolUse`/`Stop`) with no per-turn reinjection equivalent.
- **`model-usage`** — describes Claude's Haiku/Opus/Sonnet routing; irrelevant to Antigravity's Gemini models.

---

## Concise mode

Both tools default to concise output.

**Claude Code** — full system with live intensity switching:

```
/concise lite    # drop filler only, keep sentence structure
/concise full    # drop articles, filler, pleasantries, hedging (default)
/concise ultra   # maximum compression, noun phrases and imperatives
/concise off     # disable
/concise         # show current level
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
  rules/      <name>.md          → CLAUDE.md / AGENTS.md blocks
  skills/     <name>/SKILL.md    → native skills
  commands/   <name>.md          → slash commands
  agents/     <name>.md          → subagents
  hooks/      *.sh               → Claude hooks
```

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
  # >>> skill-pack:rules/clean-code
  …
  # <<< skill-pack:rules/clean-code
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
