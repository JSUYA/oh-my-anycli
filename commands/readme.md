---
description: "Draft a README from project structure without overwriting existing docs."
argument_hint: "[optional arguments]"
allowed_tools: [bash, read, edit]
routes_to_skill: readme-bootstrap
---

<command-instruction>
Run the `readme-bootstrap` skill workflow on the user's request.

When to use: User asks "/readme", "draft a README", or starts a new project that lacks one. Useful for spinning up a sane skeleton you then edit.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`readme-bootstrap`) is not installed in this environment, follow the
workflow described in skills/readme-bootstrap/SKILL.md.
</command-instruction>

<handoff-context-policy id="doc-explain">
keep: latest_user, command_instruction, requested_files, read_results, identifiers
summarize: bash, search_results, prior_assistant
drop: unrelated_history, stale_tool_results
</handoff-context-policy>
