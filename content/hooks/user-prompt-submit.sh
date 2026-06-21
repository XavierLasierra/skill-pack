#!/usr/bin/env bash
# Reinjects active concise level every turn. Handles /flow-concise level-switch commands.

LEVEL_FILE="$HOME/.skill-pack/concise-level"
DEFAULT_LEVEL="full"

# Read prompt from Claude Code's stdin JSON payload
_raw=$(cat)
prompt=$(echo "$_raw" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('prompt', '').strip())
except (json.JSONDecodeError, KeyError, TypeError, ValueError):
    print('')
" 2>/dev/null) || prompt=""

# Handle /flow-concise command
if [[ "$prompt" =~ ^/flow-concise([[:space:]]|$) ]]; then
    arg=$(echo "$prompt" | sed 's|^/flow-concise||' | tr -d '[:space:]')
    case "$arg" in
        lite|full|ultra|off)
            mkdir -p "$HOME/.skill-pack"
            echo "$arg" > "$LEVEL_FILE"
            echo "Concise level → $arg"
            exit 0
            ;;
        "")
            current=$(cat "$LEVEL_FILE" 2>/dev/null | tr -d '[:space:]' || echo "$DEFAULT_LEVEL")
            echo "Concise: $current. Switch: /flow-concise lite|full|ultra|off"
            exit 0
            ;;
        *)
            echo "Unknown level '$arg'. Valid: lite|full|ultra|off"
            exit 0
            ;;
    esac
fi

# Reinject active level rules
level=$(cat "$LEVEL_FILE" 2>/dev/null | tr -d '[:space:]')
[[ -z "$level" ]] && level="$DEFAULT_LEVEL"

case "$level" in
    off)   exit 0;;
    lite)  echo "CONCISE MODE ACTIVE (lite). Drop filler words only. Keep articles and sentence structure.";;
    full)  echo "CONCISE MODE ACTIVE (full). Drop articles/filler/pleasantries/hedging. Fragments OK. Code/security: write normal.";;
    ultra) echo "CONCISE MODE ACTIVE (ultra). Maximum compression. Noun phrases and imperatives only. Cut everything non-essential.";;
esac
