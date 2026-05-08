#!/usr/bin/env bash
#
# unit-frontmatter.sh — unit tests for the frontmatter parser helpers in
# lib/common.sh. Builds tiny fixture files in a tmpdir and asserts each helper
# returns the expected output.
#
# Usage:
#   ./tests/unit-frontmatter.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/colors.sh
. "$ROOT_DIR/lib/colors.sh"
# shellcheck source=../lib/log.sh
. "$ROOT_DIR/lib/log.sh"
# shellcheck source=../lib/common.sh
. "$ROOT_DIR/lib/common.sh"

tmpdir="$(mktemp -d -t omac-unit-fm-XXXXXX)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0
assert_eq() {
  local label="$1" want="$2" got="$3"
  if [ "$want" = "$got" ]; then
    omac_log_check ok "$label"
  else
    omac_log_check fail "$label"
    printf "    want: %q\n" "$want" >&2
    printf "    got : %q\n" "$got" >&2
    failures=$(( failures + 1 ))
  fi
}

assert_contains() {
  local label="$1" needle="$2" haystack="$3"
  if printf "%s" "$haystack" | grep -qF -- "$needle"; then
    omac_log_check ok "$label"
  else
    omac_log_check fail "$label"
    printf "    needle  : %q\n" "$needle" >&2
    printf "    haystack: %q\n" "$haystack" >&2
    failures=$(( failures + 1 ))
  fi
}

assert_empty() {
  local label="$1" got="$2"
  if [ -z "$got" ]; then
    omac_log_check ok "$label"
  else
    omac_log_check fail "$label"
    printf "    got: %q\n" "$got" >&2
    failures=$(( failures + 1 ))
  fi
}

# Fixture 1: simple top-level frontmatter.
fix1="$tmpdir/simple.md"
cat > "$fix1" <<'EOF'
---
name: simple
description: A simple description with spaces.
version: 1.2.3
tag: "quoted-value"
single: 'sq-value'
---

body
EOF

assert_eq "simple/name" "simple" "$(omac_frontmatter_get "$fix1" name)"
assert_eq "simple/description" "A simple description with spaces." "$(omac_frontmatter_get "$fix1" description)"
assert_eq "simple/version" "1.2.3" "$(omac_frontmatter_get "$fix1" version)"
assert_eq "simple/tag (double-quoted strip)" "quoted-value" "$(omac_frontmatter_get "$fix1" tag)"
assert_eq "simple/single (single-quoted strip)" "sq-value" "$(omac_frontmatter_get "$fix1" single)"
assert_empty "simple/missing key" "$(omac_frontmatter_get "$fix1" nope)"

# Fixture 2: required-key checker.
if omac_frontmatter_require "$fix1" name version >/dev/null 2>&1; then
  omac_log_check ok "require: all present → 0"
else
  omac_log_check fail "require: all present should return 0"
  failures=$(( failures + 1 ))
fi

if ! omac_frontmatter_require "$fix1" name nonexistent >/dev/null 2>&1; then
  omac_log_check ok "require: missing key → 1"
else
  omac_log_check fail "require: missing key should return 1"
  failures=$(( failures + 1 ))
fi

# Fixture 3: nested object form (tools:) plus list (inputs:).
fix2="$tmpdir/nested.md"
cat > "$fix2" <<'EOF'
---
name: nested
description: Has nested tools and a list of inputs.
tools:
  bash: true
  read: true
  grep: false
inputs:
  - name: target
    description: First input.
  - name: depth
    description: Second input.
trailing: end
---

body
EOF

# Top-level scalars still parsed cleanly even when nested children are present.
assert_eq "nested/name" "nested" "$(omac_frontmatter_get "$fix2" name)"
assert_eq "nested/trailing" "end" "$(omac_frontmatter_get "$fix2" trailing)"

# Block extraction: tools: should include all three indented children.
tools_block="$(omac_frontmatter_block_get "$fix2" tools)"
assert_contains "block/tools includes bash" "  bash: true" "$tools_block"
assert_contains "block/tools includes read" "  read: true" "$tools_block"
assert_contains "block/tools includes grep" "  grep: false" "$tools_block"
# Block extraction must NOT bleed into the next top-level key.
if printf "%s" "$tools_block" | grep -q "trailing:"; then
  omac_log_check fail "block/tools bled into 'trailing:'"
  failures=$(( failures + 1 ))
else
  omac_log_check ok "block/tools stops at next top-level key"
fi

# Block extraction: inputs: should include both list items.
inputs_block="$(omac_frontmatter_block_get "$fix2" inputs)"
assert_contains "block/inputs first item" "- name: target" "$inputs_block"
assert_contains "block/inputs second item" "- name: depth" "$inputs_block"

# has_children: tools and inputs both have children; name/version do not.
if omac_frontmatter_block_has_children "$fix2" tools; then
  omac_log_check ok "has_children/tools = true"
else
  omac_log_check fail "has_children/tools should be true"
  failures=$(( failures + 1 ))
fi
if omac_frontmatter_block_has_children "$fix2" inputs; then
  omac_log_check ok "has_children/inputs = true"
else
  omac_log_check fail "has_children/inputs should be true"
  failures=$(( failures + 1 ))
fi
if ! omac_frontmatter_block_has_children "$fix2" name; then
  omac_log_check ok "has_children/name = false"
else
  omac_log_check fail "has_children/name should be false"
  failures=$(( failures + 1 ))
fi

# Fixture 4: file with no frontmatter at all.
fix3="$tmpdir/plain.md"
cat > "$fix3" <<'EOF'
# Plain file
no frontmatter here.
EOF

assert_empty "plain/no frontmatter → empty" "$(omac_frontmatter_get "$fix3" name)"
assert_empty "plain/block_get → empty" "$(omac_frontmatter_block_get "$fix3" name)"

# Fixture 5: malformed (frontmatter never closed).
fix4="$tmpdir/unclosed.md"
cat > "$fix4" <<'EOF'
---
name: unclosed
description: never-closed frontmatter
EOF

# We accept whatever we parsed up to EOF — just assert no crash and no false
# positives outside the frontmatter region.
result="$(omac_frontmatter_get "$fix4" name 2>/dev/null || true)"
assert_eq "unclosed/name (graceful)" "unclosed" "$result"

# Fixture 6: real example from the repo (sanity).
real="$ROOT_DIR/skills/code-review/SKILL.md"
if [ -f "$real" ]; then
  assert_eq "real/code-review.name" "code-review" "$(omac_frontmatter_get "$real" name)"
  inputs_real="$(omac_frontmatter_block_get "$real" inputs)"
  assert_contains "real/code-review.inputs has pr_or_branch" "pr_or_branch" "$inputs_real"
fi

printf "\n"
if [ "$failures" -gt 0 ]; then
  omac_log_error "unit-frontmatter: $failures assertion(s) failed"
  exit 1
fi
omac_log_ok "unit-frontmatter: all assertions passed"
