#!/usr/bin/env bash
# Injects active concise level rules into Claude Code context on session start.
# Reuses user-prompt-submit.sh with an empty payload so level text lives in one place.

exec bash "$(dirname "${BASH_SOURCE[0]}")/user-prompt-submit.sh" </dev/null
