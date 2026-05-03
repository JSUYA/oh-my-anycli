---
name: refactor-helper
description: Performs small, targeted refactors only — extract function, rename, dead-code removal, simplify conditional. Explicitly refuses grand refactors and architectural rewrites.
version: 1.0.0
when_to_use: User asks "/refactor", "extract this into a function", "rename this variable across the file", or "remove this dead code". Do NOT use for "redesign this module" or "convert to TypeScript".
inputs:
  - name: scope
    description: Target file path and the specific refactor requested (e.g. "src/auth.ts — extract validateToken helper").
required_tools: [bash, read]
---

# Refactor Helper Skill

## Goal

Guide a scoped refactor with verification steps.

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
