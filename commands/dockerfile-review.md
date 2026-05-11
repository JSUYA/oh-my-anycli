---
description: "Review a Dockerfile for security, reproducibility, and runtime hygiene."
argument_hint: "[optional arguments]"
allowed_tools: [bash, read]
routes_to_skill: dockerfile-review
---

<command-instruction>
Run the `dockerfile-review` skill workflow on the user's request.

When to use: User asks "/dockerfile-review", "review this Dockerfile", or has just authored or modified a Dockerfile and wants a sanity pass before committing. Useful before a base-image bump or before publishing a new image to an internal registry.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`dockerfile-review`) is not installed in this environment, follow the
workflow described in skills/dockerfile-review/SKILL.md.
</command-instruction>

<handoff-context-policy id="diff-review">
keep: latest_user, command_instruction, changed_files, diffs, nearby_code, failing_checks
summarize: bash, grep, read, prior_assistant
drop: unrelated_history, stale_tool_results
</handoff-context-policy>
