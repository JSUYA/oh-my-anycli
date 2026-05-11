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

Add a `<handoff-context-policy>` block after the command instruction when the
command is meant to run through opencode-anycli. The provider strips this block
before handing the prompt to cline and uses the `id` to keep only the context
that is useful for that command family.

```markdown
<handoff-context-policy id="diff-review">
keep: latest_user, command_instruction, changed_files, diffs, nearby_code, failing_checks
summarize: bash, grep, read, prior_assistant
drop: unrelated_history, stale_tool_results
</handoff-context-policy>
```

Current policy IDs: `diff-review`, `debug-diagnose`, `test-writing`,
`release-git`, and `doc-explain`.

## Guidelines

- Commands should route, constrain, and summarize; detailed workflow belongs in a skill.
- Use the same name as the matching skill when practical.
- Keep tool lists minimal for the workflow.
- Preserve file paths, command names, and identifiers exactly.

## Validation

```bash
bash tests/lint-commands.sh
```
