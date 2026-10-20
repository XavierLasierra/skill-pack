---
name: pm-work-ticket
description: Write a single implementable work ticket / user story, and optionally file it in a tracker (Jira, Linear, GitHub) when a tool for it is available. Use when asked to write, create, or file a ticket, issue, user story, or task with acceptance criteria. Not a whole backlog, see pm-backlog.
targets: [all]
---
## Work Ticket

One well-formed ticket a developer can pick up cold and finish without a meeting. Tracker-agnostic: draft in markdown, then deliver as text or file it in a tracker — see **Delivery**.

### Before writing
Need the *what* and the *why*. If the user gives only a title, ask one question: what outcome does this serve? Then write. Pull context from a [[pm-backlog]] story or [[pm-product-spec]] if one exists rather than re-deriving it. Anything you can't resolve, mark inline as `[NEEDS CLARIFICATION: <question>]` rather than guessing silently.

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

### Delivery
Pick by what the user asked for and what tools the session has (tracker MCP server, `gh`, `linear` CLI):
- **Asked to create/file/open it** ("create a Jira ticket for…") and a tracker tool is available → show the draft, get a go-ahead, then create it. Return the key and URL.
- **Asked to write/draft it**, or no tracker tool → output the markdown. If a tracker tool is available, offer to file it in one line; don't create unprompted.
- **Asked to create but no tool** → output the markdown and say no tracker tool is connected.
- **Updating an existing ticket** → fetch it first, edit only the changed fields, never overwrite the description wholesale without showing the diff.

Filing it:
- Resolve project, issue type, and parent epic from the tracker (list projects / issue types) or the user — never guess a project key. Ambiguous → ask once.
- Map fields, don't flatten them into the body: summary → title, Type → issue type, Labels → labels, Estimate → story points only if the field exists, epic → parent link.
- Body format follows what the tool accepts (check its format guidance; most accept markdown). Keep the template sections intact.
- One ticket per create call. Many tickets at once is a backlog — confirm the full list first ([[pm-backlog]]).

### Rules
- Summary in imperative mood, ≤ 70 chars, no trailing period. `Add CSV export to reports`, not `CSV export feature`.
- Acceptance criteria are testable and in Given/When/Then form — each one a checkbox someone can verify true/false. No "works correctly".
- Always include at least one edge/error-path criterion.
- "Out of scope" present whenever the boundary isn't obvious — prevents scope creep mid-ticket.
- A ticket should be one sitting of work. If acceptance criteria sprawl past ~5, it's an epic — split it (see [[pm-backlog]]).
- Notes may *suggest* an approach but never mandate implementation — leave the how to the assignee.
- Draft in plain markdown — no Jira wiki markup or HTML in the text you show; convert only if the filing tool requires it.
