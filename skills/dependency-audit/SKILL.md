---
name: dependency-audit
description: Scans package.json, pyproject.toml, and go.mod for outdated, abandoned, or risky dependencies using local project metadata first.
version: 1.0.0
when_to_use: User asks "/audit-deps", "check our dependencies", "any CVEs in this project", or before a release.
inputs:
  - name: project_root
    description: Project root path. Defaults to the current working directory.
required_tools: [bash, read]
---

# Dependency Audit Skill

## Goal

Audit dependencies using local lockfiles and optional advisory indexes.

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
