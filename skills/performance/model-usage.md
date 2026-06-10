---
applies_to: claude
---
## Model Usage — Cost & Speed

### Rules
- **Haiku**: minor ops — text editing, git commits, file edits, repo management
- **Opus**: planning only — design, architecture, analysis
- **Sonnet**: execution — implementing changes, running tests, complex logic, multi-step agentic tasks
- **Sonnet + 1M context**: requires explicit user consent before use

Never auto-upgrade to a higher-context model. Ask first.

If Haiku produces a wrong or incomplete answer, escalate to Sonnet — do not retry on Haiku.
