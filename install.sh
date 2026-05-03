#!/usr/bin/env bash
#
# install.sh — bootstrap installer for oh-my-clinecli.
#
# Copies skills/, commands/, agents/, and any plugins/ into the user's
# openclineclicode config directory (~/.config/openclineclicode by default).
#
# Usage:
#   ./install.sh                # idempotent: skips files that already exist
#   ./install.sh --force        # overwrite existing files
#   ./install.sh --reapply      # alias of --force, used by `omc reapply`
#   ./install.sh --prune        # remove installed artifacts no longer in repo
#   ./install.sh --user         # symlink omc into ~/.local/bin instead of /usr/local/bin
#   ./install.sh --system       # use sudo to symlink into /usr/local/bin
#   ./install.sh --no-symlink   # do not create the omc symlink at all
#
# Environment:
#   OMC_INSTALL_DIR   override install location (default: ~/.oh-my-clinecli)
#   OMC_TARGET_DIR    override openclineclicode config dir
#   OMC_REPO_URL      override the repo URL used by initial clone
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/colors.sh
. "$SCRIPT_DIR/lib/colors.sh"
# shellcheck source=lib/log.sh
. "$SCRIPT_DIR/lib/log.sh"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

# Repository URL used by the auto-clone path (only when the script is run
# from outside an existing checkout AND OMC_INSTALL_DIR points at a
# non-existent directory). In a team fork, override with:
#   OMC_REPO_URL=https://git.example.com/<your-org>/oh-my-clinecli.git
DEFAULT_REPO_URL="${OMC_REPO_URL:-https://github.com/JSUYA/oh-my-clinecli.git}"

force=""
prune=0
symlink_mode="auto"  # auto | user | system | none

while [ $# -gt 0 ]; do
  case "$1" in
    --force|--reapply) force="--force" ;;
    --prune)           prune=1 ;;
    --user)            symlink_mode="user" ;;
    --system)          symlink_mode="system" ;;
    --no-symlink)      symlink_mode="none" ;;
    -h|--help)
      sed -n '3,22p' "$0"
      exit 0
      ;;
    *)
      omc_die "unknown flag: $1"
      ;;
  esac
  shift
done

TARGET_DIR="$(omc_target_dir)"

# 1. Resolve INSTALL_DIR.
#    Order of precedence:
#      a) OMC_INSTALL_DIR env (if set AND points at an existing checkout)
#      b) The script's own location, if it contains install.sh + lib/ (i.e. we're
#         already running from a checkout — `git clone && ./install.sh` case)
#      c) Default ~/.oh-my-clinecli; clone into it if absent
#
#    This keeps `git clone <repo> && cd <repo> && ./install.sh` working without
#    requiring OMC_INSTALL_DIR, and also makes re-running from inside an
#    existing checkout idempotent (no spurious clone attempt).
if [ -n "${OMC_INSTALL_DIR:-}" ] && [ -d "${OMC_INSTALL_DIR}" ]; then
  INSTALL_DIR="${OMC_INSTALL_DIR}"
elif [ -f "$SCRIPT_DIR/install.sh" ] && [ -d "$SCRIPT_DIR/lib" ] && [ -d "$SCRIPT_DIR/skills" ]; then
  INSTALL_DIR="$SCRIPT_DIR"
else
  INSTALL_DIR="${OMC_INSTALL_DIR:-$HOME/.oh-my-clinecli}"
  if [ ! -d "$INSTALL_DIR" ]; then
    omc_log_step "Cloning oh-my-clinecli into $INSTALL_DIR"
    if ! command -v git >/dev/null 2>&1; then
      omc_die "git is not installed; install git and retry."
    fi
    git clone "$DEFAULT_REPO_URL" "$INSTALL_DIR"
    # Re-exec from the cloned location so subsequent paths resolve correctly.
    exec "$INSTALL_DIR/install.sh" ${force:+--force} $([ "$prune" = "1" ] && printf -- "--prune") --no-symlink
  fi
fi

# 2. Detect openclineclicode config dir. Auto-create if it doesn't exist —
#    oh-my-clinecli only writes into subdirs (skills/command/agent), so creating
#    the parent is harmless even before openclineclicode itself runs.
if [ ! -d "$TARGET_DIR" ]; then
  omc_log_warn "Target config directory does not exist; creating it."
  omc_log_warn "Install openclineclicode first if it is not already installed."
  mkdir -p "$TARGET_DIR"
fi

omc_log_info "install dir : $INSTALL_DIR"
omc_log_info "target dir  : $TARGET_DIR"
omc_log_info "version     : $(omc_version)"

# Counters
copied_skills=0;   skipped_skills=0
copied_commands=0; skipped_commands=0
copied_agents=0;   skipped_agents=0
copied_plugins=0

# Track artifacts we install so --prune can clean stale ones.
manifest_dir="$TARGET_DIR/.oh-my-clinecli"
omc_ensure_dir "$manifest_dir"
manifest_file="$manifest_dir/manifest.txt"
new_manifest="$(mktemp)"
trap 'rm -f "$new_manifest"' EXIT

record() { printf "%s\n" "$1" >> "$new_manifest"; }

install_one() {
  # install_one <src> <dst> <counter-copied-var> <counter-skipped-var>
  #
  # SECURITY NOTE: $cv and $sv are passed by the (in-this-file) caller as
  # variable NAMES so we use indirect assignment via eval. All call sites
  # supply HARDCODED identifiers (copied_skills, skipped_skills, etc. — see
  # the loops below). NEVER pass a user-controlled string as $3 or $4 — that
  # would be a shell-injection vector. The bash 4.3 `local -n` namespace ref
  # would be safer but macOS ships bash 3.2 so we keep eval for portability.
  local src="$1" dst="$2" cv="$3" sv="$4"
  if omc_copy_file "$src" "$dst" "$force"; then
    eval "$cv=\$(( \${$cv} + 1 ))"
  else
    eval "$sv=\$(( \${$sv} + 1 ))"
  fi
  record "$dst"
}

# 4. skills/
omc_log_step "Installing skills"
if [ -d "$INSTALL_DIR/skills" ]; then
  for skill_dir in "$INSTALL_DIR/skills"/*/; do
    [ -d "$skill_dir" ] || continue
    name="$(basename "$skill_dir")"
    src="$skill_dir/SKILL.md"
    [ -f "$src" ] || { omc_log_warn "Skill '$name' has no SKILL.md; skipping."; continue; }
    dst="$TARGET_DIR/skills/$name/SKILL.md"
    install_one "$src" "$dst" copied_skills skipped_skills
  done
fi

# 5. commands/
omc_log_step "Installing commands"
if [ -d "$INSTALL_DIR/commands" ]; then
  for cmd in "$INSTALL_DIR/commands"/*.md; do
    [ -f "$cmd" ] || continue
    name="$(basename "$cmd")"
    dst="$TARGET_DIR/commands/$name"
    install_one "$cmd" "$dst" copied_commands skipped_commands
  done
fi

# 6. agents/
omc_log_step "Installing agents"
if [ -d "$INSTALL_DIR/agents" ]; then
  for agent in "$INSTALL_DIR/agents"/*.md; do
    [ -f "$agent" ] || continue
    name="$(basename "$agent")"
    # Enforce model: cline/default — see docs/agent-authoring.md.
    agent_model="$(omc_frontmatter_get "$agent" model 2>/dev/null || true)"
    if [ "$agent_model" != "cline/default" ]; then
      omc_log_warn "Rejected agents/$name: model='$agent_model' (required: cline/default)"
      continue
    fi
    dst="$TARGET_DIR/agents/$name"
    install_one "$agent" "$dst" copied_agents skipped_agents
  done
fi

# 7. plugins/<name>/
omc_log_step "Installing plugins"
if [ -d "$INSTALL_DIR/plugins" ]; then
  for plugin_dir in "$INSTALL_DIR/plugins"/*/; do
    [ -d "$plugin_dir" ] || continue
    plugin_name="$(basename "$plugin_dir")"
    # Skip the bundled examples/ slot and the README itself.
    case "$plugin_name" in
      examples|README*) continue ;;
    esac
    [ -f "$plugin_dir/plugin.json" ] || { omc_log_warn "Plugin '$plugin_name' has no plugin.json; skipping."; continue; }
    copied_plugins=$(( copied_plugins + 1 ))

    if [ -d "$plugin_dir/skills" ]; then
      for sd in "$plugin_dir/skills"/*/; do
        [ -d "$sd" ] || continue
        sname="$(basename "$sd")"
        src="$sd/SKILL.md"
        [ -f "$src" ] || continue
        dst="$TARGET_DIR/skills/${plugin_name}__${sname}/SKILL.md"
        install_one "$src" "$dst" copied_skills skipped_skills
      done
    fi
    if [ -d "$plugin_dir/commands" ]; then
      for cmd in "$plugin_dir/commands"/*.md; do
        [ -f "$cmd" ] || continue
        cname="$(basename "$cmd" .md)"
        dst="$TARGET_DIR/commands/${plugin_name}__${cname}.md"
        install_one "$cmd" "$dst" copied_commands skipped_commands
      done
    fi
    if [ -d "$plugin_dir/agents" ]; then
      for agent in "$plugin_dir/agents"/*.md; do
        [ -f "$agent" ] || continue
        aname="$(basename "$agent" .md)"
        # Enforce model: cline/default — see docs/agent-authoring.md.
        # Sub-agents declaring any other model would fail at runtime because
        # this integration exposes only cline/default.
        agent_model="$(omc_frontmatter_get "$agent" model 2>/dev/null || true)"
        if [ -n "$agent_model" ] && [ "$agent_model" != "cline/default" ]; then
          omc_log_warn "Rejected $plugin_name/agents/$aname.md: model='$agent_model' (required: cline/default)"
          continue
        fi
        if [ -z "$agent_model" ]; then
          omc_log_warn "Rejected $plugin_name/agents/$aname.md: missing required model key"
          continue
        fi
        dst="$TARGET_DIR/agents/${plugin_name}__${aname}.md"
        install_one "$agent" "$dst" copied_agents skipped_agents
      done
    fi
  done
fi

# Also process examples/ as a sanity-installable plugin set if a flag is set.
# (Intentionally skipped by default to avoid clutter.)

# 8. omc symlink.
maybe_symlink_omc() {
  local target_bin
  case "$symlink_mode" in
    none) return 0 ;;
    user) target_bin="$HOME/.local/bin/omc" ;;
    system) target_bin="/usr/local/bin/omc" ;;
    auto)
      if [ -w "/usr/local/bin" ]; then target_bin="/usr/local/bin/omc"
      else                              target_bin="$HOME/.local/bin/omc"
      fi
      ;;
  esac
  omc_ensure_dir "$(dirname "$target_bin")"
  local src="$INSTALL_DIR/omc"
  if [ "$symlink_mode" = "system" ] && [ ! -w "$(dirname "$target_bin")" ]; then
    omc_log_info "Creating system symlink with sudo"
    sudo ln -sf "$src" "$target_bin"
  else
    ln -sf "$src" "$target_bin"
  fi
  omc_log_ok "linked $target_bin -> $src"
}
maybe_symlink_omc || omc_log_warn "Failed to create omc symlink. Add $INSTALL_DIR to PATH."

# 9. --prune: remove anything in old manifest but not in new.
if [ "$prune" = "1" ] && [ -f "$manifest_file" ]; then
  omc_log_step "Pruning stale installed artifacts"
  while IFS= read -r old; do
    if ! grep -Fxq "$old" "$new_manifest"; then
      if [ -f "$old" ]; then
        rm -f "$old"
        omc_log_debug "pruned $old"
        # Try to clean now-empty parent dir (skill dirs).
        rmdir "$(dirname "$old")" 2>/dev/null || true
      fi
    fi
  done < "$manifest_file"
fi

mv "$new_manifest" "$manifest_file"
trap - EXIT

# 9. Summary.
omc_log_ok "$(printf "installed: %d skills (%d skipped), %d commands (%d skipped), %d agents (%d skipped), %d plugins" \
  "$copied_skills" "$skipped_skills" \
  "$copied_commands" "$skipped_commands" \
  "$copied_agents" "$skipped_agents" \
  "$copied_plugins")"

cat <<'EOF'

Next steps:
  1. omc doctor       - check installation status
  2. omc list         - list installed artifacts
  3. Start cline or openclineclicode, then use slash commands such as /review or /test
EOF
