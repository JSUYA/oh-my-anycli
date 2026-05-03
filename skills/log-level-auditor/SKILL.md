---
name: log-level-auditor
description: Finds inappropriate logging in source code — `console.log` in production JS, `print()` in non-test Python, `fmt.Println` in non-main Go, `dbg!` in Rust, `puts` in Ruby app code. Distinguishes test files (allowed) and suggests replacement with the project's logger if one is detected.
version: 1.0.0
when_to_use: User asks "/log-audit", "any console.log left", "what print statements still in the codebase". Useful before a release or after picking up an unfamiliar repository where prior debugging code may have leaked.
inputs:
  - name: target
    description: Optional file or directory to scope the scan to. Defaults to the project root.
required_tools: [bash, read, grep]
---

# Log Level Auditor Skill

## Goal

Audit logging statements and recommend project logger usage.

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
