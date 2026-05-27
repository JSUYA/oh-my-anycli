# Architecture

Oh-My-AnyCLI is a markdown-first artifact collection for AI-agent CLIs. It has no TypeScript or Python runtime; registry, status, and selected installs are handled by Bash.

## Repository layout

| Path | Purpose |
| --- | --- |
| `skills/<name>/SKILL.md` | Reusable workflow instructions with YAML frontmatter. |
| `commands/<name>.md` | Slash command wrappers that route a user request to a workflow. |
| `agents/<name>.md` | Agent definitions pinned to `model: cline/default`; most use `mode: subagent`, with audited exceptions for coordinator agents. |
| `plugins/<name>/` | Optional shareable extension packages. |
| `plugins/<name>/opencode/` | Native opencode payloads copied unprefixed into the target config. |
| `custom/` | Local-only user additions; not managed as upstream artifacts. |
| `install.sh` | Legacy OpenCode-AnyCLI bulk installer. Prefer `omac skill/plugin install`. |
| `update.sh` | Runs `git pull --ff-only` and reapplies installed artifacts. |
| `uninstall.sh` | Removes only manifest-tracked installed files. |
| `omac` | Helper CLI for universal status, selected skill/plugin installs, search/info/update/doctor commands. |
| `lib/selective.sh` | Target adapters and manifests for Claude, Codex, Cline, and OpenCode selected installs. |
| `tests/` | Lint, unit, and end-to-end test suite — see `tests/run-all.sh`. |

## Installation model

`omac` treats the repository as a registry. `skills/<name>/SKILL.md` is the
universal source, and target adapters copy selected artifacts into one or more
agent roots.

Default global roots:

- Claude: `~/.claude`
- Codex: `~/.codex`
- Cline: `~/.cline`
- OpenCode-AnyCLI: `~/.config/opencode-anycli/opencode`

Project-local installs use `.claude`, `.codex`, `.cline`, and `.opencode` under the
current working directory or `OMAC_LOCAL_DIR`.

Each target root has a selected-install manifest at
`.oh-my-anycli/manifest.tsv`. This manifest is separate from the legacy
OpenCode `manifest.txt` used by `install.sh`.

`install.sh` still resolves an install directory, resolves the OpenCode target
config directory, copies artifacts, records every installed file in a legacy
manifest, and optionally creates an `omac` symlink.

Plugins are installed with prefixed names:

- plugin skill: `skills/<plugin>__<skill>/SKILL.md`
- plugin command: `commands/<plugin>__<command>.md`
- plugin agent: `agents/<plugin>__<agent>.md`
- native opencode plugin file: `plugins/<file>.js`
- native opencode command/skill/agent: copied from `plugins/<name>/opencode/`
  without prefix

## Compatibility constraints

- Agents must declare `model: cline/default`.
- Agents must use `mode: subagent`, except audited coordinator agents such as
  `orchestrator` which use `mode: all`.
- Skills must use a `SKILL.md` file under a directory named after the skill.
- Commands and agents are top-level markdown files.
- Shell scripts are written for portable Bash and standard Unix tools.

## Safety properties

- Uninstall and prune use the manifest instead of deleting whole directories blindly.
- Existing installed files are skipped unless `--force` or `--reapply` is used.
- Plugin agents with missing or unsupported models are rejected during install.
