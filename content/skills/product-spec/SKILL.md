---
name: product-spec
description: Write a product specification or PRD for a feature or product. Use when asked to draft a spec, PRD, requirements doc, or detailed product definition. Builds on a brief if one exists. Text only.
targets: [all]
---
## Product Spec (PRD)

The contract between product, design, and engineering: what we're building, for whom, and how we'll know it worked. Detailed enough to estimate and build from, not a design doc. Output text only.

### Before drafting
Anchor on a [[product-brief]] if one exists — don't re-derive the problem, reference it. If no brief and the problem/users/goals are unclear, ask up to three questions, then draft. Where you must guess or something is undecided, flag it inline as `[NEEDS CLARIFICATION: <question>]` so reviewers see exactly what to confirm.

### Template

```markdown
# Spec: <feature name>

**Status:** Draft · **Owner:** <name> · **Last updated:** <YYYY-MM-DD>

## Summary
2–3 sentences: what and why. Link the brief if there is one.

## Goals
- <outcome 1 — measurable>
- <outcome 2>

## Non-goals
- <explicitly not doing this — and why>

## Users & use cases
| User | Job to be done | Today's workaround |
|---|---|---|

## User stories
As a `<role>`, I want `<capability>`, so that `<benefit>`.
List the core stories — each should map to one or more tickets later.

## Requirements
### Functional
- `[MUST]` <requirement>
- `[SHOULD]` <requirement>
- `[COULD]` <requirement>
### Non-functional
- Performance / scale / security / accessibility constraints with numbers.

## UX / flow
Key flows as numbered steps or a description. Link mocks if they exist; don't invent UI.

## Success metrics
`<metric> from <baseline> to <target> by <when>`. How each is measured.

## Dependencies & risks
- Depends on: <team / service / decision>
- Risk: <what could go wrong> → mitigation.

## Open questions
- [ ] <question> — owner, needed by <when>
```

### Rules
- Use `MUST` / `SHOULD` / `COULD` (MoSCoW) on every functional requirement — it drives prioritization.
- Goals are outcomes, not features. "Users can export CSV" is a requirement; "cut manual reporting time 50%" is a goal.
- Non-goals and open questions are mandatory sections — empty ones mean the spec isn't ready.
- Numbers, not adjectives: "P95 < 200ms", not "fast".
- Don't specify implementation (DB schema, class names) — that's the engineer's call. Specify behavior and constraints.
- Flag every guess or undecided point inline with `[NEEDS CLARIFICATION: …]` so review can attack it.
