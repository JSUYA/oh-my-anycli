#!/usr/bin/env bash
#
# matrix-artifacts.sh — verify cross-artifact integrity invariants:
#
#   1. Every commands/<name>.md routes to a real skill (via routes_to_skill
#      frontmatter), OR is explicitly allow-listed as a CLI-only command.
#   2. Every skills/<name>/SKILL.md has a `name` matching its directory.
#   3. Every agents/<name>.md has a `name` matching its filename and
#      model = cline/default.
#   4. There are no duplicate `name:` values across skills.
#   5. There are no duplicate filenames across commands or agents.
#   6. Frontmatter `description` is non-trivial (>= 30 characters) for
#      every skill — this is the field used by `omac search`.
#
# This sits ABOVE the per-artifact lint scripts: it catches contradictions
# between artifacts that the per-file lint cannot see.
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

# Commands that intentionally do not route to a skill (they invoke the omac
# CLI directly). Keep this list short and audited.
CLI_ONLY_COMMANDS=( omac-status )

is_cli_only() {
  local needle="$1"
  for c in "${CLI_ONLY_COMMANDS[@]}"; do
    [ "$c" = "$needle" ] && return 0
  done
  return 1
}

failures=0
fail() { failures=$(( failures + 1 )); }

###
# 1. command → skill mapping
###
omac_log_step "[1/6] command-to-skill mapping"
mapped=0; cli_only=0
while IFS= read -r -d '' cmd_file; do
  cmd_name="$(basename "$cmd_file" .md)"
  skill="$(omac_frontmatter_get "$cmd_file" routes_to_skill || true)"
  if is_cli_only "$cmd_name"; then
    if [ -n "$skill" ]; then
      omac_log_check fail "$cmd_name: CLI-only command must NOT set routes_to_skill"
      fail
    else
      cli_only=$(( cli_only + 1 ))
    fi
    continue
  fi
  if [ -z "$skill" ]; then
    omac_log_check fail "$cmd_name: missing routes_to_skill (and not in CLI allow-list)"
    fail
    continue
  fi
  if [ ! -f "$ROOT_DIR/skills/$skill/SKILL.md" ]; then
    omac_log_check fail "$cmd_name routes_to_skill='$skill' — skill not found"
    fail
    continue
  fi
  mapped=$(( mapped + 1 ))
done < <(find "$ROOT_DIR/commands" -maxdepth 1 -name '*.md' -print0)
omac_log_check ok "$mapped commands routed to a skill, $cli_only CLI-only"

###
# 2. skill name == directory name
###
omac_log_step "[2/6] skill name matches directory"
skill_count=0
declare -A SKILL_NAMES=()
while IFS= read -r -d '' f; do
  skill_count=$(( skill_count + 1 ))
  dir_name="$(basename "$(dirname "$f")")"
  fm_name="$(omac_frontmatter_get "$f" name || true)"
  if [ "$dir_name" != "$fm_name" ]; then
    omac_log_check fail "skills/$dir_name name mismatch: frontmatter='$fm_name'"
    fail
    continue
  fi
  if [ -n "${SKILL_NAMES[$fm_name]:-}" ]; then
    omac_log_check fail "duplicate skill name: $fm_name"
    fail
    continue
  fi
  SKILL_NAMES[$fm_name]=1
done < <(find "$ROOT_DIR/skills" -mindepth 2 -name SKILL.md -print0)
omac_log_check ok "$skill_count skills checked"

###
# 3. agent name + model
###
omac_log_step "[3/6] agent name + model"
agent_count=0
declare -A AGENT_NAMES=()
while IFS= read -r -d '' f; do
  agent_count=$(( agent_count + 1 ))
  base="$(basename "$f" .md)"
  fm_name="$(omac_frontmatter_get "$f" name || true)"
  fm_model="$(omac_frontmatter_get "$f" model || true)"
  if [ "$base" != "$fm_name" ]; then
    omac_log_check fail "agents/$base name mismatch: frontmatter='$fm_name'"
    fail
  fi
  if [ "$fm_model" != "cline/default" ]; then
    omac_log_check fail "agents/$base model='$fm_model' (must be cline/default)"
    fail
  fi
  if [ -n "${AGENT_NAMES[$fm_name]:-}" ]; then
    omac_log_check fail "duplicate agent name: $fm_name"
    fail
  fi
  AGENT_NAMES[$fm_name]=1
done < <(find "$ROOT_DIR/agents" -maxdepth 1 -name '*.md' -print0)
omac_log_check ok "$agent_count agents checked"

###
# 4. duplicate command filenames (case-insensitive — Mac filesystems collapse)
###
omac_log_step "[4/6] duplicate command filenames"
dup_lines="$(find "$ROOT_DIR/commands" -maxdepth 1 -name '*.md' -printf '%f\n' \
             | tr '[:upper:]' '[:lower:]' \
             | sort | uniq -d)"
if [ -n "$dup_lines" ]; then
  printf "%s\n" "$dup_lines" | while IFS= read -r d; do
    omac_log_check fail "duplicate command filename (case-insensitive): $d"
  done
  fail
else
  omac_log_check ok "no duplicate command filenames"
fi

###
# 5. duplicate agent filenames
###
omac_log_step "[5/6] duplicate agent filenames"
dup_lines="$(find "$ROOT_DIR/agents" -maxdepth 1 -name '*.md' -printf '%f\n' \
             | tr '[:upper:]' '[:lower:]' \
             | sort | uniq -d)"
if [ -n "$dup_lines" ]; then
  printf "%s\n" "$dup_lines" | while IFS= read -r d; do
    omac_log_check fail "duplicate agent filename (case-insensitive): $d"
  done
  fail
else
  omac_log_check ok "no duplicate agent filenames"
fi

###
# 6. skill descriptions are non-trivial
###
omac_log_step "[6/6] skill descriptions are non-trivial (>= 30 chars)"
short_count=0
while IFS= read -r -d '' f; do
  desc="$(omac_frontmatter_get "$f" description || true)"
  if [ ${#desc} -lt 30 ]; then
    rel="${f#"$ROOT_DIR/"}"
    omac_log_check fail "$rel: description too short (${#desc} chars)"
    short_count=$(( short_count + 1 ))
    fail
  fi
done < <(find "$ROOT_DIR/skills" -mindepth 2 -name SKILL.md -print0)
[ "$short_count" -eq 0 ] && omac_log_check ok "all skill descriptions are >= 30 chars"

printf "\n"
if [ "$failures" -gt 0 ]; then
  omac_log_error "matrix-artifacts: $failures invariant(s) violated"
  exit 1
fi
omac_log_ok "matrix-artifacts: all invariants hold"
