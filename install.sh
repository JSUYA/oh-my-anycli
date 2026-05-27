#!/usr/bin/env bash
#
# install.sh — bootstrap installer for oh-my-anycli.
#
# Copies skills/, commands/, agents/, and any plugins/ into the user's
# opencode-anycli config directory (~/.config/opencode-anycli by default).
#
# Usage:
#   ./install.sh                # idempotent: skips files that already exist
#   ./install.sh --force        # overwrite existing files
#   ./install.sh --reapply      # alias of --force, used by `omac reapply`
#   ./install.sh --prune        # remove installed artifacts no longer in repo
#   ./install.sh --user         # symlink omac into ~/.local/bin instead of /usr/local/bin
#   ./install.sh --system       # use sudo to symlink into /usr/local/bin
#   ./install.sh --no-symlink   # do not create the omac symlink at all
#
# Environment:
#   OMAC_INSTALL_DIR   override install location (default: ~/.oh-my-anycli)
#   OMAC_TARGET_DIR    override opencode-anycli config dir
#   OMAC_REPO_URL      override the repo URL used by initial clone
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/colors.sh
. "$SCRIPT_DIR/lib/colors.sh"
# shellcheck source=lib/log.sh
. "$SCRIPT_DIR/lib/log.sh"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=lib/json-merge.sh
. "$SCRIPT_DIR/lib/json-merge.sh"

# Repository URL used by the auto-clone path (only when the script is run
# from outside an existing checkout AND OMAC_INSTALL_DIR points at a
# non-existent directory). In a team fork, override with:
#   OMAC_REPO_URL=https://git.example.com/<your-org>/oh-my-anycli.git
DEFAULT_REPO_URL="${OMAC_REPO_URL:-https://github.com/JSUYA/oh-my-anycli.git}"

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
      omac_die "unknown flag: $1"
      ;;
  esac
  shift
done

TARGET_DIR="$(omac_target_dir)"

# 1. Resolve INSTALL_DIR.
#    Order of precedence:
#      a) OMAC_INSTALL_DIR env (if set AND points at an existing checkout)
#      b) The script's own location, if it contains install.sh + lib/ (i.e. we're
#         already running from a checkout — `git clone && ./install.sh` case)
#      c) Default ~/.oh-my-anycli; clone into it if absent
#
#    This keeps `git clone <repo> && cd <repo> && ./install.sh` working without
#    requiring OMAC_INSTALL_DIR, and also makes re-running from inside an
#    existing checkout idempotent (no spurious clone attempt).
if [ -n "${OMAC_INSTALL_DIR:-}" ] && [ -d "${OMAC_INSTALL_DIR}" ]; then
  INSTALL_DIR="${OMAC_INSTALL_DIR}"
elif [ -f "$SCRIPT_DIR/install.sh" ] && [ -d "$SCRIPT_DIR/lib" ] && [ -d "$SCRIPT_DIR/skills" ]; then
  INSTALL_DIR="$SCRIPT_DIR"
else
  INSTALL_DIR="${OMAC_INSTALL_DIR:-$HOME/.oh-my-anycli}"
  if [ ! -d "$INSTALL_DIR" ]; then
    omac_log_step "Cloning oh-my-anycli into $INSTALL_DIR"
    if ! command -v git >/dev/null 2>&1; then
      omac_die "git is not installed; install git and retry."
    fi
    git clone "$DEFAULT_REPO_URL" "$INSTALL_DIR"
    # Re-exec from the cloned location so subsequent paths resolve correctly.
    exec "$INSTALL_DIR/install.sh" ${force:+--force} $([ "$prune" = "1" ] && printf -- "--prune") --no-symlink
  fi
fi

# 2. Detect opencode-anycli config dir. Auto-create if it doesn't exist —
#    oh-my-anycli only writes into subdirs (skills/command/agent), so creating
#    the parent is harmless even before opencode-anycli itself runs.
if [ ! -d "$TARGET_DIR" ]; then
  omac_log_warn "Target config directory does not exist; creating it."
  omac_log_warn "Install opencode-anycli first if it is not already installed."
  mkdir -p "$TARGET_DIR"
fi

omac_log_info "install dir : $INSTALL_DIR"
omac_log_info "target dir  : $TARGET_DIR"
omac_log_info "version     : $(omac_version)"
omac_log_warn "install.sh is a legacy opencode bulk installer; prefer 'omac skill install <name>' and 'omac plugin install <name>'."

# Counters
copied_skills=0;   skipped_skills=0
copied_commands=0; skipped_commands=0
copied_agents=0;   skipped_agents=0
copied_plugins=0
copied_opencode=0; skipped_opencode=0

# Track artifacts we install so --prune can clean stale ones.
manifest_dir="$TARGET_DIR/.oh-my-anycli"
omac_ensure_dir "$manifest_dir"
manifest_file="$manifest_dir/manifest.txt"
new_manifest="$(mktemp)"
block_manifest_file="$manifest_dir/agents-blocks.txt"
new_block_manifest="$(mktemp)"
# Tracks file:// URLs registered into $TARGET_DIR/opencode.json's "plugin"
# array. opencode does not auto-load .js files from a plugins/ dir, so we
# must add an explicit entry per native plugin. The manifest lets --prune
# unregister URLs whose source plugin has been removed.
oc_plugin_manifest_file="$manifest_dir/opencode-plugins.txt"
new_oc_plugin_manifest="$(mktemp)"
trap 'rm -f "$new_manifest" "$new_block_manifest" "$new_oc_plugin_manifest"' EXIT

record() { printf "%s\n" "$1" >> "$new_manifest"; }
record_agents_block() { printf "%s|%s|%s\n" "$1" "$2" "$3" >> "$new_block_manifest"; }
record_oc_plugin() { printf "%s\n" "$1" >> "$new_oc_plugin_manifest"; }

install_one() {
  # install_one <src> <dst>
  #
  # Returns:
  #   0 — file was copied OR was already identical (counts as "copied").
  #   1 — destination existed with different content, was kept (counts as
  #       "skipped"). Use --force / --reapply to overwrite.
  #   2 — source missing or copy failed. Caller decides whether to abort.
  #
  # The caller must increment its own counters at the call site based on this
  # exit code. Pre-0.4 versions used eval-based indirect variable assignment;
  # the explicit return code keeps the function pure-data-flow and removes the
  # shell-injection footgun.
  local src="$1" dst="$2" rc
  omac_copy_file "$src" "$dst" "$force"
  rc=$?
  case "$rc" in
    0)
      record "$dst"
      ;;
    1)
      # Only keep ownership for files this installer already owned. A
      # pre-existing user file must not enter the manifest just because its
      # path collides with an upstream artifact.
      if [ -f "$manifest_file" ] && grep -Fxq "$dst" "$manifest_file"; then
        record "$dst"
      fi
      ;;
  esac
  return "$rc"
}

install_tree_files() {
  # install_tree_files <src-root> <dst-root>
  #
  # Copies every regular file below src-root to dst-root, preserving relative
  # paths and recording each file in the install manifest. Used for native
  # opencode plugin payloads that need full directories, not just SKILL.md.
  local src_root="$1" dst_root="$2" src rel dst
  [ -d "$src_root" ] || return 0
  while IFS= read -r -d '' src; do
    rel="${src#"$src_root"/}"
    dst="$dst_root/$rel"
    if install_one "$src" "$dst"; then
      copied_opencode=$(( copied_opencode + 1 ))
    else
      skipped_opencode=$(( skipped_opencode + 1 ))
    fi
  done < <(find "$src_root" -type f -print0)
}

replace_or_append_block() {
  # replace_or_append_block <src> <dst> <begin-marker> <end-marker>
  #
  # Installs a managed block into AGENTS.md without owning the whole file. The
  # block itself is tracked separately so --prune can remove it when the plugin
  # disappears while preserving user-authored AGENTS.md content.
  local src="$1" dst="$2" begin="$3" end="$4" tmp last_char
  [ -f "$src" ] || return 0
  omac_ensure_dir "$(dirname "$dst")"

  if [ ! -f "$dst" ]; then
    cp "$src" "$dst"
    copied_opencode=$(( copied_opencode + 1 ))
    return 0
  fi

  tmp="$(mktemp)"
  if grep -Fxq "$begin" "$dst" && grep -Fxq "$end" "$dst"; then
    awk -v begin="$begin" -v end="$end" -v repl="$src" '
      BEGIN {
        while ((getline line < repl) > 0) replacement = replacement line ORS
        close(repl)
      }
      $0 == begin { printf "%s", replacement; skipping=1; next }
      skipping && $0 == end { skipping=0; next }
      !skipping { print }
    ' "$dst" > "$tmp"
  else
    cp "$dst" "$tmp"
    if [ -s "$tmp" ]; then
      last_char="$(tail -c 1 "$tmp" 2>/dev/null || true)"
      [ "$last_char" = "" ] || printf "\n" >> "$tmp"
      printf "\n" >> "$tmp"
    fi
    cat "$src" >> "$tmp"
  fi

  if cmp -s "$tmp" "$dst"; then
    rm -f "$tmp"
  elif [ -f "$dst" ] && [ "$force" != "--force" ] && grep -Fxq "$begin" "$dst"; then
    rm -f "$tmp"
    skipped_opencode=$(( skipped_opencode + 1 ))
  else
    mv "$tmp" "$dst"
    copied_opencode=$(( copied_opencode + 1 ))
  fi
}

remove_block_from_file() {
  # remove_block_from_file <dst> <begin-marker> <end-marker>
  local dst="$1" begin="$2" end="$3" tmp
  [ -f "$dst" ] || return 0
  grep -Fxq "$begin" "$dst" || return 0
  grep -Fxq "$end" "$dst" || return 0
  tmp="$(mktemp)"
  awk -v begin="$begin" -v end="$end" '
    $0 == begin { skipping=1; next }
    skipping && $0 == end { skipping=0; next }
    !skipping { print }
  ' "$dst" > "$tmp"
  mv "$tmp" "$dst"
}

# 4. skills/
omac_log_step "Installing skills"
if [ -d "$INSTALL_DIR/skills" ]; then
  for skill_dir in "$INSTALL_DIR/skills"/*/; do
    [ -d "$skill_dir" ] || continue
    name="$(basename "$skill_dir")"
    src="$skill_dir/SKILL.md"
    [ -f "$src" ] || { omac_log_warn "Skill '$name' has no SKILL.md; skipping."; continue; }
    dst="$TARGET_DIR/skills/$name/SKILL.md"
    if install_one "$src" "$dst"; then
      copied_skills=$(( copied_skills + 1 ))
    else
      skipped_skills=$(( skipped_skills + 1 ))
    fi
  done
fi

# 5. commands/
omac_log_step "Installing commands"
if [ -d "$INSTALL_DIR/commands" ]; then
  for cmd in "$INSTALL_DIR/commands"/*.md; do
    [ -f "$cmd" ] || continue
    name="$(basename "$cmd")"
    dst="$TARGET_DIR/commands/$name"
    if install_one "$cmd" "$dst"; then
      copied_commands=$(( copied_commands + 1 ))
    else
      skipped_commands=$(( skipped_commands + 1 ))
    fi
  done
fi

# 6. agents/
omac_log_step "Installing agents"
if [ -d "$INSTALL_DIR/agents" ]; then
  for agent in "$INSTALL_DIR/agents"/*.md; do
    [ -f "$agent" ] || continue
    name="$(basename "$agent")"
    # Enforce model: cline/default — see docs/agent-authoring.md.
    agent_model="$(omac_frontmatter_get "$agent" model 2>/dev/null || true)"
    if [ "$agent_model" != "cline/default" ]; then
      omac_log_warn "Rejected agents/$name: model='$agent_model' (required: cline/default)"
      continue
    fi
    dst="$TARGET_DIR/agents/$name"
    if install_one "$agent" "$dst"; then
      copied_agents=$(( copied_agents + 1 ))
    else
      skipped_agents=$(( skipped_agents + 1 ))
    fi
  done
fi

# 7. plugins/<name>/
omac_log_step "Installing plugins"
if [ -d "$INSTALL_DIR/plugins" ]; then
  for plugin_dir in "$INSTALL_DIR/plugins"/*/; do
    [ -d "$plugin_dir" ] || continue
    plugin_name="$(basename "$plugin_dir")"
    # Skip the bundled examples/ slot and the README itself.
    case "$plugin_name" in
      examples|README*) continue ;;
    esac
    [ -f "$plugin_dir/plugin.json" ] || { omac_log_warn "Plugin '$plugin_name' has no plugin.json; skipping."; continue; }
    copied_plugins=$(( copied_plugins + 1 ))

    if [ -d "$plugin_dir/skills" ]; then
      for sd in "$plugin_dir/skills"/*/; do
        [ -d "$sd" ] || continue
        sname="$(basename "$sd")"
        src="$sd/SKILL.md"
        [ -f "$src" ] || continue
        dst="$TARGET_DIR/skills/${plugin_name}__${sname}/SKILL.md"
        if install_one "$src" "$dst"; then
          copied_skills=$(( copied_skills + 1 ))
        else
          skipped_skills=$(( skipped_skills + 1 ))
        fi
      done
    fi
    if [ -d "$plugin_dir/commands" ]; then
      for cmd in "$plugin_dir/commands"/*.md; do
        [ -f "$cmd" ] || continue
        cname="$(basename "$cmd" .md)"
        dst="$TARGET_DIR/commands/${plugin_name}__${cname}.md"
        if install_one "$cmd" "$dst"; then
          copied_commands=$(( copied_commands + 1 ))
        else
          skipped_commands=$(( skipped_commands + 1 ))
        fi
      done
    fi
    if [ -d "$plugin_dir/agents" ]; then
      for agent in "$plugin_dir/agents"/*.md; do
        [ -f "$agent" ] || continue
        aname="$(basename "$agent" .md)"
        # Enforce model: cline/default — see docs/agent-authoring.md.
        # Sub-agents declaring any other model would fail at runtime because
        # this integration exposes only cline/default.
        agent_model="$(omac_frontmatter_get "$agent" model 2>/dev/null || true)"
        if [ -n "$agent_model" ] && [ "$agent_model" != "cline/default" ]; then
          omac_log_warn "Rejected $plugin_name/agents/$aname.md: model='$agent_model' (required: cline/default)"
          continue
        fi
        if [ -z "$agent_model" ]; then
          omac_log_warn "Rejected $plugin_name/agents/$aname.md: missing required model key"
          continue
        fi
        dst="$TARGET_DIR/agents/${plugin_name}__${aname}.md"
        if install_one "$agent" "$dst"; then
          copied_agents=$(( copied_agents + 1 ))
        else
          skipped_agents=$(( skipped_agents + 1 ))
        fi
      done
    fi

    # Native opencode payloads are installed verbatim and unprefixed. Use this
    # only for plugins that intentionally target opencode's own extension
    # points, such as local JS plugins or opencode-native command files.
    if [ -d "$plugin_dir/opencode" ]; then
      install_tree_files "$plugin_dir/opencode/plugins"  "$TARGET_DIR/plugins"
      install_tree_files "$plugin_dir/opencode/commands" "$TARGET_DIR/commands"
      install_tree_files "$plugin_dir/opencode/skills"   "$TARGET_DIR/skills"
      install_tree_files "$plugin_dir/opencode/agents"   "$TARGET_DIR/agents"

      # Register every native JS module under opencode/plugins/ in
      # $TARGET_DIR/opencode.json so opencode actually loads it at startup.
      # Without this step, install_tree_files only drops the file on disk
      # and the plugin's hooks never run — the historical bug behind
      # caveman.js sitting unused after `omac plugin add`.
      if [ -d "$plugin_dir/opencode/plugins" ]; then
        while IFS= read -r -d '' src_js; do
          case "$src_js" in
            *.js|*.cjs|*.mjs) ;;
            *) continue ;;
          esac
          rel="${src_js#"$plugin_dir/opencode/plugins"/}"
          dst_js="$TARGET_DIR/plugins/$rel"
          url="file://$dst_js"
          if omac_json_plugin_add "$TARGET_DIR/opencode.json" "$url"; then
            record_oc_plugin "$url"
            omac_log_debug "registered opencode plugin: $url"
          else
            omac_log_warn "failed to register $url in $TARGET_DIR/opencode.json"
          fi
        done < <(find "$plugin_dir/opencode/plugins" -type f -print0 2>/dev/null)
      fi

      agents_append="$plugin_dir/opencode/AGENTS.append.md"
      if [ -f "$agents_append" ]; then
        begin_marker="<!-- ${plugin_name}-begin -->"
        end_marker="<!-- ${plugin_name}-end -->"
        record_agents_block "$TARGET_DIR/AGENTS.md" "$begin_marker" "$end_marker"
        replace_or_append_block "$agents_append" "$TARGET_DIR/AGENTS.md" "$begin_marker" "$end_marker"
      fi
    fi
  done
fi

# Also process examples/ as a sanity-installable plugin set if a flag is set.
# (Intentionally skipped by default to avoid clutter.)

# 8. omac symlink.
maybe_symlink_omc() {
  local target_bin
  case "$symlink_mode" in
    none) return 0 ;;
    user) target_bin="$HOME/.local/bin/omac" ;;
    system) target_bin="/usr/local/bin/omac" ;;
    auto)
      if [ -w "/usr/local/bin" ]; then target_bin="/usr/local/bin/omac"
      else                              target_bin="$HOME/.local/bin/omac"
      fi
      ;;
  esac
  omac_ensure_dir "$(dirname "$target_bin")"
  local src="$INSTALL_DIR/omac"
  if [ "$symlink_mode" = "system" ] && [ ! -w "$(dirname "$target_bin")" ]; then
    omac_log_info "Creating system symlink with sudo"
    sudo ln -sf "$src" "$target_bin"
  else
    ln -sf "$src" "$target_bin"
  fi
  omac_log_ok "linked $target_bin -> $src"
}
maybe_symlink_omc || omac_log_warn "Failed to create omac symlink. Add $INSTALL_DIR to PATH."

# 9. --prune: remove anything in old manifest but not in new.
if [ "$prune" = "1" ] && [ -f "$manifest_file" ]; then
  omac_log_step "Pruning stale installed artifacts"
  while IFS= read -r old; do
    if ! grep -Fxq "$old" "$new_manifest"; then
      if [ -f "$old" ]; then
        rm -f "$old"
        omac_log_debug "pruned $old"
        # Try to clean now-empty parent dir (skill dirs).
        rmdir "$(dirname "$old")" 2>/dev/null || true
      fi
    fi
  done < "$manifest_file"
fi

if [ "$prune" = "1" ] && [ -f "$block_manifest_file" ]; then
  omac_log_step "Pruning stale managed AGENTS.md blocks"
  while IFS='|' read -r block_file begin_marker end_marker; do
    [ -n "$block_file" ] || continue
    if ! grep -Fxq "$block_file|$begin_marker|$end_marker" "$new_block_manifest"; then
      remove_block_from_file "$block_file" "$begin_marker" "$end_marker"
      omac_log_debug "pruned managed AGENTS.md block $begin_marker"
    fi
  done < "$block_manifest_file"
fi

if [ "$prune" = "1" ] && [ -f "$oc_plugin_manifest_file" ]; then
  omac_log_step "Pruning stale opencode.json plugin entries"
  while IFS= read -r old_url; do
    [ -n "$old_url" ] || continue
    if ! grep -Fxq "$old_url" "$new_oc_plugin_manifest"; then
      omac_json_plugin_remove "$TARGET_DIR/opencode.json" "$old_url" \
        && omac_log_debug "unregistered $old_url"
    fi
  done < "$oc_plugin_manifest_file"
fi

mv "$new_manifest" "$manifest_file"
mv "$new_block_manifest" "$block_manifest_file"
mv "$new_oc_plugin_manifest" "$oc_plugin_manifest_file"
trap - EXIT

# 9. Summary.
omac_log_ok "$(printf "installed: %d skills (%d skipped), %d commands (%d skipped), %d agents (%d skipped), %d plugins, %d native opencode files (%d skipped)" \
  "$copied_skills" "$skipped_skills" \
  "$copied_commands" "$skipped_commands" \
  "$copied_agents" "$skipped_agents" \
  "$copied_plugins" \
  "$copied_opencode" "$skipped_opencode")"

cat <<'EOF'

Next steps:
  1. omac doctor       - check installation status
  2. omac list         - list installed artifacts
  3. Start cline or opencode-anycli, then use slash commands such as /review or /test
EOF
