# Command Authoring

Commands are slash-command wrappers stored as `commands/<name>.md`.

## Frontmatter

```yaml
---
description: Review CI configuration for common safety and reliability issues.
argument_hint: "[optional target]"
allowed_tools: [bash, read, grep]
---
```

Required fields:

- `description`
- `argument_hint`
- `allowed_tools`

## Body

Wrap instructions in `<command-instruction>` and keep them scoped:

```markdown
<command-instruction>
Run the matching skill when one exists. Inspect local project context first. Do not perform destructive Git, filesystem, or network operations unless explicitly requested.
</command-instruction>
```

## Guidelines

- Commands should route, constrain, and summarize; detailed workflow belongs in a skill.
- Use the same name as the matching skill when practical.
- Keep tool lists minimal for the workflow.
- Preserve file paths, command names, and identifiers exactly.

## Validation

```bash
bash tests/lint-commands.sh
```
