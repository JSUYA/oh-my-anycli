#!/usr/bin/env bash
#
# lint-plugins.sh — verify every plugin under plugins/<name>/ has a valid
# plugin.json and that any skills/commands/agents inside the plugin pass the
# same checks as top-level artifacts.
#
# Usage:
#   ./tests/lint-plugins.sh
#   ./tests/lint-plugins.sh <plugins-dir>
#
# Exits 0 if every plugin is well-formed, 1 otherwise.
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

target_dir="${1:-$ROOT_DIR/plugins}"

if [ ! -d "$target_dir" ]; then
  omac_die "plugins directory not found: $target_dir"
fi

failures=0
plugins_seen=0

# A "plugin" is any direct child directory of plugins/ that contains
# plugin.json, EXCEPT the bundled examples/ directory which we recurse into.
walk_plugin() {
  local plugin_dir="$1"
  local rel="${plugin_dir#"$ROOT_DIR/"}"
  plugins_seen=$(( plugins_seen + 1 ))

  # 1. plugin.json must exist and contain at least name + version.
  local manifest="$plugin_dir/plugin.json"
  if [ ! -f "$manifest" ]; then
    omac_log_check fail "$rel - missing plugin.json"
    failures=$(( failures + 1 ))
    return
  fi
  if ! grep -q '"name"' "$manifest"; then
    omac_log_check fail "$rel/plugin.json - missing \"name\" field"
    failures=$(( failures + 1 ))
    return
  fi
  if ! grep -q '"version"' "$manifest"; then
    omac_log_check fail "$rel/plugin.json - missing \"version\" field"
    failures=$(( failures + 1 ))
    return
  fi

  omac_log_check ok "$rel/plugin.json"

  # 2. plugin's skills/ and agents/ must pass the standard lints.
  if [ -d "$plugin_dir/skills" ]; then
    if ! "$ROOT_DIR/tests/lint-skills.sh" "$plugin_dir/skills" >/dev/null 2>&1; then
      omac_log_check fail "$rel/skills/ - lint-skills failed"
      failures=$(( failures + 1 ))
    else
      omac_log_check ok "$rel/skills/ (lint-skills)"
    fi
  fi
  if [ -d "$plugin_dir/agents" ]; then
    if ! "$ROOT_DIR/tests/lint-agents.sh" "$plugin_dir/agents" >/dev/null 2>&1; then
      omac_log_check fail "$rel/agents/ - lint-agents failed"
      failures=$(( failures + 1 ))
    else
      omac_log_check ok "$rel/agents/ (lint-agents)"
    fi
  fi
  if [ -d "$plugin_dir/commands" ]; then
    if ! "$ROOT_DIR/tests/lint-commands.sh" "$plugin_dir/commands" >/dev/null 2>&1; then
      omac_log_check fail "$rel/commands/ - lint-commands failed"
      failures=$(( failures + 1 ))
    else
      omac_log_check ok "$rel/commands/ (lint-commands)"
    fi
  fi
}

# Top-level plugins (skip examples/ directory itself, but walk into its
# children — the example plugin is intentionally tested too).
for d in "$target_dir"/*/; do
  [ -d "$d" ] || continue
  name="$(basename "$d")"
  case "$name" in
    examples)
      for sub in "$d"*/; do
        [ -d "$sub" ] || continue
        walk_plugin "$sub"
      done
      ;;
    *)
      walk_plugin "$d"
      ;;
  esac
done

printf "\n"
if [ "$plugins_seen" -eq 0 ]; then
  omac_log_warn "no plugins found under $target_dir"
  exit 0
fi

if [ "$failures" -gt 0 ]; then
  omac_log_error "$failures issue(s) across $plugins_seen plugin(s)"
  exit 1
fi

omac_log_ok "$plugins_seen plugin(s) passed lint"
