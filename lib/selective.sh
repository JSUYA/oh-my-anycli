# shellcheck shell=bash
# Target-aware selective install helpers for omac.

OMAC_ALL_TARGETS="claude codex opencode"

omac_validate_artifact_name() {
  local name="$1"
  [ -n "$name" ] || return 1
  case "$name" in
    *../*|../*|*/..|..|.*|*/*|*\\*|"") return 1 ;;
  esac
  case "$name" in
    *[!A-Za-z0-9._-]*) return 1 ;;
  esac
  return 0
}

omac_selective_reset() {
  OMAC_SCOPE="global"
  OMAC_VIEW="universal"
  OMAC_TARGETS="$OMAC_ALL_TARGETS"
  OMAC_FORCE=0
  OMAC_VERBOSE=0
  OMAC_REST=()
}

omac_set_target() {
  local target="$1"
  case "$target" in
    universal|universial|all)
      OMAC_VIEW="universal"
      OMAC_TARGETS="$OMAC_ALL_TARGETS"
      ;;
    claude|cluade)
      OMAC_VIEW="claude"
      OMAC_TARGETS="claude"
      ;;
    codex)
      OMAC_VIEW="codex"
      OMAC_TARGETS="codex"
      ;;
    opencode|open-code)
      OMAC_VIEW="opencode"
      OMAC_TARGETS="opencode"
      ;;
    *)
      omac_die "unknown target: $target (expected universal, claude, codex, or opencode)"
      ;;
  esac
}

omac_parse_selective_opts() {
  omac_selective_reset
  while [ $# -gt 0 ]; do
    case "$1" in
      --global) OMAC_SCOPE="global" ;;
      --local) OMAC_SCOPE="local" ;;
      --target)
        shift
        [ $# -gt 0 ] || omac_die "--target requires a value"
        omac_set_target "$1"
        ;;
      --target=*)
        omac_set_target "${1#--target=}"
        ;;
      --universal|--universial)
        omac_set_target universal
        ;;
      --claude|--cluade)
        omac_set_target claude
        ;;
      --codex)
        omac_set_target codex
        ;;
      --opencode|--open-code)
        omac_set_target opencode
        ;;
      --all|--all-agents)
        omac_set_target universal
        ;;
      --force) OMAC_FORCE=1 ;;
      -v|--verbose) OMAC_VERBOSE=1 ;;
      *) OMAC_REST+=("$1") ;;
    esac
    shift
  done
}

omac_target_flags_for_current_selection() {
  if [ "$OMAC_TARGETS" = "$OMAC_ALL_TARGETS" ]; then
    printf "%s" "--target=universal"
  else
    printf -- "--target=%s" "$OMAC_TARGETS"
  fi
}

omac_target_root() {
  local target="$1" scope="$2" project_root
  if [ "$scope" = "local" ]; then
    project_root="${OMAC_LOCAL_DIR:-$PWD}"
    case "$target" in
      claude)   printf "%s/.claude" "$project_root" ;;
      codex)    printf "%s/.codex" "$project_root" ;;
      opencode) printf "%s/.opencode" "$project_root" ;;
      *) return 1 ;;
    esac
    return
  fi

  case "$target" in
    claude)   printf "%s" "${OMAC_CLAUDE_HOME:-$HOME/.claude}" ;;
    codex)    printf "%s" "${OMAC_CODEX_HOME:-$HOME/.codex}" ;;
    opencode) omac_target_dir ;;
    *) return 1 ;;
  esac
}

omac_manifest_file_for_root() {
  printf "%s/.oh-my-anycli/manifest.tsv" "$1"
}

omac_manifest_has() {
  local root="$1" kind="$2" name="$3" target="$4" path="$5" mf line
  mf="$(omac_manifest_file_for_root "$root")"
  [ -f "$mf" ] || return 1
  line="$(printf "%s\t%s\t%s\t%s" "$kind" "$name" "$target" "$path")"
  grep -Fqx "$line" "$mf"
}

omac_manifest_record() {
  local root="$1" kind="$2" name="$3" target="$4" path="$5" mf tmp
  mf="$(omac_manifest_file_for_root "$root")"
  omac_ensure_dir "$(dirname "$mf")"
  tmp="$(mktemp)"
  if [ -f "$mf" ]; then
    awk -F '\t' -v k="$kind" -v n="$name" -v t="$target" -v p="$path" \
      '!(NF >= 4 && $1 == k && $2 == n && $3 == t && $4 == p)' "$mf" > "$tmp"
  fi
  printf "%s\t%s\t%s\t%s\n" "$kind" "$name" "$target" "$path" >> "$tmp"
  sort -u "$tmp" > "$mf"
  rm -f "$tmp"
}

omac_manifest_delete_line() {
  local root="$1" kind="$2" name="$3" target="$4" path="$5" mf tmp
  mf="$(omac_manifest_file_for_root "$root")"
  [ -f "$mf" ] || return 0
  tmp="$(mktemp)"
  awk -F '\t' -v k="$kind" -v n="$name" -v t="$target" -v p="$path" \
    '!(NF >= 4 && $1 == k && $2 == n && $3 == t && $4 == p)' "$mf" > "$tmp"
  mv "$tmp" "$mf"
}

omac_manifest_any() {
  local root="$1" kind="$2" name="$3" target="$4" mf
  mf="$(omac_manifest_file_for_root "$root")"
  [ -f "$mf" ] || return 1
  awk -F '\t' -v k="$kind" -v n="$name" -v t="$target" \
    'NF >= 4 && $1 == k && $2 == n && $3 == t { found=1; exit } END { exit !found }' "$mf"
}

omac_managed_copy() {
  # omac_managed_copy <kind> <name> <target> <root> <src> <dst> <force>
  local kind="$1" name="$2" target="$3" root="$4" src="$5" dst="$6" force="$7"
  local managed=0
  omac_manifest_has "$root" "$kind" "$name" "$target" "$dst" && managed=1
  [ -f "$src" ] || { omac_log_warn "source missing: $src"; return 1; }
  omac_ensure_dir "$(dirname "$dst")"

  if [ -f "$dst" ] && ! cmp -s "$src" "$dst"; then
    if [ "$force" != "1" ] && [ "$managed" != "1" ]; then
      omac_log_warn "kept unmanaged existing file: $dst (use --force to overwrite)"
      return 1
    fi
    if [ "$force" != "1" ]; then
      omac_log_warn "kept modified managed file: $dst (use --force to overwrite)"
      omac_manifest_record "$root" "$kind" "$name" "$target" "$dst"
      return 0
    fi
  fi

  cp "$src" "$dst"
  omac_manifest_record "$root" "$kind" "$name" "$target" "$dst"
  omac_log_ok "$target: installed $name"
}

omac_remove_managed_path() {
  local kind="$1" name="$2" target="$3" root="$4" path="$5"
  if omac_manifest_has "$root" "$kind" "$name" "$target" "$path"; then
    rm -f "$path"
    rmdir "$(dirname "$path")" 2>/dev/null || true
    omac_manifest_delete_line "$root" "$kind" "$name" "$target" "$path"
    omac_log_ok "$target: removed $name"
  elif [ -e "$path" ]; then
    omac_log_warn "left unmanaged file: $path"
  else
    omac_log_info "$target: $name not installed"
  fi
}

omac_skill_source() {
  printf "%s/skills/%s/SKILL.md" "$INSTALL_DIR" "$1"
}

omac_skill_dest() {
  local target="$1" scope="$2" name="$3" root
  root="$(omac_target_root "$target" "$scope")"
  printf "%s/skills/%s/SKILL.md" "$root" "$name"
}

omac_skill_status_for() {
  local target="$1" scope="$2" name="$3" src dst root
  src="$(omac_skill_source "$name")"
  root="$(omac_target_root "$target" "$scope")"
  dst="$(omac_skill_dest "$target" "$scope" "$name")"
  if [ -f "$dst" ]; then
    if [ -f "$src" ] && cmp -s "$src" "$dst"; then
      printf "active"
    elif omac_manifest_has "$root" skill "$name" "$target" "$dst"; then
      printf "modified"
    else
      printf "present"
    fi
  else
    printf "missing"
  fi
}

omac_skill_list_names() {
  [ -d "$INSTALL_DIR/skills" ] || return 0
  find "$INSTALL_DIR/skills" -mindepth 2 -maxdepth 2 -name SKILL.md -print \
    | sed -E 's#^.*/skills/([^/]+)/SKILL.md$#\1#' \
    | sort
}

omac_cmd_skill_list_selective() {
  local name desc status target
  omac_parse_selective_opts "$@"
  printf "scope: %s\n" "$OMAC_SCOPE"
  printf "view: %s\n\n" "$OMAC_VIEW"

  if [ "$OMAC_VIEW" = "universal" ]; then
    printf "%-30s %-10s %-10s %-10s\n" "skill" "claude" "codex" "opencode"
    while IFS= read -r name; do
      [ -n "$name" ] || continue
      printf "%-30s %-10s %-10s %-10s\n" \
        "$name" \
        "$(omac_skill_status_for claude "$OMAC_SCOPE" "$name")" \
        "$(omac_skill_status_for codex "$OMAC_SCOPE" "$name")" \
        "$(omac_skill_status_for opencode "$OMAC_SCOPE" "$name")"
      if [ "$OMAC_VERBOSE" = "1" ]; then
        desc="$(omac_frontmatter_get "$(omac_skill_source "$name")" description 2>/dev/null || true)"
        [ -n "$desc" ] && printf "  %s\n" "$desc"
      fi
    done < <(omac_skill_list_names)
    return
  fi

  printf "%-30s %-10s\n" "skill" "$OMAC_VIEW"
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    status="$(omac_skill_status_for "$OMAC_VIEW" "$OMAC_SCOPE" "$name")"
    printf "%-30s %-10s\n" "$name" "$status"
  done < <(omac_skill_list_names)
}

omac_cmd_skill_status_selective() {
  local name target
  omac_parse_selective_opts "$@"
  name="${OMAC_REST[0]:-}"
  [ -n "$name" ] || omac_die "omac skill status <name> [--target universal|claude|codex|opencode] [--global|--local]"
  omac_validate_artifact_name "$name" || omac_die "invalid skill name: $name"
  [ -f "$(omac_skill_source "$name")" ] || omac_die "skill not found: $name"
  printf "%-10s %-10s %s\n" "target" "status" "path"
  for target in $OMAC_TARGETS; do
    printf "%-10s %-10s %s\n" "$target" "$(omac_skill_status_for "$target" "$OMAC_SCOPE" "$name")" "$(omac_skill_dest "$target" "$OMAC_SCOPE" "$name")"
  done
}

omac_cmd_skill_install_selective() {
  local name target root src dst failures=0
  omac_parse_selective_opts "$@"
  name="${OMAC_REST[0]:-}"
  [ -n "$name" ] || omac_die "omac skill install <name|all> [--target universal|claude|codex|opencode] [--global|--local] [--force]"

  if [ "$name" = "all" ]; then
    while IFS= read -r name; do
      [ -n "$name" ] || continue
      omac_cmd_skill_install_selective "$name" "$(omac_target_flags_for_current_selection)" "$([ "$OMAC_SCOPE" = "local" ] && printf -- "--local" || printf -- "--global")" "$([ "$OMAC_FORCE" = "1" ] && printf -- "--force")" || failures=$(( failures + 1 ))
    done < <(omac_skill_list_names)
    [ "$failures" -eq 0 ]
    return
  fi

  omac_validate_artifact_name "$name" || omac_die "invalid skill name: $name"
  src="$(omac_skill_source "$name")"
  [ -f "$src" ] || omac_die "skill not found: $name"
  for target in $OMAC_TARGETS; do
    root="$(omac_target_root "$target" "$OMAC_SCOPE")"
    dst="$(omac_skill_dest "$target" "$OMAC_SCOPE" "$name")"
    omac_managed_copy skill "$name" "$target" "$root" "$src" "$dst" "$OMAC_FORCE" || failures=$(( failures + 1 ))
  done
  [ "$failures" -eq 0 ]
}

omac_cmd_skill_remove_selective() {
  local name target root dst failures=0
  omac_parse_selective_opts "$@"
  name="${OMAC_REST[0]:-}"
  [ -n "$name" ] || omac_die "omac skill remove <name> [--target universal|claude|codex|opencode] [--global|--local]"
  omac_validate_artifact_name "$name" || omac_die "invalid skill name: $name"
  for target in $OMAC_TARGETS; do
    root="$(omac_target_root "$target" "$OMAC_SCOPE")"
    dst="$(omac_skill_dest "$target" "$OMAC_SCOPE" "$name")"
    omac_remove_managed_path skill "$name" "$target" "$root" "$dst" || failures=$(( failures + 1 ))
  done
  [ "$failures" -eq 0 ]
}

omac_plugin_dir() {
  printf "%s/plugins/%s" "$INSTALL_DIR" "$1"
}

omac_plugin_list_names() {
  [ -d "$INSTALL_DIR/plugins" ] || return 0
  find "$INSTALL_DIR/plugins" -mindepth 1 -maxdepth 1 -type d -print \
    | sed -E 's#^.*/plugins/##' \
    | awk '$0 != "examples" { print }' \
    | sort
}

omac_plugin_status_for() {
  local target="$1" scope="$2" name="$3" root dir found=0 f sd sname rel dst
  root="$(omac_target_root "$target" "$scope")"
  if omac_manifest_any "$root" plugin "$name" "$target"; then
    printf "active"
    return
  fi

  dir="$(omac_plugin_dir "$name")"
  if [ -d "$dir/skills" ]; then
    for sd in "$dir/skills"/*/; do
      [ -d "$sd" ] || continue
      sname="$(basename "$sd")"
      [ -f "$root/skills/${name}__${sname}/SKILL.md" ] && found=1
    done
  fi
  if [ "$target" = "opencode" ]; then
    if [ -d "$dir/opencode/plugins" ]; then
      while IFS= read -r -d '' f; do
        rel="${f#"$dir/opencode/plugins"/}"
        [ -f "$root/plugins/$rel" ] && found=1
      done < <(find "$dir/opencode/plugins" -type f -print0 2>/dev/null)
    fi
    if [ -d "$dir/opencode/commands" ]; then
      while IFS= read -r -d '' f; do
        rel="${f#"$dir/opencode/commands"/}"
        [ -f "$root/commands/$rel" ] && found=1
      done < <(find "$dir/opencode/commands" -type f -print0 2>/dev/null)
    fi
    if [ -d "$dir/opencode/skills" ]; then
      while IFS= read -r -d '' f; do
        rel="${f#"$dir/opencode/skills"/}"
        [ -f "$root/skills/$rel" ] && found=1
      done < <(find "$dir/opencode/skills" -type f -print0 2>/dev/null)
    fi
    if [ -d "$dir/opencode/agents" ]; then
      while IFS= read -r -d '' f; do
        rel="${f#"$dir/opencode/agents"/}"
        [ -f "$root/agents/$rel" ] && found=1
      done < <(find "$dir/opencode/agents" -type f -print0 2>/dev/null)
    fi
  fi
  if [ "$found" = "1" ]; then printf "present"; else printf "missing"; fi
}

omac_cmd_plugin_list_selective() {
  local name ver
  omac_parse_selective_opts "$@"
  printf "scope: %s\n" "$OMAC_SCOPE"
  printf "view: %s\n\n" "$OMAC_VIEW"
  if [ "$OMAC_VIEW" = "universal" ]; then
    printf "%-24s %-10s %-10s %-10s\n" "plugin" "claude" "codex" "opencode"
    while IFS= read -r name; do
      [ -n "$name" ] || continue
      printf "%-24s %-10s %-10s %-10s\n" \
        "$name" \
        "$(omac_plugin_status_for claude "$OMAC_SCOPE" "$name")" \
        "$(omac_plugin_status_for codex "$OMAC_SCOPE" "$name")" \
        "$(omac_plugin_status_for opencode "$OMAC_SCOPE" "$name")"
      if [ "$OMAC_VERBOSE" = "1" ] && [ -f "$(omac_plugin_dir "$name")/plugin.json" ]; then
        ver="$(grep -E '"version"' "$(omac_plugin_dir "$name")/plugin.json" | head -n1 | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' || true)"
        [ -n "$ver" ] && printf "  version: %s\n" "$ver"
      fi
    done < <(omac_plugin_list_names)
    return
  fi

  printf "%-24s %-10s\n" "plugin" "$OMAC_VIEW"
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    printf "%-24s %-10s\n" "$name" "$(omac_plugin_status_for "$OMAC_VIEW" "$OMAC_SCOPE" "$name")"
  done < <(omac_plugin_list_names)
}

omac_install_tree_managed() {
  local plugin="$1" target="$2" root="$3" src_root="$4" dst_root="$5" src rel dst failures=0
  [ -d "$src_root" ] || return 0
  while IFS= read -r -d '' src; do
    rel="${src#"$src_root"/}"
    dst="$dst_root/$rel"
    omac_managed_copy plugin "$plugin" "$target" "$root" "$src" "$dst" "$OMAC_FORCE" || failures=$(( failures + 1 ))
  done < <(find "$src_root" -type f -print0)
  [ "$failures" -eq 0 ]
}

omac_plugin_replace_or_append_block() {
  local src="$1" dst="$2" begin="$3" end="$4" tmp
  [ -f "$src" ] || return 0
  omac_ensure_dir "$(dirname "$dst")"
  tmp="$(mktemp)"
  if [ -f "$dst" ] && grep -Fxq "$begin" "$dst" && grep -Fxq "$end" "$dst"; then
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
    [ -f "$dst" ] && cat "$dst" > "$tmp"
    [ -s "$tmp" ] && printf "\n" >> "$tmp"
    cat "$src" >> "$tmp"
  fi
  mv "$tmp" "$dst"
}

omac_plugin_remove_block() {
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

omac_cmd_plugin_install_selective() {
  local name target root dir failures=0 sd sname src dst cmd cname agent aname model rel dst_js url begin end agents_append
  omac_parse_selective_opts "$@"
  name="${OMAC_REST[0]:-}"
  [ -n "$name" ] || omac_die "omac plugin install <name|all> [--target universal|claude|codex|opencode] [--global|--local] [--force]"

  if [ "$name" = "all" ]; then
    while IFS= read -r name; do
      [ -n "$name" ] || continue
      omac_cmd_plugin_install_selective "$name" "$(omac_target_flags_for_current_selection)" "$([ "$OMAC_SCOPE" = "local" ] && printf -- "--local" || printf -- "--global")" "$([ "$OMAC_FORCE" = "1" ] && printf -- "--force")" || failures=$(( failures + 1 ))
    done < <(omac_plugin_list_names)
    [ "$failures" -eq 0 ]
    return
  fi

  omac_validate_artifact_name "$name" || omac_die "invalid plugin name: $name"
  dir="$(omac_plugin_dir "$name")"
  [ -d "$dir" ] || omac_die "plugin not found: $name"
  [ -f "$dir/plugin.json" ] || omac_die "plugin.json not found: $name"

  for target in $OMAC_TARGETS; do
    root="$(omac_target_root "$target" "$OMAC_SCOPE")"

    if [ -d "$dir/skills" ]; then
      for sd in "$dir/skills"/*/; do
        [ -d "$sd" ] || continue
        sname="$(basename "$sd")"
        src="$sd/SKILL.md"
        [ -f "$src" ] || continue
        dst="$root/skills/${name}__${sname}/SKILL.md"
        omac_managed_copy plugin "$name" "$target" "$root" "$src" "$dst" "$OMAC_FORCE" || failures=$(( failures + 1 ))
      done
    fi

    if [ "$target" = "opencode" ]; then
      if [ -d "$dir/commands" ]; then
        for cmd in "$dir/commands"/*.md; do
          [ -f "$cmd" ] || continue
          cname="$(basename "$cmd" .md)"
          omac_managed_copy plugin "$name" "$target" "$root" "$cmd" "$root/commands/${name}__${cname}.md" "$OMAC_FORCE" || failures=$(( failures + 1 ))
        done
      fi
      if [ -d "$dir/agents" ]; then
        for agent in "$dir/agents"/*.md; do
          [ -f "$agent" ] || continue
          aname="$(basename "$agent" .md)"
          model="$(omac_frontmatter_get "$agent" model 2>/dev/null || true)"
          [ "$model" = "cline/default" ] || { omac_log_warn "Rejected $name/agents/$aname.md: model='$model'"; continue; }
          omac_managed_copy plugin "$name" "$target" "$root" "$agent" "$root/agents/${name}__${aname}.md" "$OMAC_FORCE" || failures=$(( failures + 1 ))
        done
      fi
      omac_install_tree_managed "$name" "$target" "$root" "$dir/opencode/plugins" "$root/plugins" || failures=$(( failures + 1 ))
      omac_install_tree_managed "$name" "$target" "$root" "$dir/opencode/commands" "$root/commands" || failures=$(( failures + 1 ))
      omac_install_tree_managed "$name" "$target" "$root" "$dir/opencode/skills" "$root/skills" || failures=$(( failures + 1 ))
      omac_install_tree_managed "$name" "$target" "$root" "$dir/opencode/agents" "$root/agents" || failures=$(( failures + 1 ))

      if [ -d "$dir/opencode/plugins" ]; then
        while IFS= read -r -d '' src; do
          case "$src" in *.js|*.cjs|*.mjs) ;; *) continue ;; esac
          rel="${src#"$dir/opencode/plugins"/}"
          dst_js="$root/plugins/$rel"
          url="file://$dst_js"
          if omac_json_plugin_add "$root/opencode.json" "$url"; then
            omac_manifest_record "$root" plugin "$name" "$target" "opencode-plugin-url:$url"
          else
            failures=$(( failures + 1 ))
          fi
        done < <(find "$dir/opencode/plugins" -type f -print0 2>/dev/null)
      fi

      agents_append="$dir/opencode/AGENTS.append.md"
      if [ -f "$agents_append" ]; then
        begin="<!-- ${name}-begin -->"
        end="<!-- ${name}-end -->"
        omac_plugin_replace_or_append_block "$agents_append" "$root/AGENTS.md" "$begin" "$end"
        omac_manifest_record "$root" plugin "$name" "$target" "opencode-agents-block:$root/AGENTS.md:$begin:$end"
      fi
    fi
  done
  [ "$failures" -eq 0 ]
}

omac_cmd_plugin_remove_selective() {
  local name target root mf tmp kind rec_name rec_target path url block_file begin end failures=0
  omac_parse_selective_opts "$@"
  name="${OMAC_REST[0]:-}"
  [ -n "$name" ] || omac_die "omac plugin remove <name> [--target universal|claude|codex|opencode] [--global|--local]"
  omac_validate_artifact_name "$name" || omac_die "invalid plugin name: $name"

  for target in $OMAC_TARGETS; do
    root="$(omac_target_root "$target" "$OMAC_SCOPE")"
    mf="$(omac_manifest_file_for_root "$root")"
    if [ ! -f "$mf" ]; then
      omac_log_info "$target: $name not installed"
      continue
    fi
    tmp="$(mktemp)"
    while IFS="$(printf '\t')" read -r kind rec_name rec_target path; do
      if [ "$kind" = "plugin" ] && [ "$rec_name" = "$name" ] && [ "$rec_target" = "$target" ]; then
        case "$path" in
          opencode-plugin-url:*)
            url="${path#opencode-plugin-url:}"
            omac_json_plugin_remove "$root/opencode.json" "$url" || true
            ;;
          opencode-agents-block:*)
            block_file="${path#opencode-agents-block:}"
            begin="${block_file#*:}"
            block_file="${block_file%%:*}"
            end="${begin#*:}"
            begin="${begin%%:*}"
            omac_plugin_remove_block "$block_file" "$begin" "$end"
            ;;
          *)
            rm -f "$path"
            rmdir "$(dirname "$path")" 2>/dev/null || true
            ;;
        esac
        continue
      fi
      printf "%s\t%s\t%s\t%s\n" "$kind" "$rec_name" "$rec_target" "$path" >> "$tmp"
    done < "$mf"
    mv "$tmp" "$mf"
    omac_log_ok "$target: removed plugin $name"
  done
  [ "$failures" -eq 0 ]
}

omac_cmd_plugin_delete_registry() {
  local name="$1" dir real_plugins real_dir
  [ -n "$name" ] || omac_die "omac plugin delete <name>"
  omac_validate_artifact_name "$name" || omac_die "invalid plugin name: $name"
  dir="$(omac_plugin_dir "$name")"
  [ -d "$dir" ] || omac_die "plugin not found: $name"
  real_plugins="$(cd "$INSTALL_DIR/plugins" && pwd -P)"
  real_dir="$(cd "$dir" && pwd -P)"
  case "$real_dir" in
    "$real_plugins"/*) ;;
    *) omac_die "refusing to delete outside plugins dir: $name" ;;
  esac
  rm -rf "$dir"
  omac_log_ok "plugin deleted from registry: $name"
}
