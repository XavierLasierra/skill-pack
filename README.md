# skill-pack

Behavioral skills, rules, agents, and commands for **Claude Code**, the **Antigravity CLI (`agy`)**, and **opencode** — installed natively into each tool.

One source of truth (`content/`). The installer emits each piece into the native home each tool expects: rules into the global context file, skills as real `SKILL.md` skills, subagents into the agents dir, slash commands as commands. No drift, no copies to maintain.

---

## Install

```bash
git clone https://github.com/XavierLasierra/skill-pack
cd skill-pack
bash install.sh
```

Auto-detects Claude Code, Antigravity, and opencode. Re-running **syncs**: updates changed items, removes deleted ones, adds new ones.

```bash
bash install.sh --tools claude        # one tool only
bash install.sh --tools antigravity
bash install.sh --tools opencode
bash uninstall.sh                      # remove everything it added
```

---

## What's in the pack

Items are grouped by category prefix: **`pm-`** (product planning), **`cq-`** (code quality), **`git-`** (version control & release), **`flow-`** (workflow & meta), **`fe-`** (frontend). Agents use the **`sp-`** namespace; hooks keep fixed names.

| Type | Item | Claude | Antigravity | opencode |
|---|---|:--:|:--:|:--:|
| **rule** | `cq-clean-code` | ✅ | ✅ | ✅ |
| **rule** | `git-conventional-commits` | ✅ | ✅ | ✅ |
| **rule** | `git-workflow` | ✅ | ✅ | ✅ |
| **rule** | `flow-model-usage-claude` (Claude model tiers) | ✅ | — | — |
| **rule** | `flow-model-usage-agy` (agy model-fit warning) | — | ✅ | — |
| **rule** | `flow-concise` (full spec, switchable) | ✅ | — | — |
| **rule** | `flow-concise-base` (always-on, static) | — | ✅ | ✅ |
| **rule** | `fe-aesthetic` (anti-slop UI nudge) | ✅ | ✅ | ✅ |
| **skill** | `cq-code-review` | ✅ | ✅ | ✅ |
| **skill** | `cq-simplify-review` (over-engineering only) | ✅ | ✅ | ✅ |
| **skill** | `cq-simplify-debt` (shortcut ledger) | ✅ | ✅ | ✅ |
| **skill** | `git-changelog` | ✅ | ✅ | ✅ |
| **skill** | `git-pull-request` | ✅ | ✅ | ✅ |
| **skill** | `pm-product-brief` (kickoff one-pager) | ✅ | ✅ | ✅ |
| **skill** | `pm-product-spec` (PRD) | ✅ | ✅ | ✅ |
| **skill** | `pm-roadmap` (Now/Next/Later) | ✅ | ✅ | ✅ |
| **skill** | `pm-backlog` (epics → stories) | ✅ | ✅ | ✅ |
| **skill** | `pm-work-ticket` (tracker-agnostic ticket) | ✅ | ✅ | ✅ |
| **skill** | `fe-react-component` (clean React components) | ✅ | ✅ | ✅ |
| **skill** | `fe-react-effects` (state/effect discipline) | ✅ | ✅ | ✅ |
| **skill** | `fe-react-native-component` (RN-specific deltas) | ✅ | ✅ | ✅ |
| **skill** | `fe-react-data-fetching` (TanStack Query / server state) | ✅ | ✅ | ✅ |
| **skill** | `fe-react-testing` (React Testing Library) | ✅ | ✅ | ✅ |
| **skill** | `fe-a11y` (accessibility, web + RN) | ✅ | ✅ | ✅ |
| **skill** | `fe-react-performance` (measure-first debugging) | ✅ | ✅ | ✅ |
| **skill** | `fe-react-state-management` (state decision guide) | ✅ | ✅ | ✅ |
| **skill** | `fe-react-forms` (React Hook Form + zod) | ✅ | ✅ | ✅ |
| **skill** | `fe-responsive` (mobile-first responsive layout) | ✅ | ✅ | ✅ |
| **skill** | `fe-touch` (touch/mobile/tablet interaction) | ✅ | ✅ | ✅ |
| **skill** | `fe-ui-states` (loading/empty/error/success UX) | ✅ | ✅ | ✅ |
| **skill** | `fe-ui-foundations` (spacing/type/tokens/dark mode) | ✅ | ✅ | ✅ |
| **command** | `/flow-handoff` | ✅ | ✅ | ✅ |
| **command** | `/flow-concise` | ✅ | — | — |
| **agent** | `sp-reviewer`, `sp-investigator`, `sp-builder` | ✅ | ✅ | ✅ |
| **hook** | concise reinjection + statusline | ✅ | — | — |

**rule** = always-on behavioral default (injected into the global context file).
**skill** = on-demand procedure the model activates by description (native `SKILL.md`).
**command** = user-invoked `/slash` (Antigravity auto-converts commands to slash-skills; opencode reads command markdown directly).
**agent** = subagent for bounded tasks.

---

## Where each piece lands

| Type | Claude Code | Antigravity CLI | opencode |
|---|---|---|---|
| rules | `~/.claude/CLAUDE.md` (marker blocks) | `~/.gemini/AGENTS.md` (marker blocks) | `~/.config/opencode/AGENTS.md` (marker blocks) |
| skills | `~/.claude/skills/<n>/SKILL.md` | plugin `sp` → `skills/<n>/SKILL.md` | `~/.config/opencode/skills/<n>/SKILL.md` |
| agents | `~/.claude/agents/<n>.md` | plugin `sp` → `agents/<n>.md` | `~/.config/opencode/agents/<n>.md` |
| commands | `~/.claude/commands/<n>.md` | plugin `sp` → `commands/` (→ skills) | `~/.config/opencode/commands/<n>.md` |
| hooks | `~/.claude/settings.json` + `~/.skill-pack/hooks/` | — | — |

On Antigravity everything except rules is packaged as a native plugin named **`sp`**, registered with `agy plugin install`. Check it with `agy plugin list`. On opencode each piece is written directly into the native `~/.config/opencode/` directories — no plugin wrapper — and skills/agents/commands are picked up on next launch.

### Tool-specific items

- **`flow-concise` vs `flow-concise-base`** — all three tools are concise by default. Claude gets the full `flow-concise` rule (lite/full/ultra levels + examples) plus live switching via `/flow-concise` and a per-turn reinjection hook. Antigravity and opencode get `flow-concise-base` (a compact always-on rule in `AGENTS.md`) — concise by default but no live switching, because neither has a per-turn reinjection hook equivalent to Claude's `UserPromptSubmit`.
- **`flow-model-usage-claude` vs `flow-model-usage-agy`** — Claude gets routing guidance (Haiku/Opus/Sonnet) the agent can act on by picking subagent models. agy can't switch models mid-session (`--model` is fixed at launch), so the agent instead gets `flow-model-usage-agy`: it knows its current tier and warns you to relaunch with a stronger model when a task is clearly too heavy for a light one. See "Choosing an agy model" below. opencode picks its own model per session/agent and gets neither rule.
- **opencode agents** — opencode derives the agent name from the filename and uses `mode: subagent` frontmatter, so the installer drops Claude's `name`/`tools`/`model` keys and injects `mode: subagent`. opencode assigns the agent its own model and tool access. opencode also reads `~/.claude/CLAUDE.md` and `~/.claude/skills/` natively, so if you install for both Claude and opencode the same skills may surface from two homes — harmless (matched by name), but expected.

### Choosing an agy model

`agy --model` sets the model for the whole session (run `agy models` for the list). Pick at launch by the work; the `flow-model-usage-agy` rule nudges you if you started light for a heavy task.

| Work | Launch with |
|---|---|
| Quick edits, search, mechanical changes | `agy --model 'Gemini 3.5 Flash (Low/Medium)'` |
| Implementation, multi-step tasks | `agy --model 'Gemini 3.5 Flash (High)'` or `'Gemini 3.1 Pro (Low)'` |
| Architecture, planning, deep review | `agy --model 'Gemini 3.1 Pro (High)'` or `'Claude Opus 4.6 (Thinking)'` |

Switching mid-session means relaunching — add `--continue` to keep the conversation.

---

## Concise mode

All three tools default to concise output.

**Claude Code** — full system with live intensity switching:

```
/flow-concise lite    # drop filler only, keep sentence structure
/flow-concise full    # drop articles, filler, pleasantries, hedging (default)
/flow-concise ultra   # maximum compression, noun phrases and imperatives
/flow-concise off     # disable
/flow-concise         # show current level
```

Active level persists in `~/.skill-pack/concise-level`, is reinjected every turn by a hook, and shows in the status bar.

**Antigravity / opencode** — the `flow-concise-base` rule in `AGENTS.md` keeps output concise by default. No live switching: neither has a per-turn hook, so the level is fixed (equivalent to Claude's `full`).

## Agents

| Agent | When to use | Model (Claude) |
|---|---|---|
| `sp-investigator` | Find where code is defined, list callers, map a directory | Haiku |
| `sp-builder` | Surgical 1–2 file edits: typos, renames, single-function rewrites | Haiku |
| `sp-reviewer` | Review a diff, PR, or file for bugs and risks | Sonnet |

Claude keeps the `model`/`tools` frontmatter; the Antigravity plugin and opencode strip Claude-specific keys (they assign their own model/tools — opencode additionally gets `mode: subagent`).

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
targets: [all]          # all tools (default if omitted)
---
```
```yaml
---
targets: [claude]       # Claude only — also: antigravity, opencode
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
- **Skills / agents / commands** are written into each tool's native directory (Antigravity via its plugin; Claude and opencode directly). They sync by content diff.
- No API key, no network, no server — just files each tool already reads.

---

## Contributing

Enable the pre-commit hook once per clone (native git, no dependencies):

```bash
git config core.hooksPath .githooks
```

On every commit it runs `scripts/validate.sh` — checks each `content/` item has the required frontmatter (`name`, `description`, valid `targets`) and that the README pack table is in sync — plus `shellcheck` on the shell scripts if installed (`brew install shellcheck`). Run it any time with `bash scripts/validate.sh`.
