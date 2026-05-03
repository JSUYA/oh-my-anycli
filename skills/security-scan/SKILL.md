---
name: security-scan
description: Local security scan covering hardcoded secrets, unsafe code patterns, and risky dependency names using regex patterns and an optional user-maintained rule file.
version: 1.0.0
when_to_use: User asks "/security-scan", "any secrets in this repo?", or wants a quick local audit before pushing.
inputs:
  - name: target
    description: Optional path (file or directory) to scan. Defaults to the project root.
required_tools: [bash, read, grep]
---

# Security Scan Skill

## Goal

Run a local security scan for secrets and risky code patterns.

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
