---
description: "Plan and apply a scoped refactor with behavior checks."
argument_hint: "[optional arguments]"
allowed_tools: [bash, read, edit]
routes_to_skill: refactor-helper
---

<command-instruction>
Run the `refactor-helper` skill workflow on the user's request.

When to use: User asks "/refactor", "extract this into a function", "rename this variable across the file", or "remove this dead code". Do NOT use for "redesign this module" or "convert to TypeScript".

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`refactor-helper`) is not installed in this environment, follow the
workflow described in skills/refactor-helper/SKILL.md.
</command-instruction>

<handoff-context-policy id="diff-review">
keep: latest_user, command_instruction, changed_files, diffs, nearby_code, failing_checks
summarize: bash, grep, read, prior_assistant
drop: unrelated_history, stale_tool_results
</handoff-context-policy>
