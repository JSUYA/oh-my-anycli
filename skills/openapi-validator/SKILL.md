---
name: openapi-validator
description: Validates a local OpenAPI / Swagger specification for internal consistency — undefined $refs, missing required fields, response status coverage, schema-vs-example mismatches, and security schemes that are defined but never applied. Local file only.
version: 1.0.0
when_to_use: User asks "/openapi", "validate this spec", or has just edited `openapi.yaml`/`swagger.json` and wants a quick consistency pass before publishing or generating clients.
inputs:
  - name: spec_path
    description: Path to the OpenAPI/Swagger spec file (`openapi.yaml`, `openapi.yml`, `openapi.json`, `swagger.json`, etc.). Required.
required_tools: [bash, read, grep]
---

# Openapi Validator Skill

## Goal

Validate local OpenAPI or Swagger specifications.

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
