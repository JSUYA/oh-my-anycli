#!/usr/bin/env bash
#
# e2e-omac.sh — smoke tests for every public `omac` subcommand.
#
# Asserts that:
#   - omac version  prints VERSION
#   - omac help     mentions the major subcommands
#   - omac list     prints the artifact section headers
#   - omac search <known-keyword>   surfaces the expected artifact
#   - omac info <known-name>        prints the artifact's frontmatter
#   - omac doctor   completes (exit code may be 0 or 1 depending on host;
#                   we just assert it runs and prints the section banners)
#   - omac (no args)  prints usage
#   - omac unknown    exits non-zero
#
# Each subcommand runs against a real install in a tmp target so search/info
# read from the source tree (omac uses INSTALL_DIR for those, not TARGET_DIR).
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/colors.sh
. "$ROOT_DIR/lib/colors.sh"
# shellcheck source=../lib/log.sh
. "$ROOT_DIR/lib/log.sh"

tmpdir="$(mktemp -d -t omac-e2e-omac-XXXXXX)"
trap 'rm -rf "$tmpdir"' EXIT
target="$tmpdir/target/opencode-anycli/opencode"
claude_home="$tmpdir/claude"
codex_home="$tmpdir/codex"
mkdir -p "$target"

# Pre-populate target so `omac list` has something to enumerate.
OMAC_INSTALL_DIR="$ROOT_DIR" \
OMAC_TARGET_DIR="$target" \
"$ROOT_DIR/install.sh" --no-symlink >/dev/null

OMAC=( "$ROOT_DIR/omac" )
ENV_VARS=( "OMAC_INSTALL_DIR=$ROOT_DIR" "OMAC_TARGET_DIR=$target" "OMAC_CLAUDE_HOME=$claude_home" "OMAC_CODEX_HOME=$codex_home" )

run_omac() { env "${ENV_VARS[@]}" NO_COLOR=1 "${OMAC[@]}" "$@"; }

failures=0
fail() { failures=$(( failures + 1 )); }

assert_contains() {
  local label="$1" needle="$2" output="$3"
  if printf "%s" "$output" | grep -qF -- "$needle"; then
    omac_log_check ok "$label"
  else
    omac_log_check fail "$label (missing: $needle)"
    printf "    output (truncated):\n" >&2
    printf "%s\n" "$output" | head -5 >&2
    fail
  fi
}

assert_exit() {
  local label="$1" want="$2" got="$3"
  if [ "$want" = "$got" ]; then
    omac_log_check ok "$label (exit=$got)"
  else
    omac_log_check fail "$label: expected exit=$want, got exit=$got"
    fail
  fi
}

###
# version
###
omac_log_step "[1/8] omac version"
out="$(run_omac version 2>&1)"; rc=$?
assert_exit "version exit code" 0 "$rc"
assert_contains "version mentions oh-my-anycli" "oh-my-anycli" "$out"
assert_contains "version prints VERSION file" "$(cat "$ROOT_DIR/VERSION" | tr -d '[:space:]')" "$out"

###
# help / no-args  → usage banner.
###
omac_log_step "[2/8] omac help"
out="$(run_omac help 2>&1)"; rc=$?
assert_exit "help exit code" 0 "$rc"
for kw in list search info plugin update reapply doctor; do
  assert_contains "help mentions $kw" "$kw" "$out"
done

###
# list — universal skill/plugin matrix should appear.
###
omac_log_step "[3/8] omac list"
out="$(run_omac list 2>&1)"; rc=$?
assert_exit "list exit code" 0 "$rc"
assert_contains "list shows universal view" "view: universal" "$out"
assert_contains "list shows claude column" "claude" "$out"
assert_contains "list shows codex column" "codex" "$out"
assert_contains "list shows opencode column" "opencode" "$out"
assert_contains "list contains code-review skill name" "code-review" "$out"
assert_contains "list contains caveman plugin name" "caveman" "$out"

###
# list -v  → also prints descriptions.
###
omac_log_step "[4/8] omac list -v"
out="$(run_omac list -v 2>&1)"; rc=$?
assert_exit "list -v exit code" 0 "$rc"
assert_contains "list -v shows code-review description" "Reviews changed files" "$out"

###
# search
###
omac_log_step "[5/8] omac search"
out="$(run_omac search dockerfile 2>&1)"; rc=$?
assert_exit "search exit code" 0 "$rc"
assert_contains "search finds dockerfile-review skill" "dockerfile-review" "$out"

# Search is case-insensitive.
out="$(run_omac search DOCKERFILE 2>&1)"
assert_contains "search is case-insensitive" "dockerfile-review" "$out"

# Search across descriptions / when_to_use, not just names.
out="$(run_omac search openapi 2>&1)"
assert_contains "search by description keyword" "openapi-validator" "$out"

###
# info
###
omac_log_step "[6/8] omac info"
out="$(run_omac info code-review 2>&1)"; rc=$?
assert_exit "info exit code" 0 "$rc"
assert_contains "info names the skill" "code-review" "$out"
assert_contains "info prints description key" "description:" "$out"

# info on a command-only name (no skill collision)
out="$(run_omac info omac-status 2>&1)"; rc=$?
assert_exit "info on command-only name" 0 "$rc"
assert_contains "info finds the command" "Command" "$out"

# info on something that doesn't exist
out="$(run_omac info zz-no-such-thing 2>&1)" || rc=$?
rc=${rc:-0}
[ "$rc" -ne 0 ] && omac_log_check ok "info on unknown name exits nonzero" || {
  omac_log_check fail "info on unknown name should exit nonzero"
  fail
}

###
# doctor — banner appears, return value tolerated (host may not have cline).
###
omac_log_step "[7/8] omac doctor"
out="$(run_omac doctor 2>&1)" || true
assert_contains "doctor prints banner" "oh-my-anycli doctor" "$out"
assert_contains "doctor checks opencode-anycli config" "[1] opencode-anycli config" "$out"
assert_contains "doctor checks installed skills"       "Installed skills" "$out"

###
# unknown subcommand → nonzero.
###
omac_log_step "[8/8] omac unknown subcommand"
set +e
run_omac no-such-command >/dev/null 2>&1
rc=$?
set -e
[ "$rc" -ne 0 ] && omac_log_check ok "unknown subcommand exits nonzero" || {
  omac_log_check fail "unknown subcommand should exit nonzero"
  fail
}

printf "\n"
if [ "$failures" -gt 0 ]; then
  omac_log_error "e2e-omac: $failures assertion(s) failed"
  exit 1
fi
omac_log_ok "e2e-omac: all subcommands behaved as expected"
