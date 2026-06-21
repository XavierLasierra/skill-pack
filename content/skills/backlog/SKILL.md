---
name: backlog
description: Break a spec or roadmap into a structured backlog of epics and user stories. Use when asked to decompose a feature, create epics/stories, slice work, or turn a spec into a backlog. Text only.
targets: [all]
---
## Backlog

Turns a [[product-spec]] or [[roadmap]] theme into a hierarchy a team can pull from: **Epic → Story → (later) ticket**. The job is *vertical slicing* — each story delivers user-visible value on its own, not a horizontal layer (no "build the database" story). Output text only.

### Input
Work from an existing spec/roadmap if given. If not, ask for the feature and its goal, then decompose. Don't invent requirements the source doesn't state — flag gaps inline as `[NEEDS CLARIFICATION: <question>]`.

### Structure

```markdown
# Backlog: <feature / theme>

## Epic: <outcome-level chunk>
*Goal:* <the user/business outcome this epic delivers>

### Stories
1. As a `<role>`, I want `<capability>`, so that `<benefit>`.
   - **AC:** <the one condition that makes this done>
   - *Size:* S / M / L  ·  *Priority:* P0 / P1 / P2  ·  *Depends on:* <story # or none>
2. ...

## Epic: <next chunk>
...

## Sequencing
Walking skeleton first: the thinnest end-to-end slice that works, then layer value.
1. <story #> — why first
2. <story #>
```

### Rules
- **Vertical slices only.** Each story is shippable user value. "Set up auth tables" is a task, not a story — fold it into the first story that needs it.
- **INVEST** check each story: Independent, Negotiable, Valuable, Estimable, Small, Testable. If a story fails "Small", split it.
- Sizes are relative (S/M/L or points), never hours. If a story is `L`, suggest how to split it.
- Priority with a scheme (P0/P1/P2 or MoSCoW) on every story — an unprioritized backlog is a wishlist.
- Surface dependencies between stories explicitly; a backlog with hidden ordering is a trap.
- Don't expand stories into full tickets here — that's the [[work-ticket]] skill, done when a story is pulled into a sprint.
- Sequencing leads with a walking skeleton (thin end-to-end path), then value-ordered.
