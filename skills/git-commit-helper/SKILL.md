---
name: git-commit-helper
description: Drafts a Korean-friendly conventional commit message from the staged changes. Honors any project commit conventions found in CLAUDE.md, AGENTS.md, or CONTRIBUTING; otherwise emits a clean, neutral message.
version: 1.1.0
when_to_use: User asks "/commit", "make a commit message", or has staged changes ready to commit. Especially useful when the user wants the message in Korean but the commit-type prefix in English (Conventional Commits).
inputs:
  - name: scope_hint
    description: Optional scope (e.g. "auth", "ui") if the user wants to override the auto-detected scope.
required_tools: [bash, read]
---

# Git Commit Helper Skill

## Goal

Prepare a focused Git commit with an appropriate message.

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
