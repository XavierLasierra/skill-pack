---
name: cq-debug
description: Debug systematically instead of guessing. Use when asked to "debug this", "why is this failing", "find the bug", "this broke", "flaky test", or track down a regression. Not code review of a diff, see cq-code-review.
targets: [all]
---
## Debug

Find the root cause by experiment, not by guessing. One variable at a time. Change nothing you cannot explain.

### 1. Reproduce first
No repro, no fix. Get a minimal, repeatable trigger: smallest input, one command.
- Record the exact error, full stack trace, command, and environment (versions, OS, config).
- Flaky? Loop it until it fails (`for i in $(seq 50); do <cmd> || break; done`) and capture the failing run.
- Can't reproduce: the difference is the lead — compare env, data, timing, versions.

### 2. Read the error fully
Read the whole message and stack, top to bottom. The first frame in your own code is usually where to start; the last "caused by" is usually the real cause. Quote it exactly; don't paraphrase.

### 3. Rank hypotheses
List 2-4 candidate causes, most likely first. For each: what would be true if it were the cause. Check cheap assumptions first: wrong env/config, stale cache or build, version mismatch, bad input, recent change.
```
H1 stale build cache     — rebuild clean, 10s
H2 null from new API     — log response, 30s
H3 race in init          — add ordering log, 5m
```

### 4. Test one at a time
Pick the cheapest experiment that discriminates between hypotheses. Change one thing, run, record, revert if it did nothing. Never stack several changes — you won't know which mattered.

### 5. Narrow the space
Binary-search instead of reading everything:
- Regression with a known good commit:
  ```
  git bisect start <bad> <good>
  git bisect run ./repro.sh   # exit 0 = good, 1-127 = bad, 125 = skip
  git bisect reset
  ```
- Large input: halve it until the smallest failing case remains.
- Code path: comment out or stub half, see if the failure persists.
- Check recent changes: `git log -p -n 10 -- <path>`, dependency bumps, config edits.

### 6. Instrument, don't shotgun
Add targeted logging at the boundary where expected and actual values diverge: inputs, outputs, branch taken. Log values, not "here". Use a debugger or breakpoint if available. Remove all debug output before committing ([[cq-clean-code]]).

### 7. Fix the root cause
Ask "why" until the answer is a design or logic fault, not a symptom. A null guard that hides a bad upstream value is a symptom fix. Fix where the bad state originates.

### 8. Lock it in
Write a regression test that fails before the fix and passes after ([[cq-testing]]). Run the full suite.

### Stop and reassess
After 3 failed hypotheses, stop. Re-read the error, re-verify the repro, question assumptions you treated as fact ("that function is called", "that config is loaded"), and state the problem out loud in one paragraph. Still stuck: ask for help with the findings log attached.

### Output: findings log
```
symptom:    POST /orders returns 500 for orders with 0 items
H1:         validator missing — experiment: call service directly — result: validator runs, rejects. ruled out
H2:         null total in tax calc — experiment: log total at calc.ts:42 — result: NaN. confirmed
root cause: sum() of empty list returns undefined (utils.ts:18)
fix:        default to 0; regression test added
```
