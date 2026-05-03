# shellcheck shell=bash
# Logging helpers for oh-my-anycli. Source after lib/colors.sh.

# Levels: info, warn, error, ok, step.
# Verbosity: OMAC_VERBOSE=1 enables debug output.

omac_log_info()  { printf "%b %s\n" "$(omac_color_blue   "[info]")"  "$*"; }
omac_log_ok()    { printf "%b %s\n" "$(omac_color_green  "[ ok ]")"  "$*"; }
omac_log_warn()  { printf "%b %s\n" "$(omac_color_yellow "[warn]")"  "$*" >&2; }
omac_log_error() { printf "%b %s\n" "$(omac_color_red    "[err ]")"  "$*" >&2; }
omac_log_step()  { printf "%b %s\n" "$(omac_color_cyan   "[step]")"  "$*"; }

omac_log_debug() {
  if [ "${OMAC_VERBOSE:-0}" = "1" ]; then
    printf "%b %s\n" "$(omac_color_dim "[dbg ]")" "$*" >&2
  fi
}

# omac_log_check <ok|fail> <message>
omac_log_check() {
  local status="$1"; shift
  if [ "$status" = "ok" ]; then
    printf "  %b %s\n" "$(omac_color_green "OK")" "$*"
  else
    printf "  %b %s\n" "$(omac_color_red "X ")" "$*"
  fi
}

omac_die() {
  omac_log_error "$*"
  exit 1
}
