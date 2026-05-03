# shellcheck shell=bash
# ANSI color helpers for oh-my-anycli scripts.
# Source this file; do not execute it directly.
#
# Disable colors entirely by setting NO_COLOR=1 in the environment, or when
# stdout is not a TTY.

# Use $'...' literals so the escape bytes are baked into each variable at
# definition time. Then ${OMAC_COLOR_*} expands correctly inside cat <<EOF,
# echo, and printf uniformly. Raw "\033[..." strings only render via printf %b
# and would print as literal text from heredocs / echo.
if [ -t 1 ] && [ "${NO_COLOR:-0}" != "1" ]; then
  OMAC_COLOR_RESET=$'\033[0m'
  OMAC_COLOR_BOLD=$'\033[1m'
  OMAC_COLOR_DIM=$'\033[2m'
  OMAC_COLOR_RED=$'\033[31m'
  OMAC_COLOR_GREEN=$'\033[32m'
  OMAC_COLOR_YELLOW=$'\033[33m'
  OMAC_COLOR_BLUE=$'\033[34m'
  OMAC_COLOR_MAGENTA=$'\033[35m'
  OMAC_COLOR_CYAN=$'\033[36m'
else
  OMAC_COLOR_RESET=""
  OMAC_COLOR_BOLD=""
  OMAC_COLOR_DIM=""
  OMAC_COLOR_RED=""
  OMAC_COLOR_GREEN=""
  OMAC_COLOR_YELLOW=""
  OMAC_COLOR_BLUE=""
  OMAC_COLOR_MAGENTA=""
  OMAC_COLOR_CYAN=""
fi

omac_color_red()    { printf "%b%s%b" "$OMAC_COLOR_RED"    "$1" "$OMAC_COLOR_RESET"; }
omac_color_green()  { printf "%b%s%b" "$OMAC_COLOR_GREEN"  "$1" "$OMAC_COLOR_RESET"; }
omac_color_yellow() { printf "%b%s%b" "$OMAC_COLOR_YELLOW" "$1" "$OMAC_COLOR_RESET"; }
omac_color_blue()   { printf "%b%s%b" "$OMAC_COLOR_BLUE"   "$1" "$OMAC_COLOR_RESET"; }
omac_color_cyan()   { printf "%b%s%b" "$OMAC_COLOR_CYAN"   "$1" "$OMAC_COLOR_RESET"; }
omac_color_bold()   { printf "%b%s%b" "$OMAC_COLOR_BOLD"   "$1" "$OMAC_COLOR_RESET"; }
omac_color_dim()    { printf "%b%s%b" "$OMAC_COLOR_DIM"    "$1" "$OMAC_COLOR_RESET"; }
