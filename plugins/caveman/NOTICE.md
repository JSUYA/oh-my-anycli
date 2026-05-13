# Attribution

This plugin includes files copied from `JuliusBrussee/caveman` at commit
`63a91ecadbf4c4719a4602a5abb00883f9966034`.

Upstream: <https://github.com/JuliusBrussee/caveman>

Upstream license: MIT.

Copyright (c) 2026 Julius Brussee.

## Copied Files

- `src/plugins/opencode/plugin.js` -> `opencode/plugins/caveman.js`
- `src/hooks/caveman-config.js` -> `opencode/plugins/caveman-config.cjs`
- `src/plugins/opencode/commands/*.md` -> `opencode/commands/*.md`
- `skills/caveman*` -> `opencode/skills/caveman*`
- `src/rules/caveman-activate.md` -> `opencode/AGENTS.append.md`
- `src/plugins/opencode/README.md` -> `upstream/opencode-plugin-README.md`

The copied source text is intentionally preserved. Oh-My-AnyCLI only changes
the install layout so opencode-anycli can load the plugin from its isolated
config directory.
