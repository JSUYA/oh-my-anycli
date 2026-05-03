# shellcheck shell=bash
# Logging helpers for oh-my-anycli. Source after lib/colors.sh.

# Levels: info, warn, error, ok, step.
# Verbosity: OMC_VERBOSE=1 enables debug output.

omc_log_info()  { printf "%b %s\n" "$(omc_color_blue   "[info]")"  "$*"; }
omc_log_ok()    { printf "%b %s\n" "$(omc_color_green  "[ ok ]")"  "$*"; }
omc_log_warn()  { printf "%b %s\n" "$(omc_color_yellow "[warn]")"  "$*" >&2; }
omc_log_error() { printf "%b %s\n" "$(omc_color_red    "[err ]")"  "$*" >&2; }
omc_log_step()  { printf "%b %s\n" "$(omc_color_cyan   "[step]")"  "$*"; }

omc_log_debug() {
  if [ "${OMC_VERBOSE:-0}" = "1" ]; then
    printf "%b %s\n" "$(omc_color_dim "[dbg ]")" "$*" >&2
  fi
}

# omc_log_check <ok|fail> <message>
omc_log_check() {
  local status="$1"; shift
  if [ "$status" = "ok" ]; then
    printf "  %b %s\n" "$(omc_color_green "OK")" "$*"
  else
    printf "  %b %s\n" "$(omc_color_red "X ")" "$*"
  fi
}

omc_die() {
  omc_log_error "$*"
  exit 1
}
