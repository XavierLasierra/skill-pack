#!/usr/bin/env bash
# skill-pack installer — Claude Code + Antigravity CLI
# Single source of truth: content/{rules,skills,commands,agents,hooks}
# Re-running syncs: updates changed, removes deleted, adds new.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTENT_DIR="$REPO_DIR/content"
PLUGIN_NAME="sp"
MARKER_START="# >>> skill-pack:"
MARKER_END="# <<< skill-pack:"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
GRAY='\033[0;90m'
NC='\033[0m'

log()  { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }
skip() { echo -e "${GRAY}–${NC} $1"; }

# ------------------------------------------------------------------
# CLI args
# ------------------------------------------------------------------

SELECTED_TOOLS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --tools) SELECTED_TOOLS="$2"; shift 2;;
        --help|-h)
            echo "Usage: install.sh [--tools claude,antigravity]"
            echo ""
            echo "  --tools   comma-separated: claude,antigravity (default: auto-detect)"
            exit 0
            ;;
        *) warn "Unknown option: $1"; exit 1;;
    esac
done

# ------------------------------------------------------------------
# Frontmatter helpers
# ------------------------------------------------------------------

# Print the body of a file (everything after the YAML frontmatter).
# Frontmatter is recognised only when the file's first line is `---`, so a
# markdown `---` rule inside the body is preserved.
body() {
    awk '
        NR==1 && $0=="---" {infm=1; next}
        infm && $0=="---"  {infm=0; next}
        infm {next}
        {print}
    ' "$1"
}

# Print a file with the given frontmatter keys removed (only inside frontmatter).
strip_keys() {
    local f="$1"; shift
    local pat; pat="$(printf '%s\n' "$@" | paste -sd'|' -)"
    awk -v p="^(${pat}):" 'BEGIN{n=0} /^---$/{n++; print; next} n==1 && $0 ~ p {next} {print}' "$f"
}

# Read stdin and insert a line just after the opening `---`, marking the file as
# skill-pack-managed so prune/uninstall can distinguish it from the user's own.
add_marker() {
    awk 'NR==1 && $0=="---"{print; print "skill-pack: true"; next} {print}'
}

# Return 0 if the file's `targets` frontmatter includes the tool (or "all", or no targets).
target_match() {
    local f="$1" tool="$2"
    local vals
    vals="$(awk 'BEGIN{n=0} /^---$/{n++; if(n==2)exit} n==1 && /^targets:/{print}' "$f" \
        | sed 's/.*targets:[[:space:]]*//' | tr -d '[]' | tr ',' '\n' | tr -d ' ')"
    [[ -z "$vals" ]] && return 0
    echo "$vals" | grep -Fqx "all" && return 0
    echo "$vals" | grep -Fqx "$tool"
}

# ------------------------------------------------------------------
# Marker-based rule blocks (CLAUDE.md / AGENTS.md)
# ------------------------------------------------------------------

remove_block() {
    local target="$1" key="$2"
    local start="${MARKER_START}${key}" end="${MARKER_END}${key}"
    grep -qF "$start" "$target" 2>/dev/null || return 0
    if ! grep -qF "$end" "$target" 2>/dev/null; then
        warn "Missing end marker for $key in $(basename "$target") — skipping"
        return 1
    fi
    local tmp; tmp="$(mktemp)"
    awk -v s="$start" -v e="$end" '$0==s{skip=1;next} skip&&$0==e{skip=0;next} !skip{print}' "$target" > "$tmp"
    mv "$tmp" "$target" || { rm -f "$tmp"; return 1; }
}

upsert_block() {
    local target="$1" key="$2" file="$3"
    local start="${MARKER_START}${key}" end="${MARKER_END}${key}"
    mkdir -p "$(dirname "$target")"; touch "$target"
    local action="Installed"
    grep -qF "$start" "$target" 2>/dev/null && { remove_block "$target" "$key"; action="Updated"; }
    { echo ""; echo "$start"; body "$file"; echo ""; echo "$end"; } >> "$target"
    log "$action: $key → $(basename "$target")"
}

# Remove rule blocks in the file whose source no longer exists or no longer targets the tool.
prune_rules() {
    local tool="$1" target="$2"
    [[ -f "$target" ]] || return 0
    while IFS= read -r key; do
        local name="${key#rules/}"
        local src="$CONTENT_DIR/rules/${name}.md"
        if [[ ! -f "$src" ]] || ! target_match "$src" "$tool"; then
            remove_block "$target" "$key" && log "Removed stale: $key → $(basename "$target")"
        fi
    done < <(grep -F "$MARKER_START" "$target" 2>/dev/null | sed "s|.*${MARKER_START}||" | grep '^rules/')
}

install_rules() {
    local tool="$1" target="$2"
    prune_rules "$tool" "$target"
    for f in "$CONTENT_DIR"/rules/*.md; do
        [[ -f "$f" ]] || continue
        local name; name="$(basename "$f" .md)"
        if target_match "$f" "$tool"; then
            upsert_block "$target" "rules/$name" "$f"
        else
            skip "Skipped (not for $tool): rules/$name"
        fi
    done
}

# ------------------------------------------------------------------
# Directory sync (skills / agents / commands)
# ------------------------------------------------------------------

# Write $2 to file $1 only if changed; report action.
write_if_changed() {
    local dst="$1" label="$2"
    local content; content="$(cat)"
    if [[ -f "$dst" ]] && [[ "$(cat "$dst")" == "$content" ]]; then
        skip "Already current: $label"
    else
        printf '%s\n' "$content" > "$dst"
        log "Installed: $label"
    fi
}

# ------------------------------------------------------------------
# Claude Code
# ------------------------------------------------------------------

install_claude_hooks() {
    local hook_src="$CONTENT_DIR/hooks"
    local hook_dst="$HOME/.skill-pack/hooks"
    local settings="$HOME/.claude/settings.json"
    command -v python3 &>/dev/null || { warn "python3 not found — Claude hooks skipped"; return; }

    mkdir -p "$hook_dst"
    for hook in session-start user-prompt-submit statusline; do
        cp "$hook_src/${hook}.sh" "$hook_dst/"; chmod +x "$hook_dst/${hook}.sh"
        log "Installed: ${hook}.sh → $hook_dst"
    done

    python3 - "$hook_dst" "$settings" <<'PYEOF'
import json, os, shlex, sys
hook_dir, settings_path = sys.argv[1], sys.argv[2]
try:
    with open(settings_path) as f: settings = json.load(f)
except (FileNotFoundError, json.JSONDecodeError): settings = {}
hooks = settings.setdefault('hooks', {})
to_register = [
    ('SessionStart',     None, f'bash {shlex.quote(hook_dir + "/session-start.sh")}'),
    ('UserPromptSubmit', '',   f'bash {shlex.quote(hook_dir + "/user-prompt-submit.sh")}'),
]
for event, matcher, cmd in to_register:
    event_hooks = hooks.setdefault(event, [])
    already = any(any(h.get('command') == cmd for h in e.get('hooks', [])) for e in event_hooks)
    if not already:
        entry = {'hooks': [{'type': 'command', 'command': cmd}]}
        if matcher is not None: entry['matcher'] = matcher
        event_hooks.append(entry)
        print(f'\033[0;32m✓\033[0m Registered: {event}')
    else:
        print(f'\033[0;90m–\033[0m Already registered: {event}')
statusline_cmd = f'bash {shlex.quote(hook_dir + "/statusline.sh")}'
if settings.get('statusLine', {}).get('command') != statusline_cmd:
    settings['statusLine'] = {'type': 'command', 'command': statusline_cmd}
    print(f'\033[0;32m✓\033[0m Registered: statusLine')
os.makedirs(os.path.dirname(settings_path), exist_ok=True)
with open(settings_path, 'w') as f:
    json.dump(settings, f, indent=2); f.write('\n')
PYEOF
}

# Remove skill-pack-managed skill dirs whose source no longer exists / no longer targets claude.
prune_claude_skills() {
    local base="$1"
    [[ -d "$base" ]] || return 0
    for d in "$base"/*/; do
        [[ -d "$d" ]] || continue
        local sf="${d}SKILL.md"
        [[ -f "$sf" ]] && grep -qF "skill-pack: true" "$sf" 2>/dev/null || continue
        local name; name="$(basename "$d")"
        local src="$CONTENT_DIR/skills/$name/SKILL.md"
        if [[ ! -f "$src" ]] || ! target_match "$src" "claude"; then
            rm -rf "$d"; log "Removed stale: skills/$name"
        fi
    done
}

# Remove skill-pack-managed files in a dir whose source no longer exists / no longer targets claude.
prune_claude_dir() {
    local dst="$1" src_dir="$2" marker="$3"
    [[ -d "$dst" ]] || return 0
    for f in "$dst"/*.md; do
        [[ -f "$f" ]] || continue
        grep -qF "$marker" "$f" 2>/dev/null || continue
        local name; name="$(basename "$f" .md)"
        local src="$src_dir/${name}.md"
        if [[ ! -f "$src" ]] || ! target_match "$src" "claude"; then
            rm "$f"; log "Removed stale: $(basename "$f") → $(basename "$dst")"
        fi
    done
}

install_claude() {
    echo ""; echo "▸ Claude Code"
    install_rules "claude" "$HOME/.claude/CLAUDE.md"

    # Skills → ~/.claude/skills/<name>/SKILL.md
    local skills_dst="$HOME/.claude/skills"
    mkdir -p "$skills_dst"
    prune_claude_skills "$skills_dst"
    for d in "$CONTENT_DIR"/skills/*/; do
        [[ -d "$d" ]] || continue
        local name; name="$(basename "$d")"
        local src="$d/SKILL.md"
        if ! target_match "$src" "claude"; then skip "Skipped (not for claude): skills/$name"; continue; fi
        mkdir -p "$skills_dst/$name"
        strip_keys "$src" targets | add_marker | write_if_changed "$skills_dst/$name/SKILL.md" "skills/$name"
    done

    # Agents → ~/.claude/agents/<name>.md  (keep Claude frontmatter; drop targets)
    local agents_dst="$HOME/.claude/agents"
    mkdir -p "$agents_dst"
    prune_claude_dir "$agents_dst" "$CONTENT_DIR/agents" "skill-pack: true"
    for f in "$CONTENT_DIR"/agents/*.md; do
        [[ -f "$f" ]] || continue
        local name; name="$(basename "$f" .md)"
        target_match "$f" "claude" || { skip "Skipped (not for claude): agents/$name"; continue; }
        strip_keys "$f" targets | write_if_changed "$agents_dst/$name.md" "agents/$name"
    done

    # Commands → ~/.claude/commands/<name>.md
    local cmds_dst="$HOME/.claude/commands"
    mkdir -p "$cmds_dst"
    prune_claude_dir "$cmds_dst" "$CONTENT_DIR/commands" "skill-pack: true"
    for f in "$CONTENT_DIR"/commands/*.md; do
        [[ -f "$f" ]] || continue
        local name; name="$(basename "$f" .md)"
        target_match "$f" "claude" || { skip "Skipped (not for claude): commands/$name"; continue; }
        strip_keys "$f" targets | add_marker | write_if_changed "$cmds_dst/$name.md" "commands/$name"
    done

    install_claude_hooks
}

# ------------------------------------------------------------------
# Antigravity CLI (agy)
# ------------------------------------------------------------------

install_antigravity() {
    echo ""; echo "▸ Antigravity CLI (agy)"
    install_rules "antigravity" "$HOME/.gemini/AGENTS.md"

    # Build a native agy plugin from content/, then register it with `agy plugin install`.
    local stage="$HOME/.skill-pack/antigravity/$PLUGIN_NAME"
    rm -rf "$stage"; mkdir -p "$stage/skills" "$stage/agents" "$stage/commands"
    printf '{"name":"%s","description":"skill-pack behavioral skills","disabled":false}\n' "$PLUGIN_NAME" > "$stage/plugin.json"

    local count=0
    for d in "$CONTENT_DIR"/skills/*/; do
        [[ -d "$d" ]] || continue
        local name; name="$(basename "$d")"
        target_match "$d/SKILL.md" "antigravity" || continue
        mkdir -p "$stage/skills/$name"
        strip_keys "$d/SKILL.md" targets > "$stage/skills/$name/SKILL.md"
        count=$((count+1))
    done
    for f in "$CONTENT_DIR"/agents/*.md; do
        [[ -f "$f" ]] || continue
        local name; name="$(basename "$f" .md)"
        target_match "$f" "antigravity" || continue
        strip_keys "$f" targets model tools skill-pack > "$stage/agents/$name.md"
        count=$((count+1))
    done
    for f in "$CONTENT_DIR"/commands/*.md; do
        [[ -f "$f" ]] || continue
        local name; name="$(basename "$f" .md)"
        target_match "$f" "antigravity" || continue
        strip_keys "$f" targets > "$stage/commands/$name.md"
        count=$((count+1))
    done
    rmdir "$stage/skills" "$stage/agents" "$stage/commands" 2>/dev/null || true

    if ! command -v agy &>/dev/null; then
        warn "agy not on PATH — plugin staged at $stage. Run: agy plugin install $stage"
        return
    fi
    local vout
    if ! vout="$(agy plugin validate "$stage" 2>&1)"; then
        warn "Plugin failed validation: $(echo "$vout" | tail -1)"
        return
    fi
    agy plugin uninstall "$PLUGIN_NAME" >/dev/null 2>&1 || true
    if agy plugin install "$stage" >/dev/null 2>&1; then
        log "Installed plugin '$PLUGIN_NAME' ($count components) via agy"
    else
        warn "agy plugin install failed — plugin staged at $stage. Run: agy plugin install $stage"
    fi
}

# ------------------------------------------------------------------
# Detection + dispatch
# ------------------------------------------------------------------

detect_and_install() {
    local installed=0
    local tools="$SELECTED_TOOLS"
    if [[ -z "$tools" ]]; then
        if command -v claude &>/dev/null || [[ -d "$HOME/.claude" ]]; then
            tools="claude"
        fi
        if command -v agy &>/dev/null || [[ -d "$HOME/.gemini/antigravity-cli" ]]; then
            tools="${tools:+$tools,}antigravity"
        fi
    fi

    [[ -z "$tools" ]] && { warn "No supported tools detected (claude, antigravity)."; return; }
    echo ""; echo "Target tools: $tools"
    for tool in $(echo "$tools" | tr ',' '\n'); do
        case "$tool" in
            claude)      install_claude;       installed=$((installed+1));;
            antigravity) install_antigravity;  installed=$((installed+1));;
            *)           warn "Unknown tool: $tool";;
        esac
    done
    echo ""
    [[ $installed -gt 0 ]] && log "Done. Re-run to sync. bash uninstall.sh to remove."
}

echo "skill-pack installer"
echo "===================="
detect_and_install
