---
name: explain-code
description: Explains a function, file, or module at the requested depth (summary, walkthrough, deep-dive). Korean explanation with English code identifiers preserved. Traces callers/callees via grep when feasible and lists related files.
version: 1.0.0
when_to_use: User asks "/explain", "what does this do?", "walk me through this file", or wants onboarding context on an unfamiliar module. Read-only — never modifies code.
inputs:
  - name: target
    description: Path to a file, optionally with a function-qualified suffix (e.g. "src/auth.ts:validateToken").
  - name: depth
    description: One of "summary" (3-5 sentences), "walkthrough" (key steps in order), or "deep-dive" (full control flow, edge cases, callers). Defaults to "walkthrough".
required_tools: [bash, read, grep]
---

# Explain Code Skill

## Goal

Explain code clearly for the requested audience.

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
