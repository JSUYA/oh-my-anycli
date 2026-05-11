---
description: "Draft a database migration with rollback and verification notes."
argument_hint: "[optional arguments]"
allowed_tools: [bash, read, edit]
routes_to_skill: migration-writer
---

<command-instruction>
Run the `migration-writer` skill workflow on the user's request.

When to use: User asks "/migration", "add a migration for X", "write a column-rename migration", or has just changed an ORM model and needs the corresponding schema change. Useful before creating PRs that touch persistent data.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`migration-writer`) is not installed in this environment, follow the
workflow described in skills/migration-writer/SKILL.md.
</command-instruction>

<handoff-context-policy id="diff-review">
keep: latest_user, command_instruction, changed_files, diffs, nearby_code, failing_checks
summarize: bash, grep, read, prior_assistant
drop: unrelated_history, stale_tool_results
</handoff-context-policy>
