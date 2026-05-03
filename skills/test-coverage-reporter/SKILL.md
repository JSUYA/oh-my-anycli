---
name: test-coverage-reporter
description: Runs the project's existing coverage tool, summarizes overall and per-file results, and highlights recently-changed files that lack coverage. No external services or upload steps.
version: 1.0.0
when_to_use: User asks "/coverage", "what's our test coverage?", "show coverage gaps", or wants a pre-PR check that new code is covered. Useful right after `/test` or before opening a PR.
inputs:
  - name: scope
    description: Optional path or glob to scope the coverage run. Defaults to the project default.
required_tools: [bash, read]
---

# Test Coverage Reporter Skill

## Goal

Summarize test coverage and gaps.

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
