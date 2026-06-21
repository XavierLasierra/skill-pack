---
name: pm-product-brief
description: Write a one-page product brief to kick off a new project or feature. Use when asked to draft a brief, frame a problem, pitch an idea, or start product planning from scratch — before a full spec exists. Text only.
targets: [all]
---
## Product Brief

A one-pager that aligns people *before* a full spec is worth writing. If the idea can't fit on one page, it isn't clear enough yet. Output text only — never create files or tickets unless asked.

### Before drafting
If the user hasn't given you the problem, the audience, or what success looks like, ask — at most three questions, then draft. Don't invent metrics or users; mark any unknown inline as `[NEEDS CLARIFICATION: <question>]`.

### Template

```markdown
# <Project / feature name>

**One-liner:** <what it is, in one sentence a stranger understands>

## Problem
Who hurts, and how. 2–3 sentences. No solution here.

## Who it's for
Primary user / segment. Be specific — "everyone" means no one.

## Why now
The trigger: market shift, user pain reaching threshold, dependency just unblocked. Why not last year, why not next.

## Proposed approach
The shape of the solution in 2–3 sentences. Not the implementation.

## Success looks like
1–3 measurable outcomes. `<metric> from <baseline> to <target> by <when>`.
If a metric has no baseline yet, mark it `[NEEDS CLARIFICATION: baseline?]`.

## Out of scope
What this explicitly does NOT do. The most useful section — it kills scope creep early.

## Risks & open questions
- <biggest thing that could sink this>
- <unanswered question blocking commitment>
```

### Rules
- One page. If it overflows, cut — don't shrink the font.
- Problem section contains zero solution language.
- Every success metric is measurable or marked `TBD`. No "improve UX", "delight users".
- "Out of scope" is mandatory, never empty — name at least one thing.
- Don't pad with sections that have nothing to say; omit them.
