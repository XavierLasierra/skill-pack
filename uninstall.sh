#!/usr/bin/env bash
# skill-pack uninstaller — Claude Code + Antigravity CLI

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_NAME="sp"
MARKER_START="# >>> skill-pack:"
MARKER_END="# <<< skill-pack:"

GREEN='\033[0;32m'; GRAY='\033[0;90m'; NC='\033[0m'
log()  { echo -e "${GREEN}✓${NC} $1"; }
skip() { echo -e "${GRAY}–${NC} $1"; }

# Strip every skill-pack marker block from a file; delete the file if nothing remains.
clean_blocks() {
    local file="$1"
    [[ -f "$file" ]] || { skip "Not found: $file"; return; }
    grep -qF "$MARKER_START" "$file" 2>/dev/null || { skip "No skill-pack content: $file"; return; }
    local tmp; tmp="$(mktemp)"
    awk -v s="$MARKER_START" -v e="$MARKER_END" '
        substr($0,1,length(s))==s {skip=1; next}
        skip && substr($0,1,length(e))==e {skip=0; next}
        !skip {print}' "$file" > "$tmp"
    if ! grep -q '[^[:space:]]' "$tmp"; then
        rm "$file" "$tmp"; log "Removed (empty): $file"
    else
        mv "$tmp" "$file"; log "Cleaned: $file"
    fi
}

remove_claude_hooks() {
    local hook_dst="$HOME/.skill-pack/hooks"
    local settings="$HOME/.claude/settings.json"
    for hook in session-start user-prompt-submit statusline; do
        [[ -f "$hook_dst/${hook}.sh" ]] && { rm "$hook_dst/${hook}.sh"; log "Removed: ${hook}.sh"; }
    done
    if [[ -f "$settings" ]] && command -v python3 &>/dev/null; then
        python3 - "$hook_dst" "$settings" <<'PYEOF'
import json, shlex, sys
hook_dir, settings_path = sys.argv[1], sys.argv[2]
to_remove = {f'bash {shlex.quote(hook_dir + "/session-start.sh")}',
             f'bash {shlex.quote(hook_dir + "/user-prompt-submit.sh")}'}
try:
    with open(settings_path) as f: settings = json.load(f)
except (FileNotFoundError, json.JSONDecodeError, OSError): sys.exit(0)
for event in list(settings.get('hooks', {})):
    entries = settings['hooks'][event]
    for entry in entries:
        entry['hooks'] = [h for h in entry.get('hooks', []) if h.get('command') not in to_remove]
    settings['hooks'][event] = [e for e in entries if e.get('hooks')]
settings['hooks'] = {k: v for k, v in settings.get('hooks', {}).items() if v}
if settings.get('statusLine', {}).get('command') == f'bash {shlex.quote(hook_dir + "/statusline.sh")}':
    del settings['statusLine']
with open(settings_path, 'w') as f:
    json.dump(settings, f, indent=2); f.write('\n')
PYEOF
        log "Removed hooks from settings.json"
    fi
    rm -f "$HOME/.skill-pack/concise-level"
    rmdir "$hook_dst" 2>/dev/null || true
}

uninstall_claude() {
    echo ""; echo "▸ Claude Code"
    clean_blocks "$HOME/.claude/CLAUDE.md"

    # Skills (marker-based)
    if [[ -d "$HOME/.claude/skills" ]]; then
        for d in "$HOME/.claude/skills"/*/; do
            [[ -d "$d" ]] || continue
            [[ -f "${d}SKILL.md" ]] && grep -qF "skill-pack: true" "${d}SKILL.md" 2>/dev/null || continue
            rm -rf "$d"; log "Removed: skills/$(basename "$d")"
        done
        rmdir "$HOME/.claude/skills" 2>/dev/null || true
    fi

    # Agents (marker-based)
    if [[ -d "$HOME/.claude/agents" ]]; then
        for f in "$HOME/.claude/agents"/*.md; do
            [[ -f "$f" ]] || continue
            grep -qF "skill-pack: true" "$f" 2>/dev/null && { rm "$f"; log "Removed: agents/$(basename "$f" .md)"; }
        done
        rmdir "$HOME/.claude/agents" 2>/dev/null || true
    fi

    # Commands (marker-based)
    if [[ -d "$HOME/.claude/commands" ]]; then
        for f in "$HOME/.claude/commands"/*.md; do
            [[ -f "$f" ]] || continue
            grep -qF "skill-pack: true" "$f" 2>/dev/null && { rm "$f"; log "Removed: commands/$(basename "$f" .md)"; }
        done
        rmdir "$HOME/.claude/commands" 2>/dev/null || true
    fi

    remove_claude_hooks
}

uninstall_antigravity() {
    echo ""; echo "▸ Antigravity CLI (agy)"
    if command -v agy &>/dev/null; then
        agy plugin uninstall "$PLUGIN_NAME" >/dev/null 2>&1 && log "Uninstalled plugin '$PLUGIN_NAME'" \
            || skip "Plugin '$PLUGIN_NAME' not installed"
    fi
    clean_blocks "$HOME/.gemini/AGENTS.md"
    rm -rf "$HOME/.skill-pack/antigravity"
    rmdir "$HOME/.skill-pack" 2>/dev/null || true
}

echo "skill-pack uninstaller"
echo "======================"
uninstall_claude
uninstall_antigravity
echo ""
log "Done. Restart Claude Code / agy."
