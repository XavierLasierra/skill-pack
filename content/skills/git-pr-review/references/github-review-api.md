# GitHub review mechanics

`gh` must be authenticated (`gh auth status`). Set once:
```bash
PR=123; REPO=owner/name          # from the PR URL
ME=$(gh api user --jq .login)
```

## 1. PR state
```bash
gh pr view "$PR" -R "$REPO" --json \
  number,title,url,state,isDraft,author,baseRefName,headRefName,headRefOid,\
mergeable,mergeStateStatus,reviewDecision,statusCheckRollup,changedFiles,additions,deletions
```
- `mergeable`: `MERGEABLE` · `CONFLICTING` · `UNKNOWN` (computed lazily — wait a few seconds and re-query)
- `mergeStateStatus`: `CLEAN` · `BEHIND` · `DIRTY` (conflicts) · `BLOCKED` · `UNSTABLE` (checks failing) · `DRAFT` · `UNKNOWN`
- Own PR: `author.login == $ME` → event must be `COMMENT`
- Failing check log: `gh run view <run-id> -R "$REPO" --log-failed`

## 2. Does the base already have the change?
Fetch without touching the working tree:
```bash
BASE=$(gh pr view "$PR" -R "$REPO" --json baseRefName --jq .baseRefName)
git fetch origin "$BASE" "pull/$PR/head:refs/remotes/pr/$PR"
```
- `git cherry "origin/$BASE" "pr/$PR"` — lines starting `-` are commits whose patch is already in base. All `-` → obsolete.
- `git diff --stat "origin/$BASE" "pr/$PR" -- $(git diff --name-only "origin/$BASE...pr/$PR")` — empty → base already has the PR's version of every touched file.
- `git log "origin/$BASE" -S'<distinctive added string>' --oneline` — finds a base commit that landed the same code another way.
- Superseded: `gh pr list -R "$REPO" --state all --search "<key term> in:title"`

Reading files at PR head without checkout: `git show "pr/$PR:path/to/file"`. Need a full tree (run tests, grep): `git worktree add "$TMPDIR/pr-$PR" "pr/$PR"`, remove with `git worktree remove` when done.

## 3. Existing feedback
REST has no resolved/outdated flags — use GraphQL for threads:
```bash
gh api graphql -F owner="${REPO%/*}" -F name="${REPO#*/}" -F pr="$PR" -f query='
query($owner:String!,$name:String!,$pr:Int!){
  repository(owner:$owner,name:$name){ pullRequest(number:$pr){
    reviewThreads(first:100){ nodes{ isResolved isOutdated path line
      comments(first:20){ nodes{ author{login} body } } } }
    reviews(last:50){ nodes{ author{login} state body } } } } }'
```
Conversation comments (bots, summaries): `gh pr view "$PR" -R "$REPO" --json comments`. Note `--json comments` does **not** include inline review threads.

Same path + overlapping line + same topic = already raised. Drop it.

## 4. Post one review
Valid anchors — every `path:line` an inline comment may target on the new side (added or context lines):
```bash
gh pr diff "$PR" -R "$REPO" | awk '
  /^\+\+\+ /   { file = substr($2, 3); next }
  /^@@/        { match($0, /\+[0-9]+/); line = substr($0, RSTART + 1, RLENGTH - 1); next }
  /^[ +]/      { print file ":" line; line++ }'
```
Every comment's `path:line` must appear in that list. One bad anchor rejects the whole review.

Check for a pending review first (only one allowed per user per PR):
```bash
gh api "repos/$REPO/pulls/$PR/reviews" --paginate \
  --jq ".[] | select(.state==\"PENDING\" and .user.login==\"$ME\") | .id"
```
Found one → tell the user; they submit or delete it in the UI before continuing.

Re-fetch `headRefOid` right before posting, then send the payload on stdin. Use `--input -`: `-f comments[]=…` builds an object, not an array.
```bash
gh api -X POST "repos/$REPO/pulls/$PR/reviews" --input - --jq .html_url <<'EOF'
{
  "commit_id": "<headRefOid>",
  "event": "REQUEST_CHANGES",
  "body": "Summary text approved by the user.",
  "comments": [
    { "path": "src/a.ts", "line": 42, "side": "RIGHT", "body": "Single-line comment." },
    { "path": "src/b.ts", "start_line": 10, "start_side": "RIGHT", "line": 12, "side": "RIGHT",
      "body": "Multi-line comment; line is the LAST line.\n```suggestion\nreplacement for lines 10-12\n```" }
  ]
}
EOF
```
- `event`: `COMMENT` or `REQUEST_CHANGES` (this skill never sends `APPROVE`). Omitting it leaves the review pending.
- Use `line`/`side`, not the legacy `position` (diff offset).
- `side: "LEFT"` targets deleted lines; `suggestion` blocks don't work there.
- A `suggestion` block replaces the whole `start_line`..`line` range.

## 422 errors
| Message | Cause | Fix |
|---|---|---|
| `Pull request review thread line must be part of the diff` | anchor outside a hunk | re-anchor to a diff line, or move the point to the summary body |
| `commit_sha is not part of the pull request` | head moved | re-fetch `headRefOid`, re-check anchors |
| `User can only have one pending review per pull request` | draft review exists | user submits or deletes it |
| `Can not request changes on your own pull request` | own PR | use `COMMENT` |

## 5. Single top-level comment
For the "shouldn't proceed" path:
```bash
gh pr comment "$PR" -R "$REPO" --body-file - <<'EOF'
Comment text approved by the user.
EOF
```
