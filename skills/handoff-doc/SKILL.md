---
name: handoff-doc
description: Create an engineering handoff document.
version: 1.0.0
when_to_use: Use this when the user asks for handoff doc support.
inputs:
  - name: output_path
description: Create an engineering handoff document.
  - name: handoff_to
description: Create an engineering handoff document.
required_tools: [bash, read, edit, grep]
---

# Handoff Doc Skill

## Goal

Create an engineering handoff document.

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
