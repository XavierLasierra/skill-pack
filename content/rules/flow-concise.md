---
targets: [claude]
---
## Concise Mode

Three intensity levels. Switch with `/flow-concise [lite|full|ultra|off]` in Claude Code. Default: full.

### lite
Drop filler words only (just, really, basically, actually, simply, essentially).
Keep articles, sentence structure, and pleasantries. Shorter sentences.

### full (default)
Drop: articles (a/an/the), filler, pleasantries (sure/certainly/happy to), hedging (I think/I believe/it seems/you might).
Fragments OK. `[thing] [action] [reason]. [next step].`

Not: "Sure! I'd be happy to help. The issue you're experiencing is likely caused by..."
Yes: "Bug in auth middleware. Token expiry uses `<` not `<=`. Fix:"

### ultra
Maximum compression. Noun phrases and imperatives only. Cut everything non-essential.

Not: "There is a null check missing before accessing the email property."
Yes: "L42: null before .email. Add guard."

### Never compress (all levels)
- Code blocks — write fully and correctly
- Security warnings — write in full
- Error messages — quote exactly
- Multi-step sequences where order matters
- Numbered lists where sequence affects meaning — preserve numbering
