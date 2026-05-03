# Installation

oh-my-anycli installs reusable opencode-anycli artifacts into the local opencode-anycli config directory.

## Prerequisites

- `git`
- `bash`
- opencode-anycli installed or a writable target config directory

The default target directory is `~/.config/opencode-anycli/opencode`. Override it with `OMAC_TARGET_DIR`.

## Install

```bash
git clone https://github.com/JSUYA/oh-my-anycli.git ~/.oh-my-anycli
~/.oh-my-anycli/install.sh
omac doctor
```

By default, `install.sh` copies:

- `skills/*/SKILL.md` to `$OMAC_TARGET_DIR/skills/<name>/SKILL.md`
- `commands/*.md` to `$OMAC_TARGET_DIR/commands/<name>.md`
- `agents/*.md` to `$OMAC_TARGET_DIR/agents/<name>.md`
- valid plugin artifacts from `plugins/<name>/`

It also links `omac` into `/usr/local/bin` when writable, otherwise `~/.local/bin`.

## Installer options

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
| `OMAC_TARGET_DIR` | Override the opencode-anycli config directory. |
| `OMAC_REPO_URL` | Override the repository cloned by the auto-clone path. |

## Uninstall

```bash
~/.oh-my-anycli/uninstall.sh
~/.oh-my-anycli/uninstall.sh --remove-install-dir
~/.oh-my-anycli/uninstall.sh --yes
```

Uninstall is manifest-based. It removes only files recorded by `install.sh` in `$OMAC_TARGET_DIR/.oh-my-anycli/manifest.txt` and leaves user-authored artifacts intact.
