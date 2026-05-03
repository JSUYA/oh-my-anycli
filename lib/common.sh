# shellcheck shell=bash
# Common helpers for oh-my-clinecli install/update/omc/doctor scripts.
# Source after lib/colors.sh and lib/log.sh.

# Resolve the install directory of oh-my-clinecli itself.
# Honors OMC_INSTALL_DIR; otherwise inferred from this file's location.
omc_install_dir() {
  if [ -n "${OMC_INSTALL_DIR:-}" ]; then
    printf "%s" "$OMC_INSTALL_DIR"
    return
  fi
  # lib/common.sh -> install dir is parent of lib/
  local self_dir
  self_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  printf "%s" "$(cd "$self_dir/.." && pwd)"
}

# Resolve the openclineclicode config directory.
# This is the directory opencode itself reads under the wrapper's XDG isolation
# (XDG_CONFIG_HOME=$HOME/.config/openclineclicode → opencode reads
# $HOME/.config/openclineclicode/opencode/{commands,agents,skills}). The
# wrapper installs opencode.json one level deeper for the same reason.
omc_target_dir() {
  printf "%s" "${OMC_TARGET_DIR:-$HOME/.config/openclineclicode/opencode}"
}

# Read VERSION file, fallback to "unknown".
omc_version() {
  local install_dir
  install_dir="$(omc_install_dir)"
  if [ -f "$install_dir/VERSION" ]; then
    tr -d '[:space:]' < "$install_dir/VERSION"
  else
    printf "unknown"
  fi
}

# Ensure a directory exists.
omc_ensure_dir() {
  local d="$1"
  if [ ! -d "$d" ]; then
    mkdir -p "$d"
    omc_log_debug "created $d"
  fi
}

# Copy a file with idempotency. Args: src dst [--force]
# Returns 0 on copy, 1 on skip-existing, 2 on error.
omc_copy_file() {
  local src="$1" dst="$2" force="${3:-}"
  if [ ! -f "$src" ]; then
    omc_log_error "source file missing: $src"
    return 2
  fi
  omc_ensure_dir "$(dirname "$dst")"
  if [ -f "$dst" ] && [ "$force" != "--force" ]; then
    # If contents are identical, treat as no-op rather than skip.
    if cmp -s "$src" "$dst"; then
      omc_log_debug "unchanged $dst"
      return 0
    fi
    omc_log_debug "skip existing $dst (use --force to overwrite)"
    return 1
  fi
  cp "$src" "$dst"
  omc_log_debug "wrote $dst"
  return 0
}

# Minimal YAML frontmatter parser. Walks lines between leading '---' and the
# matching closing '---', parses simple "key: value" lines (no nesting, no
# multiline values). Prints "key=value" pairs, one per line.
#
# Usage: omc_parse_frontmatter <file>
omc_parse_frontmatter() {
  local file="$1"
  awk '
    BEGIN { in_fm = 0; opened = 0 }
    NR == 1 {
      if ($0 == "---") { in_fm = 1; opened = 1; next } else { exit 0 }
    }
    in_fm && /^---[[:space:]]*$/ { in_fm = 0; exit 0 }
    in_fm {
      # Skip list-continuation lines and blanks.
      if ($0 ~ /^[[:space:]]*-/) next
      if ($0 ~ /^[[:space:]]*$/) next
      if ($0 ~ /^[[:space:]]*#/) next
      # Match "key: value" at top level (no leading whitespace).
      if (match($0, /^[A-Za-z_][A-Za-z0-9_-]*:[[:space:]]*/)) {
        key = substr($0, 1, index($0, ":") - 1)
        value = substr($0, index($0, ":") + 1)
        sub(/^[[:space:]]+/, "", value)
        sub(/[[:space:]]+$/, "", value)
        # Strip surrounding quotes.
        if (value ~ /^".*"$/) value = substr(value, 2, length(value) - 2)
        if (value ~ /^'\''.*'\''$/) value = substr(value, 2, length(value) - 2)
        print key "=" value
      }
    }
  ' "$file"
}

# Get a single frontmatter value. Args: file key
omc_frontmatter_get() {
  local file="$1" key="$2"
  omc_parse_frontmatter "$file" | awk -F= -v k="$key" '$1 == k { sub(/^[^=]*=/, ""); print; exit }'
}

# Validate that a frontmatter block contains all listed required keys.
# Args: file key1 key2 ...
# Returns 0 if all present, 1 with stderr message otherwise.
omc_frontmatter_require() {
  local file="$1"; shift
  local missing=()
  local key
  for key in "$@"; do
    if [ -z "$(omc_frontmatter_get "$file" "$key")" ]; then
      missing+=("$key")
    fi
  done
  if [ ${#missing[@]} -gt 0 ]; then
    printf "missing keys in %s: %s\n" "$file" "${missing[*]}" >&2
    return 1
  fi
  return 0
}

# Slugify a string for filesystem use. Lowercases and replaces non-alnum with -.
omc_slug() {
  printf "%s" "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'
}

# Infer plugin name from a git URL (last path segment, sans .git).
omc_plugin_name_from_url() {
  local url="$1" name
  name="${url##*/}"
  name="${name%.git}"
  printf "%s" "$(omc_slug "$name")"
}

# Count files matching a pattern under a directory. Args: dir pattern
omc_count() {
  local dir="$1" pattern="$2"
  if [ ! -d "$dir" ]; then
    printf "0"
    return
  fi
  # shellcheck disable=SC2012
  find "$dir" -mindepth 1 -maxdepth 3 -name "$pattern" 2>/dev/null | wc -l | tr -d ' '
}
