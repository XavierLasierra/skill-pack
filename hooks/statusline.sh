#!/usr/bin/env bash
LEVEL_FILE="$HOME/.skill-pack/concise-level"
DEFAULT_LEVEL="full"

level=$(cat "$LEVEL_FILE" 2>/dev/null | tr -d '[:space:]')
[[ -z "$level" ]] && level="$DEFAULT_LEVEL"

echo "concise:$level"
