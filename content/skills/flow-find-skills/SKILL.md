---
name: flow-find-skills
description: Find existing agent skills published on the internet to use as reference when authoring a new skill-pack item. Use when asked "find a skill for X", "is there a skill that does Y", "what's out there for Z", "find references before I write a skill", or when starting a new skill and wanting prior art. Searches the open ecosystem, vets quality, then adapts findings to this pack's conventions.
targets: [all]
---
## Find Skills

Before writing a new skill-pack item, find what already exists in the open ecosystem and learn from it. Good prior art saves reinventing structure, surfaces edge cases, and gives a quality bar to beat. This finds and evaluates external skills as **reference** — it does not install third-party skills into the pack.

### Scope the need
Name the **domain** and the **specific task** in one line before searching, plus which pack category it would land in (`pm-`/`cq-`/`git-`/`flow-`/`fe-`). "React form validation skill" → `fe-` category. "PR description writer" → `git-`. This frames both the search query and where the result fits.

### Search the ecosystem
Work down until you have 2–3 strong references:

1. **Leaderboard** — check https://skills.sh/ for established, high-adoption skills in the domain.
2. **CLI search** — if installed, `npx skills find <query>` lists matches with install counts and sources.
3. **Source repos** — the well-maintained collections to scan or fetch directly:
   - `anthropics/skills`
   - `vercel-labs/skills`
   - `ComposioHQ/awesome-claude-skills`
4. **Web** — broaden with WebSearch when the above are thin; fetch a candidate's `SKILL.md` raw to read the actual procedure.

### Vet quality
Prefer references worth copying from. Rank by:
- **Adoption** — higher install counts / GitHub stars signal a battle-tested skill.
- **Source** — official publishers (Anthropic, Vercel) and active repos over one-off gists.
- **Fit** — the procedure actually matches the task, not just the title.

Read the top candidate's full `SKILL.md` before recommending it — titles lie, procedures don't.

### Present findings
For each reference (2–3 max):
`<name> — <what it does> — <adoption/source signal> — <link>`

Then a one-line read on what to borrow: structure, edge cases it handles, framing — and what to leave (bloat, host-specific assumptions, anything that fights this pack's voice).

### Adapt into the pack
References are raw material, not a drop-in. To turn one into a skill-pack item, follow `AGENTS.md`:
- Rename with the category prefix; `name:` must equal the directory name.
- Add `targets` frontmatter (default `[all]`).
- Rewrite in house voice — dense, imperative, example-driven; strip filler and host-specific lock-in.
- Cross-link related pack items with `[[name]]` instead of duplicating a rule.
- Add a README pack-table row, then `bash scripts/validate.sh` and `bash install.sh`.

### Boundaries
Discovery and evaluation only — never installs an external skill into the pack or runs one. Always cite the source so the adaptation is traceable.
