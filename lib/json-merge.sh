# shellcheck shell=bash
# JSON manipulation helpers for oh-my-anycli installer.
#
# Native opencode plugins must be referenced in $TARGET_DIR/opencode.json's
# "plugin" array — opencode does not auto-discover .js files under
# $TARGET_DIR/plugins/. These helpers register/unregister plugin URLs
# idempotently while leaving every other key in opencode.json untouched.
#
# Prefers `jq`. Falls back to inline node when jq is absent. opencode-anycli
# itself already depends on node, so the fallback path is universally
# available on supported installs.

# Detect which JSON tool to use. Sets OMAC_JSON_TOOL (jq|node|"").
omac_json_detect_tool() {
  if [ -n "${OMAC_JSON_TOOL:-}" ]; then return 0; fi
  if command -v jq >/dev/null 2>&1; then
    OMAC_JSON_TOOL=jq
  elif command -v node >/dev/null 2>&1; then
    OMAC_JSON_TOOL=node
  else
    OMAC_JSON_TOOL=""
  fi
}

# omac_json_plugin_add <opencode.json path> <file:// URL>
# Idempotent. Creates the file with {"plugin":[url]} if missing.
omac_json_plugin_add() {
  local file="$1" url="$2"
  omac_json_detect_tool
  if [ -z "$OMAC_JSON_TOOL" ]; then
    omac_log_warn "Neither jq nor node available; cannot register plugin in $file"
    return 1
  fi
  omac_ensure_dir "$(dirname "$file")"
  if [ ! -f "$file" ]; then printf '{}\n' > "$file"; fi
  local tmp
  tmp="$(mktemp)"
  case "$OMAC_JSON_TOOL" in
    jq)
      jq --arg url "$url" \
        '.plugin = ((.plugin // []) + [$url] | unique)' \
        "$file" > "$tmp" || { rm -f "$tmp"; return 1; }
      ;;
    node)
      node -e '
        const fs=require("fs");
        const [f,url]=process.argv.slice(1);
        const j=JSON.parse(fs.readFileSync(f,"utf8"));
        const cur=Array.isArray(j.plugin)?j.plugin.slice():[];
        if(!cur.includes(url)) cur.push(url);
        cur.sort();
        j.plugin=cur;
        process.stdout.write(JSON.stringify(j,null,2)+"\n");
      ' "$file" "$url" > "$tmp" || { rm -f "$tmp"; return 1; }
      ;;
  esac
  mv "$tmp" "$file"
}

# omac_json_plugin_remove <opencode.json path> <file:// URL>
# Idempotent. Removes the URL from the "plugin" array; drops the key entirely
# when the array becomes empty so opencode.json stays minimal.
omac_json_plugin_remove() {
  local file="$1" url="$2"
  [ -f "$file" ] || return 0
  omac_json_detect_tool
  [ -n "$OMAC_JSON_TOOL" ] || return 1
  local tmp
  tmp="$(mktemp)"
  case "$OMAC_JSON_TOOL" in
    jq)
      jq --arg url "$url" \
        '.plugin = ((.plugin // []) | map(select(. != $url)))
         | if (.plugin | length) == 0 then del(.plugin) else . end' \
        "$file" > "$tmp" || { rm -f "$tmp"; return 1; }
      ;;
    node)
      node -e '
        const fs=require("fs");
        const [f,url]=process.argv.slice(1);
        const j=JSON.parse(fs.readFileSync(f,"utf8"));
        const cur=Array.isArray(j.plugin)?j.plugin.filter(x=>x!==url):[];
        if(cur.length===0) delete j.plugin; else j.plugin=cur;
        process.stdout.write(JSON.stringify(j,null,2)+"\n");
      ' "$file" "$url" > "$tmp" || { rm -f "$tmp"; return 1; }
      ;;
  esac
  mv "$tmp" "$file"
}
