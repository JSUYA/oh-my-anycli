---
description: "Diagnose an error from local logs, code, and recent changes."
argument_hint: "<error message + (optional) stack trace>"
allowed_tools: [bash, read, grep]
routes_to_skill: error-diagnose
---

<command-instruction>
Run the `error-diagnose` skill workflow on the user's request.

When to use: User pastes an error/stack trace, says "this broke", "/diagnose this error", or asks for help interpreting a panic/exception/assertion. Useful before opening a bug ticket.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`error-diagnose`) is not installed in this environment, follow the
workflow described in skills/error-diagnose/SKILL.md.
</command-instruction>

<handoff-context-policy id="debug-diagnose">
keep: latest_user, command_instruction, error_text, stack_trace, failing_command, relevant_files
summarize: successful_tool_output, repeated_logs, prior_assistant
drop: unrelated_history, stale_tool_results
</handoff-context-policy>
