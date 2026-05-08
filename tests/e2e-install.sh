#!/usr/bin/env bash
#
# e2e-install.sh — end-to-end test of the install / reapply / prune /
# uninstall lifecycle against an isolated tmp config directory.
#
# Asserts:
#   - install.sh copies every skill/command/agent
#   - install.sh records every copied file in manifest.txt
#   - re-running install.sh is idempotent (no spurious changes)
#   - --force / --reapply overwrites a tampered file
#   - existing user-authored files are NOT clobbered without --force
#   - --prune removes artifacts that disappear from the source tree
#   - uninstall.sh only removes manifest-tracked files (preserves user files)
#
# Pure bash, no real LLM. Run from the repository root or anywhere — paths
# are resolved relative to this script.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/colors.sh
. "$ROOT_DIR/lib/colors.sh"
# shellcheck source=../lib/log.sh
. "$ROOT_DIR/lib/log.sh"

tmpdir="$(mktemp -d -t omac-e2e-install-XXXXXX)"
trap 'rm -rf "$tmpdir"' EXIT

target="$tmpdir/target/opencode-anycli/opencode"
mkdir -p "$target"

failures=0
fail() { failures=$(( failures + 1 )); }

run_install() {
  OMAC_INSTALL_DIR="$ROOT_DIR" \
  OMAC_TARGET_DIR="$target" \
  "$ROOT_DIR/install.sh" --no-symlink "$@" >/dev/null
}

run_uninstall() {
  OMAC_INSTALL_DIR="$ROOT_DIR" \
  OMAC_TARGET_DIR="$target" \
  "$ROOT_DIR/uninstall.sh" --yes --no-symlink "$@" >/dev/null
}

count() { find "$1" -mindepth "${2:-1}" -name "${3:-*}" -type f 2>/dev/null | wc -l | tr -d ' '; }

###
# 1. First install.
###
omac_log_step "[1/7] first install"
run_install
expected_skills=$(find "$ROOT_DIR/skills" -mindepth 2 -name SKILL.md | wc -l | tr -d ' ')
expected_commands=$(find "$ROOT_DIR/commands" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')
expected_agents=$(find "$ROOT_DIR/agents" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')

actual_skills=$(count "$target/skills" 2 SKILL.md)
actual_commands=$(count "$target/commands" 1 '*.md')
actual_agents=$(count "$target/agents" 1 '*.md')

if [ "$actual_skills" = "$expected_skills" ]; then
  omac_log_check ok "skills installed ($actual_skills)"
else
  omac_log_check fail "skills: expected $expected_skills, got $actual_skills"
  fail
fi
if [ "$actual_commands" = "$expected_commands" ]; then
  omac_log_check ok "commands installed ($actual_commands)"
else
  omac_log_check fail "commands: expected $expected_commands, got $actual_commands"
  fail
fi
if [ "$actual_agents" = "$expected_agents" ]; then
  omac_log_check ok "agents installed ($actual_agents)"
else
  omac_log_check fail "agents: expected $expected_agents, got $actual_agents"
  fail
fi

if [ -s "$target/.oh-my-anycli/manifest.txt" ]; then
  omac_log_check ok "manifest written"
else
  omac_log_check fail "manifest missing or empty"
  fail
fi

###
# 2. Idempotency — re-run yields exact same file set.
###
omac_log_step "[2/7] idempotent re-install"
hash_before=$(find "$target" -type f -name '*.md' | sort | xargs cat | md5sum | cut -d' ' -f1)
run_install
hash_after=$(find "$target" -type f -name '*.md' | sort | xargs cat | md5sum | cut -d' ' -f1)
if [ "$hash_before" = "$hash_after" ]; then
  omac_log_check ok "second install changed nothing"
else
  omac_log_check fail "second install changed file contents"
  fail
fi

###
# 3. Tamper + default install: existing different content is PRESERVED.
###
omac_log_step "[3/7] tamper + default install must preserve user changes"
review="$target/commands/review.md"
echo "# user-edit" >> "$review"
tampered_hash=$(md5sum "$review" | cut -d' ' -f1)
run_install
if [ "$(md5sum "$review" | cut -d' ' -f1)" = "$tampered_hash" ]; then
  omac_log_check ok "tampered file preserved without --force"
else
  omac_log_check fail "tampered file overwritten (should require --force)"
  fail
fi

###
# 4. --reapply (= --force) overwrites the tampered file.
###
omac_log_step "[4/7] --reapply overwrites tampered file"
run_install --reapply
src_hash=$(md5sum "$ROOT_DIR/commands/review.md" | cut -d' ' -f1)
new_hash=$(md5sum "$review" | cut -d' ' -f1)
if [ "$src_hash" = "$new_hash" ]; then
  omac_log_check ok "tampered file restored from source"
else
  omac_log_check fail "tampered file did not match source after --reapply"
  fail
fi

###
# 5. User-authored file (not in manifest) is preserved through reapply.
###
omac_log_step "[5/7] user-authored file untouched by reapply"
custom="$target/commands/my-private-cmd.md"
cat > "$custom" <<'EOF'
---
description: User's private command, not part of upstream.
---
custom body
EOF
run_install --reapply
if [ -f "$custom" ]; then
  omac_log_check ok "user file survived reapply"
else
  omac_log_check fail "user file deleted by reapply"
  fail
fi

###
# 6. --prune removes artifacts that no longer exist in the source tree.
#    We simulate "removed upstream" by introducing a stale entry into the
#    target dir and a corresponding line in the manifest, then running
#    install --prune. The stale entry must disappear; the user file from
#    step 5 must NOT.
###
omac_log_step "[6/7] --prune removes stale tracked artifacts only"
stale="$target/commands/stale-from-upstream.md"
cat > "$stale" <<'EOF'
---
description: simulated upstream artifact that was later removed.
---
EOF
# Append to manifest so install.sh believes it owns this file.
echo "$stale" >> "$target/.oh-my-anycli/manifest.txt"
run_install --prune
if [ -f "$stale" ]; then
  omac_log_check fail "--prune did not remove stale tracked file"
  fail
else
  omac_log_check ok "--prune removed stale tracked file"
fi
if [ -f "$custom" ]; then
  omac_log_check ok "user file preserved through --prune"
else
  omac_log_check fail "--prune ate the user file"
  fail
fi

###
# 7. Uninstall — manifest-tracked files gone, user file preserved.
###
omac_log_step "[7/7] uninstall preserves user files"
run_uninstall
if [ -f "$target/commands/review.md" ]; then
  omac_log_check fail "uninstall left a tracked file behind"
  fail
else
  omac_log_check ok "tracked files removed"
fi
if [ -f "$custom" ]; then
  omac_log_check ok "user file preserved through uninstall"
else
  omac_log_check fail "uninstall removed user file"
  fail
fi

printf "\n"
if [ "$failures" -gt 0 ]; then
  omac_log_error "e2e-install: $failures step(s) failed"
  exit 1
fi
omac_log_ok "e2e-install: all 7 lifecycle steps passed"
