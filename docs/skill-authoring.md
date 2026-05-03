# Skill Authoring

Skills are reusable workflows stored as `skills/<name>/SKILL.md`.

## Frontmatter

Every skill must start with YAML frontmatter:

```yaml
---
name: example-skill
description: Short, action-oriented description of what the skill does.
version: 1.0.0
when_to_use: User asks for this workflow or a closely related task.
inputs:
  - name: target
    description: Optional file, directory, command, or domain target.
required_tools: [bash, read, grep]
---
```

Required fields:

- `name`
- `description`
- `version`
- `when_to_use`
- `required_tools`

## Body structure

Use this structure unless the domain needs something more specific:

```markdown
# Example Skill

## Goal

State the outcome.

## Workflow

1. Inspect the smallest relevant local context.
2. Apply the domain checklist.
3. Make only scoped edits when the user asked for edits.
4. Verify with discovered project commands when possible.
5. Report concrete results, files, commands, and residual risks.

## Guardrails

- Do not invent facts, test results, issue links, or external references.
- Do not perform destructive actions without explicit user approval.
- Preserve project conventions and security boundaries.
```

## Naming

- Directory name and frontmatter `name` must match.
- Use lowercase kebab-case.
- Prefer domain + action names such as `tizen-build-package` or `rust-clippy-triage`.

## Validation

```bash
bash tests/lint-skills.sh
```
