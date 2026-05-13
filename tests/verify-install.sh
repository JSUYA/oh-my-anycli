#!/usr/bin/env bash
#
# verify-install.sh — smoke-test install.sh in an isolated tmpdir.
#
# Builds a fake opencode-anycli config dir, points install.sh at it, and asserts
# that the expected files appear. Pure bash, no real LLM or cline involved.
#
# Usage:
#   ./tests/verify-install.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/colors.sh
. "$ROOT_DIR/lib/colors.sh"
# shellcheck source=../lib/log.sh
. "$ROOT_DIR/lib/log.sh"

tmpdir="$(mktemp -d -t omac-verify-XXXXXX)"
trap 'rm -rf "$tmpdir"' EXIT

omac_log_step "tmpdir: $tmpdir"

fake_target="$tmpdir/fake-config/opencode-anycli"
mkdir -p "$fake_target"

omac_log_step "running install.sh in isolated target"
OMAC_INSTALL_DIR="$ROOT_DIR" \
OMAC_TARGET_DIR="$fake_target" \
"$ROOT_DIR/install.sh" --no-symlink

# Count expected artifacts in the source tree.
expected_skills=$(find "$ROOT_DIR/skills" -mindepth 2 -name SKILL.md | wc -l | tr -d ' ')
expected_commands=$(find "$ROOT_DIR/commands" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')
expected_agents=$(find "$ROOT_DIR/agents" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')
for plugin_dir in "$ROOT_DIR/plugins"/*/; do
  [ -d "$plugin_dir" ] || continue
  [ "$(basename "$plugin_dir")" = "examples" ] && continue
  [ -f "$plugin_dir/plugin.json" ] || continue
  if [ -d "$plugin_dir/skills" ]; then
    expected_skills=$(( expected_skills + $(find "$plugin_dir/skills" -mindepth 2 -name SKILL.md | wc -l | tr -d ' ') ))
  fi
  if [ -d "$plugin_dir/commands" ]; then
    expected_commands=$(( expected_commands + $(find "$plugin_dir/commands" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ') ))
  fi
  if [ -d "$plugin_dir/agents" ]; then
    expected_agents=$(( expected_agents + $(find "$plugin_dir/agents" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ') ))
  fi
  if [ -d "$plugin_dir/opencode/skills" ]; then
    expected_skills=$(( expected_skills + $(find "$plugin_dir/opencode/skills" -mindepth 2 -name SKILL.md | wc -l | tr -d ' ') ))
  fi
  if [ -d "$plugin_dir/opencode/commands" ]; then
    expected_commands=$(( expected_commands + $(find "$plugin_dir/opencode/commands" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ') ))
  fi
  if [ -d "$plugin_dir/opencode/agents" ]; then
    expected_agents=$(( expected_agents + $(find "$plugin_dir/opencode/agents" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ') ))
  fi
done

# Count actually installed.
actual_skills=$(find "$fake_target/skills" -mindepth 2 -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')
actual_commands=$(find "$fake_target/commands" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
actual_agents=$(find "$fake_target/agents" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' ')

failures=0
check_eq() {
  local label="$1" want="$2" got="$3"
  if [ "$want" = "$got" ]; then
    omac_log_check ok "$label: $got"
  else
    omac_log_check fail "$label: expected $want, got $got"
    failures=$(( failures + 1 ))
  fi
}

check_eq "skills installed"   "$expected_skills"   "$actual_skills"
check_eq "commands installed" "$expected_commands" "$actual_commands"
check_eq "agents installed"   "$expected_agents"   "$actual_agents"

# Idempotency: a second run should not change file count.
omac_log_step "checking idempotent second run"
OMAC_INSTALL_DIR="$ROOT_DIR" \
OMAC_TARGET_DIR="$fake_target" \
"$ROOT_DIR/install.sh" --no-symlink >/dev/null

actual_skills2=$(find "$fake_target/skills" -mindepth 2 -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')
check_eq "skills after re-run" "$actual_skills" "$actual_skills2"

# --reapply path overwrites identical files without error.
omac_log_step "checking --reapply path"
OMAC_INSTALL_DIR="$ROOT_DIR" \
OMAC_TARGET_DIR="$fake_target" \
"$ROOT_DIR/install.sh" --reapply --no-symlink >/dev/null

# Manifest must have been written.
if [ -s "$fake_target/.oh-my-anycli/manifest.txt" ]; then
  omac_log_check ok "manifest written"
else
  omac_log_check fail "manifest missing or empty"
  failures=$(( failures + 1 ))
fi

if [ -f "$fake_target/plugins/caveman.js" ] && [ -f "$fake_target/plugins/caveman-config.cjs" ]; then
  omac_log_check ok "native opencode plugin files installed"
else
  omac_log_check fail "native opencode plugin files missing"
  failures=$(( failures + 1 ))
fi

if grep -Fxq "<!-- caveman-begin -->" "$fake_target/AGENTS.md" 2>/dev/null; then
  omac_log_check ok "managed AGENTS.md caveman block installed"
else
  omac_log_check fail "managed AGENTS.md caveman block missing"
  failures=$(( failures + 1 ))
fi

# Built-in skill content sanity: code-review SKILL.md should include its title.
if grep -q "Code Review Skill" "$fake_target/skills/code-review/SKILL.md" 2>/dev/null; then
  omac_log_check ok "code-review SKILL.md content sanity"
else
  omac_log_check fail "code-review SKILL.md missing or empty"
  failures=$(( failures + 1 ))
fi

printf "\n"
if [ "$failures" -gt 0 ]; then
  omac_log_error "verify-install failed with $failures issue(s)"
  exit 1
fi
omac_log_ok "verify-install passed"
