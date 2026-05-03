# Agent Authoring

Agents are subagent definitions stored as `agents/<name>.md`.

## Frontmatter

```yaml
---
name: code-reviewer
description: Specialist subagent for reviewing source diffs.
mode: subagent
model: cline/default
tools:
  bash: true
  read: true
  grep: true
---
```

Required constraints:

- `mode` must be `subagent`.
- `model` must be `cline/default`.
- Tool access must be explicit.

## Body

Each agent should define:

- mission
- operating principles
- workflow
- output expectations
- safety boundaries

## Guidelines

- Keep agents specialized and reusable.
- Prefer read-only behavior unless the role needs edits.
- Cite files, commands, and observed behavior when making claims.
- Do not allow destructive actions without explicit user approval.

## Validation

```bash
bash tests/lint-agents.sh
```
