#!/usr/bin/env bash
#
# run-all.sh — runs every test in this directory in a deterministic order.
#
# Usage:
#   ./tests/run-all.sh           # run all tests, fail fast on first error
#   ./tests/run-all.sh --keep    # keep going past failures, summary at end
#
set -uo pipefail   # NOTE: not -e; we capture each test's exit code ourselves

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/colors.sh
. "$ROOT_DIR/lib/colors.sh"
# shellcheck source=../lib/log.sh
. "$ROOT_DIR/lib/log.sh"

keep_going=0
for arg in "$@"; do
  case "$arg" in
    --keep|-k) keep_going=1 ;;
    -h|--help)
      sed -n '1,12p' "$0"
      exit 0
      ;;
    *) omac_die "unknown flag: $arg" ;;
  esac
done

# Order matters: cheap → expensive, lint → unit → e2e.
TESTS=(
  lint-skills.sh
  lint-commands.sh
  lint-agents.sh
  lint-plugins.sh
  matrix-artifacts.sh
  unit-frontmatter.sh
  verify-install.sh
  e2e-install.sh
  e2e-omac.sh
  e2e-plugin.sh
)

pass=0; fail=0; skipped=0
declare -a failed_names=()

for t in "${TESTS[@]}"; do
  path="$SCRIPT_DIR/$t"
  if [ ! -x "$path" ] && [ -f "$path" ]; then
    chmod +x "$path"
  fi
  if [ ! -f "$path" ]; then
    omac_log_warn "skipping missing test: $t"
    skipped=$(( skipped + 1 ))
    continue
  fi
  printf "\n%b\n" "$(omac_color_bold "── $t ──")"
  if "$path"; then
    pass=$(( pass + 1 ))
  else
    fail=$(( fail + 1 ))
    failed_names+=("$t")
    if [ "$keep_going" -eq 0 ]; then
      printf "\n"
      omac_log_error "stopping at first failure ($t). Use --keep to continue."
      printf "Summary: %d passed, %d failed, %d skipped\n" "$pass" "$fail" "$skipped"
      exit 1
    fi
  fi
done

printf "\n%b\n" "$(omac_color_bold "── summary ──")"
printf "passed:  %d\n" "$pass"
printf "failed:  %d\n" "$fail"
printf "skipped: %d\n" "$skipped"

if [ "$fail" -gt 0 ]; then
  printf "\nfailed tests:\n"
  for n in "${failed_names[@]}"; do
    printf "  - %s\n" "$n"
  done
  exit 1
fi

omac_log_ok "all $pass test(s) passed"
