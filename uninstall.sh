#!/usr/bin/env bash
# skill-pack uninstaller
# Removes all skill-pack content from all config files.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARKER_START="# >>> skill-pack:"
MARKER_END="# <<< skill-pack:"

GREEN='\033[0;32m'
GRAY='\033[0;90m'
NC='\033[0m'

log()  { echo -e "${GREEN}✓${NC} $1"; }
skip() { echo -e "${GRAY}–${NC} $1"; }

remove_skills_from_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        skip "Not found: $file"
        return
    fi

    if ! grep -qF "$MARKER_START" "$file" 2>/dev/null; then
        skip "No skill-pack content: $file"
        return
    fi

    local tmp
    tmp="$(mktemp)"
    awk -v start="$MARKER_START" -v end="$MARKER_END" '
        substr($0, 1, length(start)) == start { skip=1; next }
        skip && substr($0, 1, length(end)) == end { skip=0; next }
        !skip { print }
    ' "$file" > "$tmp"

    # Delete file if nothing meaningful remains
    if ! grep -q '[^[:space:]]' "$tmp"; then
        rm "$file" "$tmp"
        log "Removed (empty after clean): $file"
    else
        mv "$tmp" "$file"
        log "Cleaned: $file"
    fi
}

remove_cursor_rules() {
    local rules_dir="$HOME/.cursor/rules"
    if [[ ! -d "$rules_dir" ]]; then
        skip "Cursor rules dir not found"
        return
    fi
    local found=0
    for f in "$rules_dir"/*.mdc; do
        [[ -f "$f" ]] || continue
        if grep -qF "skill-pack/" "$f" 2>/dev/null; then
            rm "$f"
            log "Removed: $f"
            found=$((found + 1))
        fi
    done
    [[ $found -eq 0 ]] && skip "No skill-pack Cursor rules found"
}

remove_kiro_steering() {
    local kiro_dir="$REPO_DIR/.kiro/steering"
    if [[ ! -d "$kiro_dir" ]]; then
        skip "Kiro steering dir not found"
        return
    fi
    local removed=0
    while IFS= read -r skill_md; do
        local skill_name="${skill_md#"$REPO_DIR/skills/"}"
        skill_name="${skill_name%.md}"
        local f="$kiro_dir/${skill_name//\//-}.md"
        if [[ -f "$f" ]] && grep -qF "<!-- skill-pack -->" "$f" 2>/dev/null; then
            rm "$f"
            log "Removed: $f"
            removed=$((removed + 1))
        fi
    done < <(find "$REPO_DIR/skills" -name "*.md" | sort)
    [[ $removed -eq 0 ]] && skip "No skill-pack Kiro steering files found"
    rmdir "$kiro_dir" 2>/dev/null && rmdir "$REPO_DIR/.kiro" 2>/dev/null || true
}

echo "skill-pack uninstaller"
echo "======================"
echo ""

remove_claude_hooks() {
    local hook_dst="$HOME/.skill-pack/hooks"
    local settings="$HOME/.claude/settings.json"

    if [[ ! -d "$hook_dst" ]] && [[ ! -f "$settings" ]]; then
        skip "No skill-pack hooks found"
        return
    fi

    # Remove hook scripts
    for hook in session-start user-prompt-submit statusline; do
        local f="$hook_dst/${hook}.sh"
        if [[ -f "$f" ]]; then
            rm "$f"
            log "Removed: $f"
        fi
    done
    rmdir "$hook_dst" 2>/dev/null || true
    rmdir "$HOME/.skill-pack" 2>/dev/null || true

    # Remove from settings.json
    if [[ -f "$settings" ]] && command -v python3 &>/dev/null; then
        python3 - "$hook_dst" "$settings" <<'PYEOF'
import json, os, shlex, sys

hook_dir, settings_path = sys.argv[1], sys.argv[2]
to_remove = {
    f'bash {shlex.quote(hook_dir + "/session-start.sh")}',
    f'bash {shlex.quote(hook_dir + "/user-prompt-submit.sh")}',
}

try:
    with open(settings_path) as f:
        settings = json.load(f)
except (FileNotFoundError, json.JSONDecodeError, OSError):
    sys.exit(0)

for event in list(settings.get('hooks', {})):
    entries = settings['hooks'][event]
    for entry in entries:
        entry['hooks'] = [h for h in entry.get('hooks', []) if h.get('command') not in to_remove]
    settings['hooks'][event] = [e for e in entries if e.get('hooks')]

settings['hooks'] = {k: v for k, v in settings.get('hooks', {}).items() if v}

statusline_cmd = f'bash {shlex.quote(hook_dir + "/statusline.sh")}'
if settings.get('statusLine', {}).get('command') == statusline_cmd:
    del settings['statusLine']

with open(settings_path, 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')
PYEOF
        log "Removed hooks from settings.json"
    fi

    # Remove flag file and dir
    rm -f "$HOME/.skill-pack/concise-level"
    rmdir "$HOME/.skill-pack" 2>/dev/null || true
}

remove_claude_agents() {
    local agents_dst="$HOME/.claude/agents"
    [[ ! -d "$agents_dst" ]] && skip "No skill-pack agents found" && return

    local removed=0
    for f in "$agents_dst"/*.md; do
        [[ -f "$f" ]] || continue
        if grep -qF "skill-pack: true" "$f" 2>/dev/null; then
            rm "$f"
            log "Removed agent: $f"
            removed=$((removed + 1))
        fi
    done
    [[ $removed -eq 0 ]] && skip "No skill-pack agents found"
    rmdir "$agents_dst" 2>/dev/null || true
}

echo "Global tool configs:"
remove_skills_from_file "$HOME/.claude/CLAUDE.md"
remove_claude_hooks
remove_claude_agents
remove_skills_from_file "$HOME/.gemini/GEMINI.md"
remove_skills_from_file "$HOME/.windsurfrules"
remove_cursor_rules

echo ""
echo "Project templates:"
remove_skills_from_file "$REPO_DIR/.github/copilot-instructions.md"
remove_skills_from_file "$REPO_DIR/.clinerules"
remove_skills_from_file "$REPO_DIR/AGENTS.md"
remove_skills_from_file "$REPO_DIR/.roorules"
remove_kiro_steering

echo ""
log "Done. Restart your AI CLI tools."
