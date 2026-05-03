#!/usr/bin/env bash
#
# doctor.sh — diagnose oh-my-clinecli installation.
#
# Prints a colorized check report and exits 0 if everything is healthy,
# 1 if any check fails.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/colors.sh
. "$SCRIPT_DIR/lib/colors.sh"
# shellcheck source=lib/log.sh
. "$SCRIPT_DIR/lib/log.sh"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

INSTALL_DIR="$(omc_install_dir)"
TARGET_DIR="$(omc_target_dir)"

failures=0
fail() { failures=$(( failures + 1 )); }

printf "\n%b\n" "$(omc_color_bold "oh-my-clinecli doctor")"
printf "  install dir : %s\n" "$INSTALL_DIR"
printf "  target dir  : %s\n" "$TARGET_DIR"
printf "  version     : %s\n\n" "$(omc_version)"

# 1. openclineclicode config dir present.
printf "%b\n" "$(omc_color_bold "[1] openclineclicode config")"
if [ -d "$TARGET_DIR" ]; then
  omc_log_check ok "target config directory exists"
else
  omc_log_check fail "target config directory missing"
  fail
fi

if command -v cline >/dev/null 2>&1; then
  omc_log_check ok "cline CLI on PATH: $(command -v cline)"
else
  omc_log_check fail "cline CLI not on PATH"
  fail
fi

# 2. omc on PATH.
printf "\n%b\n" "$(omc_color_bold "[2] omc CLI")"
if command -v omc >/dev/null 2>&1; then
  omc_log_check ok "omc on PATH: $(command -v omc)"
else
  omc_log_check fail "omc CLI not on PATH"
  fail
fi

# 3. Installed skill frontmatter validity.
printf "\n%b\n" "$(omc_color_bold "[3] Installed skills")"
skill_count=0
if [ -d "$TARGET_DIR/skills" ]; then
  for sk in "$TARGET_DIR/skills"/*/SKILL.md; do
    [ -f "$sk" ] || continue
    skill_count=$(( skill_count + 1 ))
    if omc_frontmatter_require "$sk" name description >/dev/null 2>&1; then
      omc_log_check ok "$(basename "$(dirname "$sk")")"
    else
      omc_log_check fail "$(basename "$(dirname "$sk")") — missing required frontmatter"
      fail
    fi
  done
fi
[ "$skill_count" -eq 0 ] && printf "  %b\n" "$(omc_color_dim "no installed skills found")"

# 4. Installed command frontmatter validity.
printf "\n%b\n" "$(omc_color_bold "[4] Installed commands")"
cmd_count=0
if [ -d "$TARGET_DIR/commands" ]; then
  for cm in "$TARGET_DIR/commands"/*.md; do
    [ -f "$cm" ] || continue
    cmd_count=$(( cmd_count + 1 ))
    if omc_frontmatter_require "$cm" description >/dev/null 2>&1; then
      omc_log_check ok "$(basename "$cm")"
    else
      omc_log_check fail "$(basename "$cm") — missing description frontmatter"
      fail
    fi
  done
fi
[ "$cmd_count" -eq 0 ] && printf "  %b\n" "$(omc_color_dim "no installed commands found")"

# 5. Installed agent frontmatter validity.
printf "\n%b\n" "$(omc_color_bold "[5] Installed agents")"
agent_count=0
if [ -d "$TARGET_DIR/agents" ]; then
  for ag in "$TARGET_DIR/agents"/*.md; do
    [ -f "$ag" ] || continue
    agent_count=$(( agent_count + 1 ))
    if omc_frontmatter_require "$ag" name description >/dev/null 2>&1; then
      omc_log_check ok "$(basename "$ag")"
    else
      omc_log_check fail "$(basename "$ag") — missing required frontmatter"
      fail
    fi
  done
fi
[ "$agent_count" -eq 0 ] && printf "  %b\n" "$(omc_color_dim "no installed agents found")"

# 6. Plugin count.
printf "\n%b\n" "$(omc_color_bold "[6] Plugins")"
plugin_count=0
if [ -d "$INSTALL_DIR/plugins" ]; then
  for p in "$INSTALL_DIR/plugins"/*/; do
    [ -d "$p" ] || continue
    name="$(basename "$p")"
    case "$name" in examples|README*) continue ;; esac
    plugin_count=$(( plugin_count + 1 ))
    omc_log_check ok "plugin: $name"
  done
fi
[ "$plugin_count" -eq 0 ] && printf "  %b\n" "$(omc_color_dim "no plugins installed")"

# 7. Counts summary.
printf "\n%b\n" "$(omc_color_bold "[summary]")"
printf "  skills:   %d\n" "$skill_count"
printf "  commands: %d\n" "$cmd_count"
printf "  agents:   %d\n" "$agent_count"
printf "  plugins:  %d\n" "$plugin_count"

printf "\n"
if [ "$failures" -gt 0 ]; then
  omc_log_error "doctor found $failures issue(s)"
  exit 1
fi
omc_log_ok "doctor checks passed"
