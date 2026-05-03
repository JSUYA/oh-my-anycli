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

tmpdir="$(mktemp -d -t omc-verify-XXXXXX)"
trap 'rm -rf "$tmpdir"' EXIT

omc_log_step "tmpdir: $tmpdir"

fake_target="$tmpdir/fake-config/opencode-anycli"
mkdir -p "$fake_target"

omc_log_step "running install.sh in isolated target"
OMC_INSTALL_DIR="$ROOT_DIR" \
OMC_TARGET_DIR="$fake_target" \
"$ROOT_DIR/install.sh" --no-symlink

# Count expected artifacts in the source tree.
expected_skills=$(find "$ROOT_DIR/skills" -mindepth 2 -name SKILL.md | wc -l | tr -d ' ')
expected_commands=$(find "$ROOT_DIR/commands" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')
expected_agents=$(find "$ROOT_DIR/agents" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')

# Count actually installed.
actual_skills=$(find "$fake_target/skills" -mindepth 2 -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')
actual_commands=$(find "$fake_target/commands" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
actual_agents=$(find "$fake_target/agents" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' ')

failures=0
check_eq() {
  local label="$1" want="$2" got="$3"
  if [ "$want" = "$got" ]; then
    omc_log_check ok "$label: $got"
  else
    omc_log_check fail "$label: expected $want, got $got"
    failures=$(( failures + 1 ))
  fi
}

check_eq "skills installed"   "$expected_skills"   "$actual_skills"
check_eq "commands installed" "$expected_commands" "$actual_commands"
check_eq "agents installed"   "$expected_agents"   "$actual_agents"

# Idempotency: a second run should not change file count.
omc_log_step "checking idempotent second run"
OMC_INSTALL_DIR="$ROOT_DIR" \
OMC_TARGET_DIR="$fake_target" \
"$ROOT_DIR/install.sh" --no-symlink >/dev/null

actual_skills2=$(find "$fake_target/skills" -mindepth 2 -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')
check_eq "skills after re-run" "$actual_skills" "$actual_skills2"

# --reapply path overwrites identical files without error.
omc_log_step "checking --reapply path"
OMC_INSTALL_DIR="$ROOT_DIR" \
OMC_TARGET_DIR="$fake_target" \
"$ROOT_DIR/install.sh" --reapply --no-symlink >/dev/null

# Manifest must have been written.
if [ -s "$fake_target/.oh-my-anycli/manifest.txt" ]; then
  omc_log_check ok "manifest written"
else
  omc_log_check fail "manifest missing or empty"
  failures=$(( failures + 1 ))
fi

# Built-in skill content sanity: code-review SKILL.md should include its title.
if grep -q "Code Review Skill" "$fake_target/skills/code-review/SKILL.md" 2>/dev/null; then
  omc_log_check ok "code-review SKILL.md content sanity"
else
  omc_log_check fail "code-review SKILL.md missing or empty"
  failures=$(( failures + 1 ))
fi

printf "\n"
if [ "$failures" -gt 0 ]; then
  omc_log_error "verify-install failed with $failures issue(s)"
  exit 1
fi
omc_log_ok "verify-install passed"
