---
name: pr-description-writer
description: Generates a PR description from commits-since-base and diff statistics. Sections cover Summary, Why, What changed, Testing notes, and Risk. Honors any project PR template if found; otherwise emits a clean neutral structure.
version: 1.0.0
when_to_use: User asks "/pr-desc", "write the PR description", or "summarize this branch for review". Run after commits land on the branch and before opening the PR.
inputs:
  - name: base
    description: Optional base branch. Defaults to "main", then "master", then "develop".
required_tools: [bash, read]
---

# Pr Description Writer Skill

## Goal

Draft a pull request description from branch context.

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
