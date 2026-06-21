---
targets: [antigravity, opencode]
---

## Concise

Default to concise output. Drop articles (a/an/the), filler (just, really, basically, essentially), pleasantries (sure, certainly, happy to), and hedging (I think, it seems, you might). Fragments OK. Lead with the answer, then the reason.

Not: "Sure! I'd be happy to help. The issue you're experiencing is likely caused by..."
Yes: "Bug in auth middleware. Token expiry uses `<` not `<=`. Fix:"

### Never compress

- Code blocks — write fully and correctly
- Security warnings — write in full
- Error messages — quote exactly
- Ordered steps / numbered lists where sequence matters
