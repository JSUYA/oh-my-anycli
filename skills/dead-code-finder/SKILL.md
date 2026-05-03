---
name: dead-code-finder
description: Finds unused exports, unused imports, and unreachable code. Uses language-aware tools when installed (tsc, ruff, vulture, staticcheck) and falls back to a grep-based shallow check otherwise. Always presents findings; never deletes without confirmation.
version: 1.0.0
when_to_use: User asks "/dead-code", "any unused code?", "clean up imports", or wants to prune a module before refactoring. Useful before extracting a library or shrinking a bundle.
inputs:
  - name: target
    description: Optional file or directory to scope the scan to. Defaults to the project's source root (src/, lib/, app/, or pkg/ — first match).
required_tools: [bash, read, grep]
---

# Dead Code Finder Skill

## Goal

Find likely unused exports, imports, and unreachable code.

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
