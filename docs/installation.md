# Installation

Oh-My-AnyCLI manages reusable AI-agent artifacts through `omac`. Skills and
plugins can be installed selectively into Claude, Codex, Cline, or OpenCode targets.

## Prerequisites

- `git`
- `bash`
- At least one writable target config directory for Claude, Codex, Cline, or OpenCode

Default global target roots:

- Claude: `~/.claude`
- Codex: `~/.codex`
- Cline: `~/.cline`
- OpenCode-AnyCLI: `~/.config/opencode-anycli/opencode`

Override them with `OMAC_CLAUDE_HOME`, `OMAC_CODEX_HOME`, `OMAC_CLINE_HOME`, and `OMAC_TARGET_DIR`.

Cline skills are installed into Cline's `skills/` directory layout. In the VS
Code extension, enable Settings -> Features -> Enable Skills before expecting
newly installed skills to appear.

## Install

```bash
git clone https://github.com/JSUYA/oh-my-anycli.git ~/.oh-my-anycli
~/.oh-my-anycli/install.sh --no-symlink
~/.oh-my-anycli/omac skill list
```

`install.sh` remains available as a legacy OpenCode bulk installer. For new
usage, install only the skills/plugins you want:

```bash
omac skill install code-review --target claude
omac skill install karpathy-guidelines --target codex
omac skill install code-review --target cline
omac skill install tizen-api-modernize --target opencode
omac plugin install caveman --target opencode
```

Use `--target universal` to target Claude, Codex, Cline, and OpenCode together, and
`all` as the artifact name to install every registry item for the selected
target:

```bash
omac skill install all --target opencode
omac plugin install all --target opencode
```

Use `--local` to install into project-local roots (`.claude`, `.codex`,
`.cline`, `.opencode`) instead of global user config.

## Status

```bash
omac skill list
omac skill list --target claude --local
omac skill status code-review
omac plugin list
```

The universal list is the default and reports each artifact as `active`,
`modified`, `present`, or `missing` per target.

## Legacy installer options

| Option | Meaning |
| --- | --- |
| `--force`, `--reapply` | Overwrite existing installed files. |
| `--prune` | Remove previously installed files that no longer exist in this repo. |
| `--user` | Link `omac` into `~/.local/bin`. |
| `--system` | Link `omac` into `/usr/local/bin`, using `sudo` if needed. |
| `--no-symlink` | Install artifacts but do not create the `omac` symlink. |

## Environment variables

| Variable | Meaning |
| --- | --- |
| `OMAC_INSTALL_DIR` | Override the checkout/install location. |
| `OMAC_CLAUDE_HOME` | Override the Claude global root. |
| `OMAC_CODEX_HOME` | Override the Codex global root. |
| `OMAC_CLINE_HOME` | Override the Cline global root. |
| `OMAC_TARGET_DIR` | Override the OpenCode-AnyCLI global root. |
| `OMAC_LOCAL_DIR` | Override the project root used by `--local`. |
| `OMAC_REPO_URL` | Override the repository cloned by the auto-clone path. |

## Uninstall

```bash
~/.oh-my-anycli/uninstall.sh
~/.oh-my-anycli/uninstall.sh --remove-install-dir
~/.oh-my-anycli/uninstall.sh --yes
```

Uninstall is manifest-based. It removes only files recorded by `install.sh` in `$OMAC_TARGET_DIR/.oh-my-anycli/manifest.txt` and leaves user-authored artifacts intact.
