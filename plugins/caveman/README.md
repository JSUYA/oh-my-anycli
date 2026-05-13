# caveman plugin

Native opencode caveman mode packaged for Oh-My-AnyCLI.

On install or update, `install.sh` copies the `opencode/` payload into the
OpenCode-AnyCLI config directory:

- `opencode/plugins/` -> `$OMAC_TARGET_DIR/plugins/`
- `opencode/commands/` -> `$OMAC_TARGET_DIR/commands/`
- `opencode/skills/` -> `$OMAC_TARGET_DIR/skills/`
- `opencode/AGENTS.append.md` -> managed caveman block inside `$OMAC_TARGET_DIR/AGENTS.md`

OpenCode loads local plugin files from the config `plugins/` directory at
startup, so no `opencode.json` mutation is required.

See `NOTICE.md` and `LICENSE` for upstream attribution and MIT terms.
