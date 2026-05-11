---
description: "Create integration tests for a feature boundary."
argument_hint: "[optional arguments]"
allowed_tools: [bash, read, edit]
routes_to_skill: integration-test-writer
---

<command-instruction>
Run the `integration-test-writer` skill workflow on the user's request.

When to use: User asks "/test-int", "write integration tests for the auth flow", or wants end-to-end coverage of a feature touching the DB or HTTP layer. Use after a feature ships and unit coverage is in place.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`integration-test-writer`) is not installed in this environment, follow the
workflow described in skills/integration-test-writer/SKILL.md.
</command-instruction>

<handoff-context-policy id="test-writing">
keep: latest_user, command_instruction, target_file, existing_tests, test_failures, coverage_summary
summarize: bash, grep, read, prior_assistant
drop: unrelated_history, stale_tool_results
</handoff-context-policy>
