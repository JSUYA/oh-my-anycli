# Plugins

Plugins extend Oh-My-AnyCLI with additional skills, commands, or agents.

## Add a Plugin

```bash
omac plugin add https://git.example.com/<your-org>/<plugin-repo>.git
```

The plugin is cloned into `plugins/<name>/` and then installed into the OpenCode-AnyCLI config directory with prefixed artifact names.

## Plugin Shape

```text
my-plugin/
├── plugin.json
├── README.md
├── skills/
├── commands/
└── agents/
```

See `plugins/examples/hello-world/` for a minimal example.
