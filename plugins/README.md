# Plugins

Plugins extend oh-my-clinecli with additional skills, commands, or agents.

## Add a Plugin

```bash
omc plugin add https://git.example.com/<your-org>/<plugin-repo>.git
```

The plugin is cloned into `plugins/<name>/` and then installed into the openclineclicode config directory with prefixed artifact names.

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
