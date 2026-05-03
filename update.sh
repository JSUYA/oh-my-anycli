#!/usr/bin/env bash
#
# update.sh — pull latest oh-my-anycli and reapply.
#
# Usage:
#   ./update.sh             # git pull --ff-only && ./install.sh --reapply
#   ./update.sh --prune     # also drop stale skills no longer in the repo
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/colors.sh
. "$SCRIPT_DIR/lib/colors.sh"
# shellcheck source=lib/log.sh
. "$SCRIPT_DIR/lib/log.sh"

prune_flag=""
for arg in "$@"; do
  case "$arg" in
    --prune) prune_flag="--prune" ;;
    -h|--help)
      sed -n '3,9p' "$0"
      exit 0
      ;;
    *) omac_log_warn "unknown flag: $arg" ;;
  esac
done

cd "$SCRIPT_DIR"

if [ ! -d ".git" ]; then
  omac_log_warn "No .git directory found; skipping git pull."
else
  omac_log_step "Pulling latest changes"
  git pull --ff-only
fi

omac_log_step "Reapplying installed artifacts"
"$SCRIPT_DIR/install.sh" --reapply ${prune_flag}

omac_log_ok "Update complete"
