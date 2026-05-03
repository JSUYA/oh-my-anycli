---
name: ci-config-validator
description: Validates a CI configuration file (GitHub Actions, GitLab CI, Jenkins, CircleCI) for matrix completeness, secret-handling patterns, pinned third-party action versions, timeout settings, and concurrency cancellation. Local file only — no API calls.
version: 1.0.0
when_to_use: User asks "/ci-config", "review my workflow", or has just modified `.github/workflows/*.yml`, `.gitlab-ci.yml`, `Jenkinsfile`, or `.circleci/config.yml`. Useful before pushing CI changes that could leak secrets or run forever.
inputs:
  - name: ci_path
    description: Optional explicit path to a CI config file. If omitted, the skill auto-detects the first existing CI config in the repository.
required_tools: [bash, read, grep]
---

# Ci Config Validator Skill

## Goal

Validate CI configuration files with static checks.

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
