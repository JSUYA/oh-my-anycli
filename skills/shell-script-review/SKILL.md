---
name: shell-script-review
description: Reviews bash/zsh scripts for safety basics — set -euo pipefail, quoted variable expansions, unsafe eval/source, missing -- before user args, race-prone temp files, and shellcheck-style issues we can grep for. Local file only.
version: 1.0.0
when_to_use: User asks "/shell-review", "review this script", or has just authored or modified a `.sh`/`.bash`/`.zsh` script. Useful before committing build/deploy scripts.
inputs:
  - name: script_path
    description: Path to the shell script to review. Required. Multiple paths may be passed space-separated.
required_tools: [bash, read, grep]
---

# Shell Script Review Skill

## Goal

Review shell scripts for safety and portability.

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
