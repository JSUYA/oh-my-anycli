---
name: lint-fix
description: Detects the project's configured linter and runs it. Surfaces fixable issues, proposes patches, and applies fixes only after explicit user approval. Refuses to invent a linter that the project did not configure.
version: 1.0.0
when_to_use: User asks "/lint-fix", "run the linter", "fix lint warnings", or wants to clean up a file before review. Useful before opening a PR or after a large refactor.
inputs:
  - name: target
    description: Optional file or directory path to scope the linter to. Defaults to the project root (whatever the linter's default scope is).
required_tools: [bash, read, edit]
---

# Lint Fix Skill

## Goal

Run the configured linter and apply safe fixes with approval.

## Workflow

1. Read the user's request and identify the target files or project area.
2. Gather only the local context needed for the task.
3. Apply the skill's domain checklist with scoped, evidence-backed reasoning.
4. Report findings, edits, or recommendations in English.
5. Include verification steps or residual risks when relevant.

## Output

Use concise English. Preserve code identifiers, file paths, command names, and API names exactly as they appear in the project.

## Guardrails

- Do not invent facts, test results, issue links, or external references.
- Do not make unrelated edits.
- Do not perform destructive actions without explicit user approval.
- Keep examples generic and free of sensitive or organization-specific data.
