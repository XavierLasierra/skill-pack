#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail=0
err() { echo "  ✗ $1"; fail=1; }

frontmatter() { awk 'NR==1 && $0=="---"{f=1;next} f && $0=="---"{exit} f' "$1"; }
has_key() { frontmatter "$1" | grep -qE "^$2:[[:space:]]*"; }

check_targets() {
  local file="$1" line vals v
  line=$(frontmatter "$file" | grep -E '^targets:' || true)
  if [ -z "$line" ]; then err "$file: missing 'targets'"; return; fi
  vals=$(echo "$line" | sed -E 's/.*\[(.*)\].*/\1/' | tr ',' '\n' | tr -d '[:blank:]')
  while IFS= read -r v; do
    [ -z "$v" ] && continue
    case "$v" in
      all|claude|antigravity|opencode) ;;
      *) err "$file: invalid target '$v' (allowed: all, claude, antigravity, opencode)" ;;
    esac
  done <<< "$vals"
}

echo "Validating content/ frontmatter…"

for f in content/skills/*/SKILL.md; do
  [ -e "$f" ] || continue
  has_key "$f" name || err "$f: missing 'name'"
  skill_name=$(frontmatter "$f" | sed -nE 's/^name:[[:space:]]*//p')
  dir_name=$(basename "$(dirname "$f")")
  [ "$skill_name" = "$dir_name" ] || err "$f: name '$skill_name' must equal directory '$dir_name'"
  has_key "$f" description || err "$f: missing 'description'"
  check_targets "$f"
done

for f in content/agents/*.md; do
  [ -e "$f" ] || continue
  has_key "$f" name || err "$f: missing 'name'"
  has_key "$f" description || err "$f: missing 'description'"
  check_targets "$f"
done

for f in content/commands/*.md; do
  [ -e "$f" ] || continue
  has_key "$f" description || err "$f: missing 'description'"
  check_targets "$f"
done

for f in content/rules/*.md; do
  [ -e "$f" ] || continue
  check_targets "$f"
done

echo "Checking [[wiki-links]] resolve…"
item_exists() {
  [ -f "content/skills/$1/SKILL.md" ] || [ -f "content/rules/$1.md" ] \
    || [ -f "content/commands/$1.md" ] || [ -f "content/agents/$1.md" ]
}
# Inline code spans are stripped first so documented placeholders like `[[name]]` are ignored.
while IFS=: read -r file link; do
  target="${link#[[}"; target="${target%]]}"
  item_exists "$target" || err "$file: broken link [[$target]]"
done < <(find content -name '*.md' -exec sh -c 'sed "s/\`[^\`]*\`//g" "$1" | grep -oE "\[\[[a-z0-9-]+\]\]" | sed "s|^|$1:|"' _ {} \;)

echo "Checking README pack table is in sync…"
readme="README.md"
sync_check() {
  grep -qF "\`$1\`" "$readme" || grep -qF "\`/$1\`" "$readme" \
    || err "$readme: $2 '$1' not listed in pack table"
}

for d in content/skills/*/; do [ -e "$d" ] || continue; sync_check "$(basename "$d")" skill; done
for f in content/agents/*.md; do [ -e "$f" ] || continue; sync_check "$(basename "$f" .md)" agent; done
for f in content/commands/*.md; do [ -e "$f" ] || continue; sync_check "$(basename "$f" .md)" command; done
for f in content/rules/*.md; do [ -e "$f" ] || continue; sync_check "$(basename "$f" .md)" rule; done

if [ "$fail" -eq 0 ]; then
  echo "✓ All content valid and README in sync."
else
  echo "Validation failed."
  exit 1
fi
