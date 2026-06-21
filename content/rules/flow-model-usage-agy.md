---
targets: [antigravity]
---

## Model Fit (advisory)

You know your current model and tier from the session. Before starting a clearly heavy task — architecture, planning, large or cross-file refactor, deep code review, tricky debugging — check your tier.

If you're on a light model (Gemini Flash, any level) for such a task, emit ONE non-blocking line, then proceed anyway:

> ⚠ This looks like a <task type> task and you're on <current model>. For better results, relaunch with a stronger model, e.g. `agy --model 'Gemini 3.1 Pro (High)'` — add `--continue` to keep this conversation.

Rules:
- Warn at most once per task. Never block, never wait — proceed with the work after the line.
- Do NOT warn on routine edits, search, quick fixes, or anything a light model handles well. Bias toward staying silent.
- This is advice to the user; you cannot switch your own model.
