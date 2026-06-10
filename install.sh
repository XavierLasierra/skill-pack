#!/usr/bin/env bash
# skill-pack installer
# Detects installed AI coding tools and injects skills into their config.
# Re-running syncs skills: updates changed, removes deleted, adds new.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$REPO_DIR/skills"
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
SELECTED_SKILLS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --tools)
            SELECTED_TOOLS="$2"
            shift 2
            ;;
        --skills)
            SELECTED_SKILLS="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: install.sh [--tools tool1,tool2] [--skills skill1,skill2]"
            echo ""
            echo "  --tools   comma-separated: claude,gemini,cursor,windsurf,copilot,cline,amp,kiro,roo"
            echo "  --skills  comma-separated skill names, e.g. clean-code,concise (default: all)"
            echo ""
            echo "Examples:"
            echo "  install.sh                              # detect tools, install all skills"
            echo "  install.sh --tools claude,cursor        # force install to these tools only"
            echo "  install.sh --skills concise,clean-code  # install only these skills"
            exit 0
            ;;
        *)
            warn "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------

# Match by basename or full group-relative path (e.g. "clean-code" or "code-quality/clean-code")
skill_selected() {
    local skill_name="$1"
    [[ -z "$SELECTED_SKILLS" ]] && return 0
    local skill_base
    skill_base="$(basename "$skill_name")"
    local list
    list="$(echo "$SELECTED_SKILLS" | tr ',' '\n')"
    echo "$list" | grep -qx "$skill_name" && return 0
    echo "$list" | grep -qx "$skill_base"
}

# Return 0 (true) if the skill's applies_to includes the given tool.
skill_applies_to() {
    local skill_file="$1"
    local tool="$2"

    # No frontmatter → applies to all
    if ! head -1 "$skill_file" | grep -q '^---$'; then
        return 0
    fi

    local applies_line
    applies_line="$(awk 'BEGIN{n=0} /^---$/{n++; if(n==2)exit} n==1 && /applies_to:/{print}' "$skill_file")"

    # No applies_to field → applies to all
    [[ -z "$applies_line" ]] && return 0

    local applies_values
    applies_values="$(echo "$applies_line" | sed 's/.*applies_to:[[:space:]]*//' | tr -d '[]' | tr ',' '\n' | tr -d ' ')"

    echo "$applies_values" | grep -qx "all" && return 0
    echo "$applies_values" | grep -qx "$tool"
}

# Output skill file content with YAML frontmatter stripped.
skill_content() {
    local skill_file="$1"
    if head -1 "$skill_file" | grep -q '^---$'; then
        awk 'BEGIN{n=0; past=0} /^---$/{n++; if(n==2){past=1}; next} past{print}' "$skill_file"
    else
        cat "$skill_file"
    fi
}

# Iterate over all skill files, yielding skill_file and skill_name (group-relative path).
# Usage: each_skill <callback> [extra args...]
# Callback receives: skill_file skill_name [extra args...]
each_skill() {
    local callback="$1"
    shift
    while IFS= read -r skill_file; do
        local skill_name="${skill_file#"$SKILLS_DIR/"}"
        skill_name="${skill_name%.md}"
        skill_selected "$skill_name" || continue
        "$callback" "$skill_file" "$skill_name" "$@"
    done < <(find "$SKILLS_DIR" -name "*.md" | sort)
}

# ------------------------------------------------------------------
# Core: remove / upsert / prune skill blocks in marker-based files
# ------------------------------------------------------------------

# Remove a single skill block identified by key from a target file.
# Guards against missing end marker to avoid eating the rest of the file.
remove_skill_block() {
    local target="$1"
    local key="$2"
    local start="${MARKER_START}${key}"
    local end="${MARKER_END}${key}"

    if ! grep -qF "$start" "$target" 2>/dev/null; then
        return 0
    fi
    if ! grep -qF "$end" "$target" 2>/dev/null; then
        warn "Missing end marker for $key in $(basename "$target") — skipping removal"
        return 1
    fi

    local tmp
    tmp="$(mktemp)"
    awk -v start="$start" -v end="$end" '
        index($0, start) { skip=1; next }
        skip && index($0, end) { skip=0; next }
        !skip { print }
    ' "$target" > "$tmp"
    mv "$tmp" "$target"
}

# Remove skill blocks present in a file but no longer in the repo (or no longer
# applying to the given tool). Skipped on partial --skills installs to avoid
# removing skills the user didn't touch.
prune_stale_skills() {
    local tool="$1"
    local target="$2"

    [[ ! -f "$target" ]] && return 0
    [[ -n "$SELECTED_SKILLS" ]] && return 0

    while IFS= read -r key; do
        local skill_file="$SKILLS_DIR/${key}.md"
        if [[ ! -f "$skill_file" ]] || ! skill_applies_to "$skill_file" "$tool"; then
            if remove_skill_block "$target" "$key"; then
                log "Removed stale: $key → $(basename "$target")"
            fi
        fi
    done < <(grep -F "$MARKER_START" "$target" 2>/dev/null | sed "s|.*${MARKER_START}||")
}

# Upsert a skill block into a target config file.
append_skill() {
    local skill_file="$1"
    local skill_name="$2"
    local tool="$3"
    local target="$4"
    local start="${MARKER_START}${skill_name}"
    local end="${MARKER_END}${skill_name}"

    if ! skill_applies_to "$skill_file" "$tool"; then
        skip "Skipped (not for $tool): $skill_name"
        return
    fi

    mkdir -p "$(dirname "$target")"
    touch "$target"

    local action="Installed"
    if grep -qF "$start" "$target" 2>/dev/null; then
        remove_skill_block "$target" "$skill_name"
        action="Updated"
    fi

    {
        echo ""
        echo "$start"
        skill_content "$skill_file"
        echo ""
        echo "$end"
    } >> "$target"

    log "$action: $skill_name → $(basename "$target")"
}

# ------------------------------------------------------------------
# Per-tool installers
# ------------------------------------------------------------------

_do_append() { append_skill "$1" "$2" "$3" "$4"; }

install_claude_hooks() {
    local hook_src="$REPO_DIR/hooks"
    local hook_dst="$HOME/.skill-pack/hooks"
    local settings="$HOME/.claude/settings.json"

    if ! command -v python3 &>/dev/null; then
        warn "python3 not found — Claude Code hooks skipped"
        return
    fi

    mkdir -p "$hook_dst"
    for hook in session-start user-prompt-submit statusline; do
        cp "$hook_src/${hook}.sh" "$hook_dst/"
        chmod +x "$hook_dst/${hook}.sh"
        log "Installed: ${hook}.sh → $hook_dst"
    done

    python3 - "$hook_dst" "$settings" <<'PYEOF'
import json, os, shlex, sys

hook_dir, settings_path = sys.argv[1], sys.argv[2]

try:
    with open(settings_path) as f:
        settings = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    settings = {}

hooks = settings.setdefault('hooks', {})

to_register = [
    ('SessionStart',     None, f'bash {shlex.quote(hook_dir + "/session-start.sh")}'),
    ('UserPromptSubmit', '',   f'bash {shlex.quote(hook_dir + "/user-prompt-submit.sh")}'),
]

for event, matcher, cmd in to_register:
    event_hooks = hooks.setdefault(event, [])
    already = any(
        any(h.get('command') == cmd for h in entry.get('hooks', []))
        for entry in event_hooks
    )
    if not already:
        entry = {'hooks': [{'type': 'command', 'command': cmd}]}
        if matcher is not None:
            entry['matcher'] = matcher
        event_hooks.append(entry)
        print(f'\033[0;32m✓\033[0m Registered: {event} → {cmd}')
    else:
        print(f'\033[0;90m–\033[0m Already registered: {event}')

statusline_cmd = f'bash {shlex.quote(hook_dir + "/statusline.sh")}'
if settings.get('statusLine', {}).get('command') != statusline_cmd:
    settings['statusLine'] = {'type': 'command', 'command': statusline_cmd}
    print(f'\033[0;32m✓\033[0m Registered: statusLine → {statusline_cmd}')
else:
    print(f'\033[0;90m–\033[0m Already registered: statusLine')

os.makedirs(os.path.dirname(settings_path), exist_ok=True)
with open(settings_path, 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')
PYEOF
}

install_claude_code() {
    local target="$HOME/.claude/CLAUDE.md"
    echo ""
    echo "▸ Claude Code"
    prune_stale_skills "claude" "$target"
    each_skill _do_append "claude" "$target"
    install_claude_hooks
}

install_gemini_cli() {
    local target="$HOME/.gemini/GEMINI.md"
    echo ""
    echo "▸ Gemini CLI"
    prune_stale_skills "gemini" "$target"
    each_skill _do_append "gemini" "$target"
}

_do_cursor() {
    local skill_file="$1" skill_name="$2" rules_dir="$3"
    if ! skill_applies_to "$skill_file" "cursor"; then
        skip "Skipped (not for cursor): $skill_name"
        return
    fi
    local target="$rules_dir/${skill_name//\//-}.mdc"
    {
        echo "---"
        echo "description: skill-pack/${skill_name}"
        echo "alwaysApply: true"
        echo "---"
        skill_content "$skill_file"
    } > "$target"
    log "Installed: $skill_name → $target"
}

prune_cursor_rules() {
    local rules_dir="$1"
    [[ ! -d "$rules_dir" ]] && return 0
    [[ -n "$SELECTED_SKILLS" ]] && return 0

    for f in "$rules_dir"/*.mdc; do
        [[ -f "$f" ]] || continue
        if grep -qF "skill-pack/" "$f" 2>/dev/null; then
            local skill_name
            skill_name="$(grep 'description: skill-pack/' "$f" | sed 's|.*description: skill-pack/||')"
            local skill_file="$SKILLS_DIR/${skill_name}.md"
            if [[ ! -f "$skill_file" ]] || ! skill_applies_to "$skill_file" "cursor"; then
                rm "$f"
                log "Removed stale: $f"
            fi
        fi
    done
}

install_cursor() {
    local rules_dir="$HOME/.cursor/rules"
    mkdir -p "$rules_dir"
    echo ""
    echo "▸ Cursor"
    prune_cursor_rules "$rules_dir"
    each_skill _do_cursor "$rules_dir"
}

install_windsurf() {
    local target="$HOME/.windsurfrules"
    echo ""
    echo "▸ Windsurf"
    prune_stale_skills "windsurf" "$target"
    each_skill _do_append "windsurf" "$target"
}

install_copilot() {
    local target="$REPO_DIR/.github/copilot-instructions.md"
    mkdir -p "$REPO_DIR/.github"
    echo ""
    echo "▸ GitHub Copilot (template — copy .github/copilot-instructions.md to each project)"
    prune_stale_skills "copilot" "$target"
    each_skill _do_append "copilot" "$target"
}

install_cline() {
    local target="$REPO_DIR/.clinerules"
    echo ""
    echo "▸ Cline (template — copy .clinerules to each project)"
    prune_stale_skills "cline" "$target"
    each_skill _do_append "cline" "$target"
}

install_amp() {
    local target="$REPO_DIR/AGENTS.md"
    echo ""
    echo "▸ Amp / Sourcegraph (template — copy AGENTS.md to each project root)"
    prune_stale_skills "amp" "$target"
    each_skill _do_append "amp" "$target"
}

_do_kiro() {
    local skill_file="$1" skill_name="$2" kiro_dir="$3"
    if ! skill_applies_to "$skill_file" "kiro"; then
        skip "Skipped (not for kiro): $skill_name"
        return
    fi
    local target="$kiro_dir/${skill_name//\//-}.md"
    skill_content "$skill_file" > "$target"
    log "Installed: $skill_name → $target"
}

prune_kiro_steering() {
    local kiro_dir="$1"
    [[ ! -d "$kiro_dir" ]] && return 0
    [[ -n "$SELECTED_SKILLS" ]] && return 0

    for f in "$kiro_dir"/*.md; do
        [[ -f "$f" ]] || continue
        local fname
        fname="$(basename "$f")"
        local found=0
        while IFS= read -r skill_file; do
            local skill_name="${skill_file#"$SKILLS_DIR/"}"
            skill_name="${skill_name%.md}"
            if skill_applies_to "$skill_file" "kiro" && [[ "${skill_name//\//-}.md" == "$fname" ]]; then
                found=1
                break
            fi
        done < <(find "$SKILLS_DIR" -name "*.md" | sort)
        if [[ $found -eq 0 ]]; then
            rm "$f"
            log "Removed stale: $f"
        fi
    done
}

install_kiro() {
    local kiro_dir="$REPO_DIR/.kiro/steering"
    mkdir -p "$kiro_dir"
    echo ""
    echo "▸ Kiro / AWS (template — copy .kiro/ to each project root)"
    prune_kiro_steering "$kiro_dir"
    each_skill _do_kiro "$kiro_dir"
}

install_roo() {
    local target="$REPO_DIR/.roorules"
    echo ""
    echo "▸ Roo Code (template — copy .roorules to each project root)"
    prune_stale_skills "roo" "$target"
    each_skill _do_append "roo" "$target"
}

# ------------------------------------------------------------------
# Detection + dispatch
# ------------------------------------------------------------------

detect_and_install() {
    local installed=0

    if [[ -n "$SELECTED_TOOLS" ]]; then
        echo ""
        echo "Target tools: $SELECTED_TOOLS"
        for tool in $(echo "$SELECTED_TOOLS" | tr ',' '\n'); do
            case "$tool" in
                claude)   install_claude_code;  installed=$((installed + 1));;
                gemini)   install_gemini_cli;   installed=$((installed + 1));;
                cursor)   install_cursor;       installed=$((installed + 1));;
                windsurf) install_windsurf;     installed=$((installed + 1));;
                copilot)  install_copilot; installed=$((installed + 1));;
                cline)    install_cline;   installed=$((installed + 1));;
                amp)      install_amp;     installed=$((installed + 1));;
                kiro)     install_kiro;    installed=$((installed + 1));;
                roo)      install_roo;     installed=$((installed + 1));;
                *)        warn "Unknown tool: $tool";;
            esac
        done
    else
        # Auto-detect global tools
        if command -v claude &>/dev/null || [[ -d "$HOME/.claude" ]]; then
            install_claude_code; installed=$((installed + 1))
        else
            skip "Claude Code not found"
        fi

        if command -v gemini &>/dev/null || [[ -d "$HOME/.gemini" ]]; then
            install_gemini_cli; installed=$((installed + 1))
        else
            skip "Gemini CLI not found"
        fi

        if command -v cursor &>/dev/null || [[ -d "$HOME/.cursor" ]] || [[ -d "/Applications/Cursor.app" ]]; then
            install_cursor; installed=$((installed + 1))
        else
            skip "Cursor not found"
        fi

        if command -v windsurf &>/dev/null || [[ -f "$HOME/.windsurfrules" ]] || [[ -d "/Applications/Windsurf.app" ]]; then
            install_windsurf; installed=$((installed + 1))
        else
            skip "Windsurf not found"
        fi

        # Always regenerate project-level templates
        install_copilot
        install_cline
        install_amp
        install_kiro
        install_roo
    fi

    echo ""
    if [[ $installed -eq 0 ]] && [[ -z "$SELECTED_TOOLS" ]]; then
        warn "No AI CLI tools detected. Templates written to repo — copy manually."
    else
        log "Done. Re-run to sync skills. bash uninstall.sh to remove."
    fi
}

echo "skill-pack installer"
echo "===================="
detect_and_install
