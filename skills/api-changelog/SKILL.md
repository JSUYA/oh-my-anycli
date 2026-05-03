---
name: api-changelog
description: Compares two OpenAPI / GraphQL spec files (or two git revisions of the same spec) and produces a structured breaking-change report — removed endpoints, changed parameter types, removed enum values, response shape changes. Categorized as BREAKING / NON-BREAKING / ADDITIVE. Korean summary.
version: 1.0.0
when_to_use: User asks "/api-diff", "what changed in this spec", or before publishing a new API version. Useful for downstream client teams who need a heads-up on breaking changes.
inputs:
  - name: old_spec
    description: Path to the older spec file, OR a git revision (e.g. "HEAD~1:openapi.yaml", "v1.2.0:openapi.yaml").
  - name: new_spec
    description: Path to the newer spec file, OR a git revision. Defaults to the current working-tree version of the same path as `old_spec`.
required_tools: [bash, read, grep]
---

# Api Changelog Skill

## Goal

Compare API specs and report breaking, non-breaking, and additive changes.

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
