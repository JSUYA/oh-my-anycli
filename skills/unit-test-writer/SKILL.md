---
name: unit-test-writer
description: Generates a unit test file for a given function or source file, auto-detecting the project's existing test framework and matching its style and conventions.
version: 1.0.0
when_to_use: User asks "/test path/to/file.ts", "write tests for X", or wants test coverage for a newly-added function. Use after implementing new code, or to backfill missing tests.
inputs:
  - name: target
    description: Path to the source file (or function-qualified path like "src/util.ts:formatDate") to be tested.
required_tools: [bash, read]
---

# Unit Test Writer Skill

## Goal

Create unit tests for the requested code.

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
