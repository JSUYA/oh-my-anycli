#!/usr/bin/env bash
#
# uninstall.sh — remove what install.sh placed on this machine.
#
# Strategy: manifest-based. install.sh tracks every file it copies into
# `<target>/.oh-my-anycli/manifest.txt`. We remove only those files,
# never anything else — so user-authored skills/commands/agents in the
# same target directory are safe.
#
# What this removes:
#   1. The `omac` symlink in /usr/local/bin or ~/.local/bin
#   2. Every file listed in the manifest (skills/commands/agents that
#      install.sh copied)
#   3. The manifest file itself
#   4. Empty parent directories (skills/<name>/, commands/, agents/)
#      that we own and that have no other files left
#
# What this does NOT touch:
#   - Files in target/{commands,agents,skills}/ that are NOT in our manifest
#     (someone else, or the user, put them there)
#   - Plugins under <install_dir>/plugins/
#   - The install_dir (~/.oh-my-anycli) — pass --remove-install-dir to remove
#   - The user's opencode-anycli wrapper config (opencode.json)
#
# Usage:
#   ./uninstall.sh                       # symlink + manifested files only
#   ./uninstall.sh --remove-install-dir  # also delete the cloned repo dir
#   ./uninstall.sh --user                # symlink scope (default: auto)
#   ./uninstall.sh --system              # symlink scope (sudo if needed)
#   ./uninstall.sh --sudo                # use sudo when removing system bin
#   ./uninstall.sh --no-symlink          # skip symlink removal entirely
#                                        # (useful for testing or partial uninstall)
#   ./uninstall.sh --yes                 # skip confirmation prompts
#   ./uninstall.sh -h | --help           # this help
#
# Environment:
#   OMAC_TARGET_DIR   override the opencode-anycli config dir we clean from
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/colors.sh
. "$SCRIPT_DIR/lib/colors.sh"
# shellcheck source=lib/log.sh
. "$SCRIPT_DIR/lib/log.sh"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

remove_install_dir=0
scope="auto"   # auto | user | system | none
use_sudo=0
assume_yes=0

while [ $# -gt 0 ]; do
  case "$1" in
    --remove-install-dir) remove_install_dir=1 ;;
    --user)               scope="user" ;;
    --system)             scope="system" ;;
    --no-symlink)         scope="none" ;;
    --sudo)               use_sudo=1 ;;
    --yes|-y)             assume_yes=1 ;;
    -h|--help)
      sed -n '3,37p' "$0"; exit 0 ;;
    *) omac_die "unknown flag: $1" ;;
  esac
  shift
done

INSTALL_DIR="${OMAC_INSTALL_DIR:-$SCRIPT_DIR}"
TARGET_DIR="$(omac_target_dir)"

confirm() {
  if [ "$assume_yes" = "1" ]; then return 0; fi
  printf "${OMAC_COLOR_YELLOW:-}?${OMAC_COLOR_RESET:-} %s [y/N] " "$1"
  read -r reply
  case "$reply" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

# ─── 1. Remove omac symlink ────────────────────────────────────────────────────
if [ "$scope" = "none" ]; then
  omac_log_step "Skipping omac symlink removal (--no-symlink)"
  targets=("__SKIP__")
else
  omac_log_step "Removing omac symlink"
  case "$scope" in
    user)   targets=("$HOME/.local/bin/omac") ;;
    system) targets=("/usr/local/bin/omac") ;;
    auto)   targets=("/usr/local/bin/omac" "$HOME/.local/bin/omac") ;;
  esac
fi
for t in "${targets[@]}"; do
  [ "$t" = "__SKIP__" ] && continue
  if [ -L "$t" ]; then
    if [ -w "$(dirname "$t")" ]; then
      rm "$t"
      omac_log_ok "removed symlink $t"
    elif [ "$use_sudo" = "1" ]; then
      sudo rm "$t"
      omac_log_ok "removed symlink $t (sudo)"
    else
      omac_log_warn "no write permission for $(dirname "$t"). Re-run with --sudo to remove $t."
    fi
  elif [ -e "$t" ]; then
    omac_log_warn "$t exists but is not a symlink — leaving it alone."
  else
    omac_log_info "no symlink at $t (already removed)"
  fi
done

# ─── 2. Read manifest and remove our files ────────────────────────────────────
manifest="$TARGET_DIR/.oh-my-anycli/manifest.txt"
omac_log_step "Removing files listed in the install manifest"
omac_log_info "target dir : $TARGET_DIR"
omac_log_info "manifest   : $manifest"

if [ ! -f "$manifest" ]; then
  omac_log_warn "manifest not found — nothing to remove from $TARGET_DIR."
  omac_log_warn "  (Already uninstalled, or OMAC_TARGET_DIR differs from the install.sh run.)"
else
  removed=0
  missing=0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if [ -f "$f" ]; then
      rm -f "$f"
      removed=$((removed+1))
    else
      missing=$((missing+1))
    fi
  done < "$manifest"

  omac_log_ok "removed $removed file(s)$([ "$missing" -gt 0 ] && printf ", %d already missing" "$missing")"

  # Clean up empty skill subdirectories (skills/<name>/ where SKILL.md was the only file).
  if [ -d "$TARGET_DIR/skills" ]; then
    for d in "$TARGET_DIR/skills"/*/; do
      [ -d "$d" ] || continue
      if [ -z "$(ls -A "$d" 2>/dev/null)" ]; then
        rmdir "$d"
      fi
    done
  fi

  # Remove now-empty manifest directory.
  rm -f "$manifest"
  rmdir "$TARGET_DIR/.oh-my-anycli" 2>/dev/null || true

  # Optionally remove now-empty top-level dirs (commands/, agents/, skills/) — only if empty.
  for sub in commands agents skills; do
    d="$TARGET_DIR/$sub"
    if [ -d "$d" ] && [ -z "$(ls -A "$d" 2>/dev/null)" ]; then
      rmdir "$d"
      omac_log_ok "removed empty $d"
    elif [ -d "$d" ]; then
      omac_log_info "kept $d (still contains files not from oh-my-anycli)"
    fi
  done
fi

# ─── 3. Optionally remove the install dir itself ──────────────────────────────
if [ "$remove_install_dir" = "1" ]; then
  omac_log_step "Removing install directory $INSTALL_DIR"
  if [ -d "$INSTALL_DIR" ]; then
    if confirm "Delete $INSTALL_DIR, including this script and the git checkout?"; then
      # Delete from outside the directory to avoid `rm` operating on its own cwd.
      ( cd / && rm -rf "$INSTALL_DIR" )
      omac_log_ok "removed $INSTALL_DIR"
    else
      omac_log_info "skipped (user declined)"
    fi
  else
    omac_log_info "no install dir at $INSTALL_DIR (already removed)"
  fi
fi

# ─── 4. Final advice ──────────────────────────────────────────────────────────
printf "\n%boh-my-anycli uninstall complete.%b\n\n" "${OMAC_COLOR_GREEN:-}" "${OMAC_COLOR_RESET:-}"
printf "Left intact:\n"
printf "  - opencode-anycli itself (use its separate uninstaller)\n"
printf "  - %s/opencode.json (wrapper config)\n" "$TARGET_DIR"
printf "  - commands/agents/skills files you added yourself\n"
if [ "$remove_install_dir" = "0" ]; then
  printf "  - %s ${OMAC_COLOR_DIM:-}(remove with --remove-install-dir)${OMAC_COLOR_RESET:-}\n" "$INSTALL_DIR"
fi
