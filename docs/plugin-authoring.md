# Plugin Authoring

Plugins package shareable skills, commands, and agents outside the core collection.

## Layout

```text
my-plugin/
├── plugin.json
├── README.md
├── skills/
│   └── example-skill/
│       └── SKILL.md
├── commands/
│   └── example.md
├── agents/
│   └── example-agent.md
└── opencode/
    ├── plugins/
    │   └── example.js
    ├── commands/
    │   └── example.md
    ├── skills/
    │   └── example/
    │       └── SKILL.md
    └── AGENTS.append.md
```

Only `plugin.json` is required, but a useful plugin should include at least one artifact.

## plugin.json

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "Short plugin description"
}
```

## Install behavior

```bash
omac plugin add <git-url>
```

The plugin is cloned into `plugins/<name>/`, then installed with prefixed artifact names to avoid collisions:

- `skills/<plugin>__<skill>/SKILL.md`
- `commands/<plugin>__<command>.md`
- `agents/<plugin>__<agent>.md`

Plugin agents must declare `model: cline/default` or they are rejected.

Plugins may also include a native `opencode/` payload. These files are copied
verbatim and unprefixed into the OpenCode-AnyCLI config directory:

- `opencode/plugins/` -> `$OMAC_TARGET_DIR/plugins/`
- `opencode/commands/` -> `$OMAC_TARGET_DIR/commands/`
- `opencode/skills/` -> `$OMAC_TARGET_DIR/skills/`
- `opencode/agents/` -> `$OMAC_TARGET_DIR/agents/`

Use native payloads only when the artifact must be loaded by opencode itself,
for example a JavaScript plugin file under `plugins/`. `AGENTS.append.md` is
special: it is appended or replaced as a managed block in
`$OMAC_TARGET_DIR/AGENTS.md` using `<!-- <plugin>-begin -->` and
`<!-- <plugin>-end -->` markers. It is removed on `install.sh --prune` if the
plugin no longer exists.

## Remove behavior

```bash
omac plugin remove <name>
```

The plugin directory is removed and `install.sh --reapply --prune` cleans stale installed artifacts from the manifest.
