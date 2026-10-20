#!/usr/bin/env bash
LEVEL_FILE="$HOME/.skill-pack/concise-level"
DEFAULT_LEVEL="full"

level=$(tr -d '[:space:]' 2>/dev/null < "$LEVEL_FILE")
[[ -z "$level" ]] && level="$DEFAULT_LEVEL"

echo "concise:$level"
