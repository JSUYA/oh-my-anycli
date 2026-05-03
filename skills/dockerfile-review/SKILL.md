---
name: dockerfile-review
description: Reviews a Dockerfile for image base hygiene, layer cache ordering, secret leak risk, non-root USER, healthcheck, multi-stage opportunities, and the presence of .dockerignore. Refuses to touch ARGs that look like network connectivity settings.
version: 1.0.0
when_to_use: User asks "/dockerfile-review", "review this Dockerfile", or has just authored or modified a Dockerfile and wants a sanity pass before committing. Useful before a base-image bump or before publishing a new image to an internal registry.
inputs:
  - name: dockerfile_path
    description: Optional path to the Dockerfile (default "./Dockerfile"). Accepts variants such as "Dockerfile.build" or "docker/api.Dockerfile".
required_tools: [bash, read]
---

# Dockerfile Review Skill

## Goal

Review Dockerfiles for reproducibility, security, and runtime hygiene.

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
