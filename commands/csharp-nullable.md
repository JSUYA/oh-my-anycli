---
description: "Enable nullable reference types for a C# project and categorize the resulting CS86xx warnings."
argument_hint: "[csproj path or scope (file|project|solution)]"
allowed_tools: [bash, read, edit]
routes_to_skill: csharp-nullable-migrate
---

<command-instruction>
Run the `csharp-nullable-migrate` skill workflow on the user's request.

When to use: User invokes "/csharp-nullable", asks to "enable NRT", or wants to migrate a project to nullable annotations safely.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`csharp-nullable-migrate`) is not installed in this environment, follow the
workflow described in skills/csharp-nullable-migrate/SKILL.md.
</command-instruction>

<handoff-context-policy id="diff-review">
keep: latest_user, command_instruction, changed_files, diffs, nearby_code, failing_checks
summarize: bash, grep, read, prior_assistant
drop: unrelated_history, stale_tool_results
</handoff-context-policy>
