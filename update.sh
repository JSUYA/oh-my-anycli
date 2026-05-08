#!/usr/bin/env bash
#
# update.sh — pull latest oh-my-anycli and reapply.
#
# Usage:
#   ./update.sh                # auto-stash dirty tree → pull --ff-only → reapply → pop
#   ./update.sh --prune        # also drop stale skills no longer in the repo
#   ./update.sh --no-stash     # skip auto-stash; abort if working tree is dirty
#
# Auto-stash behavior:
#   If the working tree has uncommitted changes (tracked or untracked, but NOT
#   .gitignore'd files), they are stashed before `git pull --ff-only`. After a
#   successful reapply, the stash is popped automatically. If pull/install
#   fails, the stash is also popped so the tree is restored. If the pop itself
#   conflicts, the stash is kept in `git stash list` for manual resolution.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/colors.sh
. "$SCRIPT_DIR/lib/colors.sh"
# shellcheck source=lib/log.sh
. "$SCRIPT_DIR/lib/log.sh"

prune_flag=""
no_stash=0
for arg in "$@"; do
  case "$arg" in
    --prune)    prune_flag="--prune" ;;
    --no-stash) no_stash=1 ;;
    -h|--help)
      sed -n '3,15p' "$0"
      exit 0
      ;;
    *) omac_log_warn "unknown flag: $arg" ;;
  esac
done

cd "$SCRIPT_DIR"

stashed=0
on_exit() {
  local rc=$?
  if [ "$stashed" = "1" ]; then
    if [ "$rc" -ne 0 ]; then
      omac_log_warn "Update aborted; attempting to restore stashed changes."
    else
      omac_log_step "Restoring stashed changes"
    fi
    if git stash pop; then
      omac_log_ok "Stash restored cleanly"
    else
      omac_log_warn "git stash pop had conflicts; your changes remain in 'git stash list' — resolve manually."
    fi
  fi
  exit "$rc"
}
trap on_exit EXIT

if [ ! -d ".git" ]; then
  omac_log_warn "No .git directory found; skipping git pull."
else
  if [ -n "$(git status --porcelain)" ]; then
    if [ "$no_stash" = "1" ]; then
      omac_die "working tree dirty and --no-stash set; commit or drop changes first"
    fi
    stash_msg="omac update auto-stash $(date +%Y-%m-%dT%H:%M:%S)"
    omac_log_step "Stashing local changes: $stash_msg"
    git stash push --include-untracked -m "$stash_msg"
    stashed=1
  fi

  omac_log_step "Pulling latest changes"
  git pull --ff-only
fi

omac_log_step "Reapplying installed artifacts"
"$SCRIPT_DIR/install.sh" --reapply ${prune_flag}

omac_log_ok "Update complete"
