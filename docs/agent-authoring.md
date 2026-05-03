# Agent Authoring

This document describes the agent authoring workflow for oh-my-clinecli.

## Purpose

Use this guide to understand how the related skills, commands, agents, or installer behavior should be authored and maintained.

## Guidelines

- Keep all user-facing text in English.
- Keep changes scoped to the relevant artifact.
- Preserve frontmatter fields required by the lint scripts.
- Prefer local project context over invented assumptions.
- Verify changes with the repository test scripts before publishing.

## Validation

```bash
bash tests/lint-skills.sh
bash tests/lint-commands.sh
bash tests/lint-agents.sh
bash tests/verify-install.sh
```
