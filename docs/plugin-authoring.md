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
└── agents/
    └── example-agent.md
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

## Remove behavior

```bash
omac plugin remove <name>
```

The plugin directory is removed and `install.sh --reapply --prune` cleans stale installed artifacts from the manifest.
