# shellcheck shell=bash
# ANSI color helpers for oh-my-anycli scripts.
# Source this file; do not execute it directly.
#
# Disable colors entirely by setting NO_COLOR=1 in the environment, or when
# stdout is not a TTY.

if [ -t 1 ] && [ "${NO_COLOR:-0}" != "1" ]; then
  OMC_COLOR_RESET="\033[0m"
  OMC_COLOR_BOLD="\033[1m"
  OMC_COLOR_DIM="\033[2m"
  OMC_COLOR_RED="\033[31m"
  OMC_COLOR_GREEN="\033[32m"
  OMC_COLOR_YELLOW="\033[33m"
  OMC_COLOR_BLUE="\033[34m"
  OMC_COLOR_MAGENTA="\033[35m"
  OMC_COLOR_CYAN="\033[36m"
else
  OMC_COLOR_RESET=""
  OMC_COLOR_BOLD=""
  OMC_COLOR_DIM=""
  OMC_COLOR_RED=""
  OMC_COLOR_GREEN=""
  OMC_COLOR_YELLOW=""
  OMC_COLOR_BLUE=""
  OMC_COLOR_MAGENTA=""
  OMC_COLOR_CYAN=""
fi

omc_color_red()    { printf "%b%s%b" "$OMC_COLOR_RED"    "$1" "$OMC_COLOR_RESET"; }
omc_color_green()  { printf "%b%s%b" "$OMC_COLOR_GREEN"  "$1" "$OMC_COLOR_RESET"; }
omc_color_yellow() { printf "%b%s%b" "$OMC_COLOR_YELLOW" "$1" "$OMC_COLOR_RESET"; }
omc_color_blue()   { printf "%b%s%b" "$OMC_COLOR_BLUE"   "$1" "$OMC_COLOR_RESET"; }
omc_color_cyan()   { printf "%b%s%b" "$OMC_COLOR_CYAN"   "$1" "$OMC_COLOR_RESET"; }
omc_color_bold()   { printf "%b%s%b" "$OMC_COLOR_BOLD"   "$1" "$OMC_COLOR_RESET"; }
omc_color_dim()    { printf "%b%s%b" "$OMC_COLOR_DIM"    "$1" "$OMC_COLOR_RESET"; }
