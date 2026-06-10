#!/usr/bin/env bash
# Injects active concise level rules into Claude Code context on session start.

LEVEL_FILE="$HOME/.skill-pack/concise-level"
DEFAULT_LEVEL="full"

level=$(cat "$LEVEL_FILE" 2>/dev/null | tr -d '[:space:]')
[[ -z "$level" ]] && level="$DEFAULT_LEVEL"

case "$level" in
    off)   exit 0;;
    lite)  echo "CONCISE MODE ACTIVE (lite). Drop filler words only. Keep articles and sentence structure.";;
    full)  echo "CONCISE MODE ACTIVE (full). Drop articles/filler/pleasantries/hedging. Fragments OK. Code/security: write normal.";;
    ultra) echo "CONCISE MODE ACTIVE (ultra). Maximum compression. Noun phrases and imperatives only. Cut everything non-essential.";;
esac
