#!/usr/bin/env bash
#
# lint-skills.sh — verify every SKILL.md under skills/ has required frontmatter.
#
# Usage:
#   ./tests/lint-skills.sh            # walks ./skills/
#   ./tests/lint-skills.sh <dir>      # walks the given directory's *.md tree
#
# Exits 0 if all SKILL.md files have `name` and `description` keys, 1 otherwise.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/colors.sh
. "$ROOT_DIR/lib/colors.sh"
# shellcheck source=../lib/log.sh
. "$ROOT_DIR/lib/log.sh"
# shellcheck source=../lib/common.sh
. "$ROOT_DIR/lib/common.sh"

target_dir="${1:-$ROOT_DIR/skills}"

if [ ! -d "$target_dir" ]; then
  omac_die "skills directory not found: $target_dir"
fi

failures=0
checked=0

while IFS= read -r -d '' skill; do
  checked=$(( checked + 1 ))
  rel="${skill#"$ROOT_DIR/"}"
  if ! omac_frontmatter_require "$skill" name description >/dev/null 2>&1; then
    omac_log_check fail "$rel - missing required frontmatter: name and description"
    failures=$(( failures + 1 ))
    continue
  fi

  # Verify name == directory name.
  expected="$(basename "$(dirname "$skill")")"
  actual="$(omac_frontmatter_get "$skill" name)"
  if [ "$expected" != "$actual" ]; then
    omac_log_check fail "$rel - name='$actual' does not match directory '$expected'"
    failures=$(( failures + 1 ))
    continue
  fi

  # Verify body is non-empty.
  body_lines=$(awk '
    BEGIN { in_fm=0; opened=0 }
    NR==1 && $0=="---" { in_fm=1; opened=1; next }
    in_fm && /^---[[:space:]]*$/ { in_fm=0; next }
    !in_fm && opened && NF { count++ }
    END { print count+0 }
  ' "$skill")
  if [ "$body_lines" -lt 5 ]; then
    omac_log_check fail "$rel - body is too short"
    failures=$(( failures + 1 ))
    continue
  fi

  omac_log_check ok "$rel"
done < <(find "$target_dir" -type f -name SKILL.md -print0)

printf "\n"
if [ "$checked" -eq 0 ]; then
  omac_log_warn "no SKILL.md files found: $target_dir"
  exit 0
fi

if [ "$failures" -gt 0 ]; then
  omac_log_error "$failures / $checked skills failed lint"
  exit 1
fi

omac_log_ok "$checked skills passed lint"
