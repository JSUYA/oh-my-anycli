---
description: "Compare API specifications and produce a breaking-change report."
argument_hint: "[optional arguments]"
allowed_tools: [bash, read, grep]
routes_to_skill: api-changelog
---

<command-instruction>
Run the `api-changelog` skill workflow on the user's request.

When to use: User asks "/api-diff", "what changed in this spec", or before publishing a new API version. Useful for downstream client teams who need a heads-up on breaking changes.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`api-changelog`) is not installed in this environment, follow the
workflow described in skills/api-changelog/SKILL.md.
</command-instruction>

<handoff-context-policy id="diff-review">
keep: latest_user, command_instruction, changed_files, diffs, nearby_code, failing_checks
summarize: bash, grep, read, prior_assistant
drop: unrelated_history, stale_tool_results
</handoff-context-policy>
