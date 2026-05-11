# Agent Authoring

Agents are markdown definitions stored as `agents/<name>.md`. Most are strict
subagents. Coordinator agents may use `mode: all` only when they are explicitly
allow-listed by the test suite.

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

- `mode` must be `subagent`, except audited coordinator agents such as
  `orchestrator` which use `mode: all`.
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
