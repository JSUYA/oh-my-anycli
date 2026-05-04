# Troubleshooting

## `omac` command not found

Check where the installer linked it:

```bash
ls -l /usr/local/bin/omac ~/.local/bin/omac 2>/dev/null
```

If it is in `~/.local/bin`, ensure that directory is in `PATH`.

## Artifacts are not visible in OpenCode-AnyCLI

Run:

```bash
omac doctor
omac list -v
```

Confirm `OMAC_TARGET_DIR` matches the OpenCode-AnyCLI config directory you actually use.

## Existing files were not overwritten

This is expected for a normal install. Reapply with overwrite:

```bash
~/.oh-my-anycli/install.sh --reapply
```

## Removed upstream files are still installed

Use prune:

```bash
omac update --prune
```

Prune only removes files recorded in the install manifest.

## Agent is skipped during install

Agents must declare:

```yaml
mode: subagent
model: cline/default
```

Unsupported or missing models are rejected because OpenCode-AnyCLI exposes `cline/default`.

## Plugin does not install

Check that the plugin directory contains `plugin.json` and at least one valid artifact directory.

```bash
omac plugin list
omac info <artifact-name>
```

## Validation commands

```bash
bash tests/lint-skills.sh
bash tests/lint-commands.sh
bash tests/lint-agents.sh
bash tests/verify-install.sh
```
