#!/usr/bin/env bash
#
# e2e-plugin.sh — exercise the plugin lifecycle using the bundled
# plugins/examples/hello-world fixture.
#
# Strategy:
#   1. Build a throw-away "fake clone" of oh-my-anycli in a tmpdir (rsync the
#      source tree). This avoids touching the user's real ~/.oh-my-anycli.
#   2. Promote plugins/examples/hello-world to plugins/hello-world inside the
#      fake clone, so install.sh actually picks it up (top-level
#      plugins/examples/ is intentionally skipped by install.sh).
#   3. Run install.sh against an isolated target. Verify the plugin's
#      artifacts land with the `hello-world__` prefix.
#   4. Remove the plugin directory in the fake clone, run install --prune.
#      Verify prefixed artifacts disappear.
#   5. Confirm omac plugin list / add-from-tarball does the right thing
#      (install path; the `git clone` path is exercised by separately
#      providing a local bare repo).
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/colors.sh
. "$ROOT_DIR/lib/colors.sh"
# shellcheck source=../lib/log.sh
. "$ROOT_DIR/lib/log.sh"

if ! command -v rsync >/dev/null 2>&1; then
  omac_log_warn "rsync not available; falling back to cp -r"
  COPY_TREE() { cp -r "$1/." "$2/"; }
else
  COPY_TREE() { rsync -a --exclude=.git "$1/" "$2/"; }
fi

tmpdir="$(mktemp -d -t omac-e2e-plugin-XXXXXX)"
trap 'rm -rf "$tmpdir"' EXIT

fake_install="$tmpdir/install-dir"
target="$tmpdir/target/opencode-anycli/opencode"
mkdir -p "$fake_install" "$target"

omac_log_step "[1/5] cloning source tree into isolated install dir"
COPY_TREE "$ROOT_DIR" "$fake_install"

# install.sh ignores plugins/examples/. Promote hello-world to a real plugin.
mkdir -p "$fake_install/plugins"
cp -r "$fake_install/plugins/examples/hello-world" "$fake_install/plugins/hello-world"

failures=0
fail() { failures=$(( failures + 1 )); }

run_install() {
  OMAC_INSTALL_DIR="$fake_install" \
  OMAC_TARGET_DIR="$target" \
  "$fake_install/install.sh" --no-symlink "$@" >/dev/null
}

omac_log_step "[2/5] install with hello-world plugin present"
run_install

# Plugin artifact names are prefixed with "<plugin>__".
plugin_skill="$target/skills/hello-world__hello/SKILL.md"
plugin_cmd="$target/commands/hello-world__hello.md"
plugin_agent="$target/agents/hello-world__hello-agent.md"

if [ -f "$plugin_skill" ]; then
  omac_log_check ok "plugin skill installed (hello-world__hello)"
else
  omac_log_check fail "plugin skill missing"
  fail
fi
if [ -f "$plugin_cmd" ]; then
  omac_log_check ok "plugin command installed (hello-world__hello)"
else
  omac_log_check fail "plugin command missing"
  fail
fi
if [ -f "$plugin_agent" ]; then
  omac_log_check ok "plugin agent installed (hello-world__hello-agent)"
else
  omac_log_check fail "plugin agent missing"
  fail
fi

# Manifest must reference each prefixed artifact.
manifest="$target/.oh-my-anycli/manifest.txt"
for f in "$plugin_skill" "$plugin_cmd" "$plugin_agent"; do
  if grep -Fxq "$f" "$manifest"; then
    omac_log_check ok "manifest tracks $(basename "$f")"
  else
    omac_log_check fail "manifest missing $(basename "$f")"
    fail
  fi
done

omac_log_step "[3/5] reject plugin agent with wrong model"
bad_plugin="$fake_install/plugins/bad-plugin"
mkdir -p "$bad_plugin/agents"
cat > "$bad_plugin/plugin.json" <<'EOF'
{ "name": "bad-plugin", "version": "0.0.1" }
EOF
cat > "$bad_plugin/agents/bad-agent.md" <<'EOF'
---
name: bad-agent
description: Should be rejected by install because of wrong model.
mode: subagent
model: not-cline-default
---

body
EOF
# Capture stderr to look for the rejection warning.
warn_log="$(OMAC_INSTALL_DIR="$fake_install" \
              OMAC_TARGET_DIR="$target" \
              "$fake_install/install.sh" --reapply --no-symlink 2>&1 >/dev/null)"
if printf "%s" "$warn_log" | grep -q "Rejected bad-plugin/agents/bad-agent.md"; then
  omac_log_check ok "wrong-model plugin agent rejected with warning"
else
  omac_log_check fail "wrong-model plugin agent rejection warning missing"
  fail
fi
if [ -f "$target/agents/bad-plugin__bad-agent.md" ]; then
  omac_log_check fail "wrong-model plugin agent leaked into target"
  fail
else
  omac_log_check ok "wrong-model plugin agent NOT installed"
fi
rm -rf "$bad_plugin"

omac_log_step "[4/5] --prune removes a deleted plugin's artifacts"
rm -rf "$fake_install/plugins/hello-world"
run_install --prune
for f in "$plugin_skill" "$plugin_cmd" "$plugin_agent"; do
  if [ -f "$f" ]; then
    omac_log_check fail "$(basename "$f") survived plugin removal"
    fail
  else
    omac_log_check ok "$(basename "$f") removed by --prune"
  fi
done

omac_log_step "[5/5] omac plugin add via local file:// bare repo"
# Build a bare git repo from the example so omac plugin add can clone it.
bare="$tmpdir/hello-world.git"
work="$tmpdir/hello-world-work"
git init -q --bare "$bare"
# Default HEAD on the bare repo must point at the branch we are about to
# push, otherwise `git clone` produces an empty working tree even though
# the push succeeded. Older git versions don't support --initial-branch.
git -C "$bare" symbolic-ref HEAD refs/heads/main

git init -q "$work"
cp -r "$ROOT_DIR/plugins/examples/hello-world/." "$work/"
git -C "$work" \
    -c user.email=test@example.com \
    -c user.name=test \
    -c init.defaultBranch=main \
    checkout -q -B main
git -C "$work" \
    -c user.email=test@example.com \
    -c user.name=test \
    add -A
git -C "$work" \
    -c user.email=test@example.com \
    -c user.name=test \
    commit -q -m "init"
git -C "$work" remote add origin "$bare"
git -C "$work" push -q origin main:main

OMAC_INSTALL_DIR="$fake_install" OMAC_TARGET_DIR="$target" \
  "$fake_install/omac" plugin add "file://$bare" >/dev/null

if [ -d "$fake_install/plugins/hello-world" ]; then
  omac_log_check ok "omac plugin add cloned plugin into plugins/"
else
  omac_log_check fail "omac plugin add did not clone plugin"
  fail
fi
if [ -f "$target/skills/hello-world__hello/SKILL.md" ]; then
  omac_log_check ok "omac plugin add reapplied artifacts"
else
  omac_log_check fail "omac plugin add did not reapply artifacts"
  fail
fi

OMAC_INSTALL_DIR="$fake_install" OMAC_TARGET_DIR="$target" \
  "$fake_install/omac" plugin remove hello-world >/dev/null

if [ ! -d "$fake_install/plugins/hello-world" ]; then
  omac_log_check ok "omac plugin remove deleted plugin dir"
else
  omac_log_check fail "omac plugin remove kept plugin dir"
  fail
fi

printf "\n"
if [ "$failures" -gt 0 ]; then
  omac_log_error "e2e-plugin: $failures step(s) failed"
  exit 1
fi
omac_log_ok "e2e-plugin: all steps passed"
