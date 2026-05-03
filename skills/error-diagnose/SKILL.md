---
name: error-diagnose
description: Walks through an error message and optional stack trace — literal interpretation, ranked root-cause hypotheses, one-line fix per cause, and a list of what to gather if the cause is still unclear. Encourages reproducer creation. Policy-neutral.
version: 1.0.0
when_to_use: User pastes an error/stack trace, says "this broke", "/diagnose this error", or asks for help interpreting a panic/exception/assertion. Useful before opening a bug ticket.
inputs:
  - name: error_text
    description: The raw error message and (optionally) stack trace, in the original language. Required.
  - name: file_context
    description: Optional path to the file the error originates from, if known. Improves accuracy of root-cause ranking.
required_tools: [bash, read, grep]
---

# Error Diagnose Skill

## Goal

Diagnose errors from logs, stack traces, and local code context.

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
