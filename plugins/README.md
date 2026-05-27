# Plugins

Plugins extend Oh-My-AnyCLI with additional skills, commands, or agents.

## Add a Plugin

```bash
omac plugin add https://git.example.com/<your-org>/<plugin-repo>.git
```

The plugin is cloned into `plugins/<name>/` and then installed into the selected target with prefixed artifact names. Native `opencode/` payloads still install only into the OpenCode-AnyCLI config directory.

## Plugin Shape

```text
my-plugin/
├── plugin.json
├── README.md
├── skills/
├── commands/
├── agents/
└── opencode/
    ├── plugins/
    ├── commands/
    ├── skills/
    └── AGENTS.append.md
```

The optional `opencode/` directory is for native opencode payloads that must be
installed without the Oh-My-AnyCLI prefix.

See `plugins/examples/hello-world/` for a minimal example.
