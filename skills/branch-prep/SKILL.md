---
name: branch-prep
description: Prepares the current feature branch for review by rebasing onto the base branch (with safety checks), running lint and tests, fixing trivially obvious issues, and pushing only after explicit confirmation. Refuses force-push without --force-with-lease consent.
version: 1.0.0
when_to_use: User asks "/branch-prep", "ready this branch for PR", or "rebase and push for review". Useful right before opening a PR.
inputs:
  - name: base
    description: Optional base branch. Defaults to "main", then "master", then "develop" — first existing remote branch wins.
required_tools: [bash, read]
---

# Branch Prep Skill

## Goal

Prepare a branch for review with local Git, lint, and test checks.

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
