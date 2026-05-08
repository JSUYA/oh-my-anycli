# Architecture

Oh-My-AnyCLI is a markdown-first artifact collection for OpenCode-AnyCLI. It has no TypeScript or Python runtime; installation and maintenance are handled by Bash scripts.

## Repository layout

| Path | Purpose |
| --- | --- |
| `skills/<name>/SKILL.md` | Reusable workflow instructions with YAML frontmatter. |
| `commands/<name>.md` | Slash command wrappers that route a user request to a workflow. |
| `agents/<name>.md` | Subagent definitions pinned to `model: cline/default`. |
| `plugins/<name>/` | Optional shareable extension packages. |
| `custom/` | Local-only user additions; not managed as upstream artifacts. |
| `install.sh` | Copies artifacts into the OpenCode-AnyCLI target config. |
| `update.sh` | Runs `git pull --ff-only` and reapplies installed artifacts. |
| `uninstall.sh` | Removes only manifest-tracked installed files. |
| `omac` | Helper CLI for list/search/info/plugin/update/doctor commands. |
| `tests/` | Lint, unit, and end-to-end test suite — see `tests/run-all.sh`. |

## Installation model

`install.sh` resolves an install directory, resolves the target config directory, copies artifacts, records every installed file in a manifest, and optionally creates an `omac` symlink.

Plugins are installed with prefixed names:

- plugin skill: `skills/<plugin>__<skill>/SKILL.md`
- plugin command: `commands/<plugin>__<command>.md`
- plugin agent: `agents/<plugin>__<agent>.md`

## Compatibility constraints

- Agents must declare `model: cline/default`.
- Skills must use a `SKILL.md` file under a directory named after the skill.
- Commands and agents are top-level markdown files.
- Shell scripts are written for portable Bash and standard Unix tools.

## Safety properties

- Uninstall and prune use the manifest instead of deleting whole directories blindly.
- Existing installed files are skipped unless `--force` or `--reapply` is used.
- Plugin agents with missing or unsupported models are rejected during install.
