---
name: work-ticket
description: Write a single implementable work ticket / user story for any tracker (Jira, Linear, GitHub). Use when asked to write a ticket, issue, user story, or task with acceptance criteria. Plain markdown, text only — never creates the ticket.
targets: [all]
---
## Work Ticket

One well-formed ticket a developer can pick up cold and finish without a meeting. Tracker-agnostic, **plain markdown**. Text only — output the ticket; never create it in a tracker unless explicitly asked and a tool is available.

### Before writing
Need the *what* and the *why*. If the user gives only a title, ask one question: what outcome does this serve? Then write. Pull context from a [[backlog]] story or [[product-spec]] if one exists rather than re-deriving it. Anything you can't resolve, mark inline as `[NEEDS CLARIFICATION: <question>]` rather than guessing silently.

### Template

```markdown
## <Type>: <imperative summary, ≤ 70 chars>

**Story:** As a `<role>`, I want `<capability>`, so that `<benefit>`.
*(omit for pure tech tasks — use a one-line problem statement instead)*

### Context
Why this exists, link to spec/parent epic. 1–3 sentences. Enough to start without asking.

### Acceptance criteria
- [ ] Given `<context>`, when `<action>`, then `<outcome>`.
- [ ] <criterion 2>
- [ ] <edge case / error path>

### Out of scope
- <what this ticket deliberately does not cover>

### Notes
- Dependencies, links, design refs, suggested approach (suggested — not prescribed).

**Type:** Story / Bug / Task   ·   **Estimate:** <S/M/L or points, if known>   ·   **Labels:** <area, component>
```

### Bug variant
For bugs, replace Story/Context with:
```markdown
**Steps to reproduce:** 1. … 2. …
**Expected:** <what should happen>
**Actual:** <what happens>
**Environment:** <version / browser / OS>
```

### Rules
- Summary in imperative mood, ≤ 70 chars, no trailing period. `Add CSV export to reports`, not `CSV export feature`.
- Acceptance criteria are testable and in Given/When/Then form — each one a checkbox someone can verify true/false. No "works correctly".
- Always include at least one edge/error-path criterion.
- "Out of scope" present whenever the boundary isn't obvious — prevents scope creep mid-ticket.
- A ticket should be one sitting of work. If acceptance criteria sprawl past ~5, it's an epic — split it (see [[backlog]]).
- Notes may *suggest* an approach but never mandate implementation — leave the how to the assignee.
- Plain markdown only. No Jira wiki markup, no HTML.
