#!/usr/bin/env bash
#
# e2e-selective.sh — exercise target-aware selective skill/plugin install.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/colors.sh
. "$ROOT_DIR/lib/colors.sh"
# shellcheck source=../lib/log.sh
. "$ROOT_DIR/lib/log.sh"

tmpdir="$(mktemp -d -t omac-e2e-selective-XXXXXX)"
trap 'rm -rf "$tmpdir"' EXIT

claude_home="$tmpdir/claude"
codex_home="$tmpdir/codex"
opencode_target="$tmpdir/opencode"
mkdir -p "$claude_home" "$codex_home" "$opencode_target"

ENV_VARS=(
  "OMAC_INSTALL_DIR=$ROOT_DIR"
  "OMAC_CLAUDE_HOME=$claude_home"
  "OMAC_CODEX_HOME=$codex_home"
  "OMAC_TARGET_DIR=$opencode_target"
)
run_omac() { env "${ENV_VARS[@]}" NO_COLOR=1 "$ROOT_DIR/omac" "$@"; }

failures=0
fail() { failures=$(( failures + 1 )); }

assert_contains() {
  local label="$1" needle="$2" output="$3"
  if printf "%s" "$output" | grep -qF -- "$needle"; then
    omac_log_check ok "$label"
  else
    omac_log_check fail "$label (missing: $needle)"
    printf "%s\n" "$output" | head -5 >&2
    fail
  fi
}

omac_log_step "[1/5] universal skill matrix starts missing"
out="$(run_omac skill list --target universal)"
assert_contains "skill list shows universal view" "view: universal" "$out"
assert_contains "skill list shows code-review" "code-review" "$out"
assert_contains "skill list shows target columns" "claude" "$out"
out="$(run_omac skills --target universal list --global)"
assert_contains "target-before-action works" "view: universal" "$out"
out="$(run_omac skill --target claude)"
assert_contains "target claude view works" "view: claude" "$out"

omac_log_step "[2/5] install one skill to one target"
run_omac skill install code-review --target claude >/dev/null
if [ -f "$claude_home/skills/code-review/SKILL.md" ] && [ ! -f "$codex_home/skills/code-review/SKILL.md" ]; then
  omac_log_check ok "code-review installed only to claude"
else
  omac_log_check fail "code-review target selection failed"
  fail
fi
out="$(run_omac skill status code-review --target universal)"
assert_contains "status marks claude active" "claude     active" "$out"
assert_contains "status leaves codex missing" "codex      missing" "$out"

omac_log_step "[3/5] unmanaged collision is not claimed"
mkdir -p "$codex_home/skills/lint-fix"
printf "user-owned\n" > "$codex_home/skills/lint-fix/SKILL.md"
if run_omac skill install lint-fix --target codex >/dev/null 2>&1; then
  omac_log_check fail "unmanaged collision install unexpectedly succeeded"
  fail
else
  omac_log_check ok "unmanaged collision install rejected"
fi
if grep -Fxq "user-owned" "$codex_home/skills/lint-fix/SKILL.md"; then
  omac_log_check ok "unmanaged collision content preserved"
else
  omac_log_check fail "unmanaged collision content overwritten"
  fail
fi
run_omac skill remove lint-fix --target codex >/dev/null
if [ -f "$codex_home/skills/lint-fix/SKILL.md" ]; then
  omac_log_check ok "remove leaves unmanaged collision file"
else
  omac_log_check fail "remove deleted unmanaged collision file"
  fail
fi

omac_log_step "[4/5] remove managed skill"
run_omac skill remove code-review --target claude >/dev/null
if [ ! -f "$claude_home/skills/code-review/SKILL.md" ]; then
  omac_log_check ok "managed skill removed"
else
  omac_log_check fail "managed skill still present"
  fail
fi

omac_log_step "[5/5] selected plugin install/remove"
run_omac plugin install caveman --target opencode >/dev/null
if [ -f "$opencode_target/plugins/caveman.js" ] && grep -q "caveman.js" "$opencode_target/opencode.json"; then
  omac_log_check ok "caveman opencode plugin installed and registered"
else
  omac_log_check fail "caveman opencode plugin not installed"
  fail
fi
out="$(run_omac plugin list --target universal)"
assert_contains "plugin list marks opencode active" "caveman                  missing    missing    active" "$out"
run_omac plugin remove caveman --target opencode >/dev/null
if [ ! -f "$opencode_target/plugins/caveman.js" ] && ! grep -q "caveman.js" "$opencode_target/opencode.json" 2>/dev/null; then
  omac_log_check ok "caveman opencode plugin removed and unregistered"
else
  omac_log_check fail "caveman opencode plugin removal incomplete"
  fail
fi

printf "\n"
if [ "$failures" -gt 0 ]; then
  omac_log_error "e2e-selective: $failures assertion(s) failed"
  exit 1
fi
omac_log_ok "e2e-selective: all selective lifecycle steps passed"
