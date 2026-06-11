Compact the current conversation into a handoff document so another agent or session can continue the work.

Focus for next session (if provided): $ARGUMENTS

## Steps

1. **Determine the output path**
   - macOS/Linux: `/tmp/handoff-<slug>.md` where `<slug>` is a 2–3 word kebab-case summary of the work
   - Windows: `%TEMP%\handoff-<slug>.md`

2. **Write the document** using this structure:

```markdown
# Handoff — <title>

## Goal
One sentence: what this session was trying to accomplish.

## Current state
What is done. What is not done. Where work stopped.

## Key decisions
Bullet list: decision → reason. Only non-obvious choices.

## Pending work
Ordered list of remaining tasks, most important first.

## References
Pointers to existing artifacts — do NOT reproduce their content:
- File paths with line numbers for relevant code
- Commit SHAs or branch names
- PRD / ADR / plan files if they exist
- Open issues or tickets

## Open questions
Blockers or uncertainties the next session needs to resolve.

## Suggested skills
Skills or context the next agent should load (e.g. concise mode, relevant domain knowledge).
```

3. If `$ARGUMENTS` is set, tailor "Pending work" and "Suggested skills" toward that focus.

## Rules
- Reference existing artifacts (plans, diffs, PRDs, commits) — never copy their content into the document
- Redact sensitive data: API keys, passwords, tokens, PII
- Keep the document under 400 lines — summarize aggressively if needed
- After writing, print the file path
