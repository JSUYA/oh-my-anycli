---
name: integration-test-writer
description: Generates integration tests that exercise actual external dependencies (DB, API, message bus) or cross-module interactions. Auto-detects framework (jest+supertest, pytest+requests, go testing+testcontainers) and matches existing style. Distinct from unit tests by scope.
version: 1.0.0
when_to_use: User asks "/test-int", "write integration tests for the auth flow", or wants end-to-end coverage of a feature touching the DB or HTTP layer. Use after a feature ships and unit coverage is in place.
inputs:
  - name: target
    description: Path to the source file or feature module under test (e.g. "src/auth/login-flow.ts" or "internal/orders/").
required_tools: [bash, read]
---

# Integration Test Writer Skill

## Goal

Create integration tests around a feature boundary.

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
