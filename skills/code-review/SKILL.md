---
name: code-review
description: Reviews changed files on the current git branch and surfaces concrete, actionable issues across correctness, security, performance, style, and test coverage with file:line references.
version: 1.0.0
when_to_use: User asks for a code review, opens a PR locally, or invokes "/review". Also useful before pushing a feature branch.
inputs:
  - name: pr_or_branch
    description: Optional PR number or branch name. Defaults to the current checked-out branch compared against its merge base with main/master.
required_tools: [bash, read]
---

# Code Review Skill

## Goal

Review code changes and report actionable findings.

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
