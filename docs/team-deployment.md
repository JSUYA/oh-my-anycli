# Team Deployment

Teams can use oh-my-anycli as a shared baseline and extend it with plugins or a fork.

## Recommended models

| Model | Use when |
| --- | --- |
| Upstream repo + plugins | Teams want to receive upstream updates and maintain separate internal artifacts. |
| Fork | Teams need to change default artifacts, installer behavior, or policy. |
| Local `custom/` | One developer needs private local artifacts that should not be shared. |

## Plugin-based deployment

1. Create a plugin repository with `plugin.json` and artifacts.
2. Install the core collection.
3. Add the team plugin:

```bash
omac plugin add <team-plugin-git-url>
omac doctor
```

## Fork-based deployment

Set `OMAC_REPO_URL` when using the auto-clone path:

```bash
OMAC_REPO_URL=<team-fork-git-url> install.sh
```

Keep fork-specific policy in docs and tests so updates remain reviewable.

## Update policy

Use fast-forward updates for the core checkout:

```bash
omac update
omac update --prune
```

Run validation before publishing team changes:

```bash
bash tests/lint-skills.sh
bash tests/lint-commands.sh
bash tests/lint-agents.sh
bash tests/verify-install.sh
```
