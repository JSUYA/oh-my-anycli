#!/usr/bin/env bash
#
# lint-agents.sh — verify every agent .md under agents/ (and optional plugin
# subdirectories) conforms to the oh-my-anycli agent contract:
#
#   1. frontmatter contains `name`, `description`, `mode`, `model`
#   2. `name` matches the filename (without .md)
#   3. `model` is `cline/default` (only valid value — see below)
#   4. `mode` is `subagent`, except audited top-level primary agents.
#   5. `tools` (if present) uses the object form (`tools:` followed by indented
#      `key: value` lines), NOT the array form (`tools: [a, b]`). opencode's
#      schema rejects array-form tools with `Expected object | undefined`.
#   6. body is non-empty
#
# WHY model must be `cline/default`:
#   opencode-anycli exposes subagents through cline/default. Other model ids
#   do not match the local routing contract and fail at runtime with
#   NoSuchModelError, so we reject them at install time instead.
#
# Usage:
#   ./tests/lint-agents.sh            # walks ./agents/
#   ./tests/lint-agents.sh <dir>      # walks the given directory's *.md tree
#
# Exits 0 if all agent .md files pass, 1 otherwise.
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

REQUIRED_MODEL="cline/default"
ALL_MODE_AGENTS=( orchestrator )
target_dir="${1:-$ROOT_DIR/agents}"

if [ ! -d "$target_dir" ]; then
  omac_die "agents directory not found: $target_dir"
fi

failures=0
checked=0

is_all_mode_agent() {
  local needle="$1"
  for a in "${ALL_MODE_AGENTS[@]}"; do
    [ "$a" = "$needle" ] && return 0
  done
  return 1
}

while IFS= read -r -d '' agent; do
  checked=$(( checked + 1 ))
  rel="${agent#"$ROOT_DIR/"}"

  # 1. required frontmatter keys
  if ! omac_frontmatter_require "$agent" name description mode model >/dev/null 2>&1; then
    omac_log_check fail "$rel - missing required frontmatter: name, description, mode, model"
    failures=$(( failures + 1 ))
    continue
  fi

  # 2. name must match filename
  expected="$(basename "$agent" .md)"
  actual_name="$(omac_frontmatter_get "$agent" name)"
  if [ "$expected" != "$actual_name" ]; then
    omac_log_check fail "$rel - name='$actual_name' does not match filename '$expected'"
    failures=$(( failures + 1 ))
    continue
  fi

  # 3. model must be cline/default — see header comment for rationale
  actual_model="$(omac_frontmatter_get "$agent" model)"
  if [ "$actual_model" != "$REQUIRED_MODEL" ]; then
    omac_log_check fail "$rel - model='$actual_model' (required: '$REQUIRED_MODEL')"
    failures=$(( failures + 1 ))
    continue
  fi

  # 4. mode must be subagent, except audited top-level primary agents.
  actual_mode="$(omac_frontmatter_get "$agent" mode)"
  case "$actual_mode" in
    subagent) ;;
    all)
      if ! is_all_mode_agent "$expected"; then
        omac_log_check fail "$rel - mode='all' is only allowed for: ${ALL_MODE_AGENTS[*]}"
        failures=$(( failures + 1 ))
        continue
      fi
      ;;
    *)
      omac_log_check fail "$rel - mode='$actual_mode' (required: 'subagent')"
      failures=$(( failures + 1 ))
      continue
      ;;
  esac

  # 5. tools (if present) must be object form, not array form.
  # opencode rejects `tools: [a, b]` with "Expected object | undefined" — only
  # `tools:\n  bash: true\n  read: true` is accepted. Inspect the line that
  # opens the `tools:` key inside the frontmatter.
  tools_violation="$(awk '
    BEGIN { in_fm=0; opened=0; bad=0 }
    NR==1 && $0=="---" { in_fm=1; opened=1; next }
    in_fm && /^---[[:space:]]*$/ { exit }
    in_fm && /^tools:/ {
      # Strip the key, look at the remainder.
      rest=$0
      sub(/^tools:[[:space:]]*/, "", rest)
      # Empty (multi-line object) is OK; "[..." is the array form.
      if (rest ~ /^\[/) { bad=1; exit }
      if (rest != "" && rest !~ /^#/) { bad=1; exit }  # inline non-object value
    }
    END { print bad+0 }
  ' "$agent")"
  if [ "$tools_violation" = "1" ]; then
    omac_log_check fail "$rel - tools must use object form, not array or inline value"
    failures=$(( failures + 1 ))
    continue
  fi

  # 6. body must be non-empty
  body_lines=$(awk '
    BEGIN { in_fm=0; opened=0 }
    NR==1 && $0=="---" { in_fm=1; opened=1; next }
    in_fm && /^---[[:space:]]*$/ { in_fm=0; next }
    !in_fm && opened && NF { count++ }
    END { print count+0 }
  ' "$agent")
  if [ "$body_lines" -lt 5 ]; then
    omac_log_check fail "$rel - body is too short"
    failures=$(( failures + 1 ))
    continue
  fi

  omac_log_check ok "$rel"
done < <(find "$target_dir" -type f -name '*.md' -print0)

printf "\n"
if [ "$checked" -eq 0 ]; then
  omac_log_warn "no agent markdown files found: $target_dir"
  exit 0
fi

if [ "$failures" -gt 0 ]; then
  omac_log_error "$failures / $checked agents failed lint"
  printf "\nAgents must use model: %s\n" "$REQUIRED_MODEL"
  exit 1
fi

omac_log_ok "$checked agents passed lint"
