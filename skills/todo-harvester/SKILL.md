---
name: todo-harvester
description: Finds and categorizes TODO/FIXME/HACK/XXX/NOTE comments across the repository. Groups by severity heuristic (HACK/FIXME high, TODO medium, NOTE low) and surfaces age via git blame so older items rank higher. Honors .gitignore.
version: 1.0.0
when_to_use: User asks "/todo", "what TODOs are still open", "any FIXMEs left in this module". Useful before a release, before handing off a project, or during a quarterly tech-debt review.
inputs:
  - name: target
    description: Optional path (file or directory) to scope the harvest. Defaults to the project root.
  - name: max_age_days
    description: Optional. If set, hide items younger than this many days (good for "show me anything older than 60 days"). Defaults to 0 (show all).
required_tools: [bash, read, grep]
---

# Todo Harvester Skill

## Goal

Collect TODO comments and classify follow-up work.

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
