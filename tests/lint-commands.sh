#!/usr/bin/env bash
#
# lint-commands.sh — verify every command markdown has required frontmatter.
#
# Usage:
#   ./tests/lint-commands.sh           # walks ./commands/
#   ./tests/lint-commands.sh <dir>     # walks the given directory's *.md
#
# Exits 0 if all command md files have a `description` key, 1 otherwise.
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

target_dir="${1:-$ROOT_DIR/commands}"

if [ ! -d "$target_dir" ]; then
  omc_die "commands directory not found: $target_dir"
fi

failures=0
checked=0

while IFS= read -r -d '' cmd; do
  checked=$(( checked + 1 ))
  rel="${cmd#"$ROOT_DIR/"}"

  if ! omc_frontmatter_require "$cmd" description >/dev/null 2>&1; then
    omc_log_check fail "$rel - missing required frontmatter: description"
    failures=$(( failures + 1 ))
    continue
  fi

  # Body must contain the <command-instruction> block (loose check) or at least
  # 2 non-empty lines.
  body_lines=$(awk '
    BEGIN { in_fm=0; opened=0 }
    NR==1 && $0=="---" { in_fm=1; opened=1; next }
    in_fm && /^---[[:space:]]*$/ { in_fm=0; next }
    !in_fm && opened && NF { count++ }
    END { print count+0 }
  ' "$cmd")
  if [ "$body_lines" -lt 2 ]; then
    omc_log_check fail "$rel - body is too short"
    failures=$(( failures + 1 ))
    continue
  fi

  omc_log_check ok "$rel"
done < <(find "$target_dir" -maxdepth 1 -type f -name '*.md' -print0)

printf "\n"
if [ "$checked" -eq 0 ]; then
  omc_log_warn "no command markdown files found: $target_dir"
  exit 0
fi

if [ "$failures" -gt 0 ]; then
  omc_log_error "$failures / $checked commands failed lint"
  exit 1
fi

omc_log_ok "$checked commands passed lint"
