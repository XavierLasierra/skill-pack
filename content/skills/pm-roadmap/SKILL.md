---
name: pm-roadmap
description: Build a product roadmap. Use when asked to create, sequence, or prioritize a roadmap — themes and outcomes over time, not a dated feature list. Supports Now/Next/Later or quarterly. Text only.
targets: [all]
---
## Roadmap

Communicates direction and intent, not delivery dates. Organized by outcomes and themes so it survives reality. A roadmap is not a backlog and not a Gantt chart. Output text only.

### Pick a horizon model
- **Now / Next / Later** — default. Honest about decreasing certainty over time. Use unless the user asks for dates.
- **Quarterly (Q1–Q4)** — only when the user needs calendar alignment. Later quarters stay deliberately vague.

Ask which the user wants if unclear; default to Now/Next/Later.

### Template (Now/Next/Later)

```markdown
# Roadmap: <product> — as of <YYYY-MM-DD>

**North star:** <the one outcome everything ladders up to>

## Now  (committed, in progress)
### <Theme> — *why it matters: <outcome>*
- <initiative> → <expected outcome / metric>
- <initiative>

## Next  (planned, next cycle)
### <Theme>
- <initiative> → <outcome>  ·  *depends on: <x>*

## Later  (directional, not committed)
- <theme / bet>  — <the question we're trying to answer>

## Not doing
- <thing people will ask about> — <why not, for now>
```

### Rules
- Lead with themes/outcomes; features are evidence, not the headline. Each item names the outcome it drives.
- Certainty decreases left to right: `Now` is committed, `Later` is directional. Never put dates on `Later`.
- Each theme states *why it matters* — tie to the north star or a goal.
- Note cross-theme dependencies inline (`depends on: …`).
- "Not doing" is mandatory — it's how a roadmap says no.
- Don't list every backlog item. If it's not theme-level, it belongs in the [[pm-backlog]], not here.
- No effort estimates or assignees — that lives in the [[pm-backlog]], not the roadmap.
