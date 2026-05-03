---
name: readme-bootstrap
description: Generates an initial README from project structure — detects language(s), entry point, infers purpose from manifest description, and proposes Install/Usage/Development sections. Refuses to overwrite an existing README and writes to README.draft.md instead.
version: 1.0.0
when_to_use: User asks "/readme", "draft a README", or starts a new project that lacks one. Useful for spinning up a sane skeleton you then edit.
inputs:
  - name: scope
    description: Optional path to scope the inference to (e.g., a sub-package directory). Defaults to the project root.
required_tools: [bash, read]
---

# Readme Bootstrap Skill

## Goal

Draft a README from project structure.

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
