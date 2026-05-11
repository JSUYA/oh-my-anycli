---
description: "Convert sync-over-async patterns in changed C# files, such as .Result, .Wait, and .GetAwaiter().GetResult(), to async/await."
argument_hint: "[path or project type (library|aspnetcore|wpf|winforms|console)]"
allowed_tools: [bash, read, edit]
routes_to_skill: csharp-async-modernize
---

<command-instruction>
Run the `csharp-async-modernize` skill workflow on the user's request.

When to use: User invokes "/csharp-async", asks to "convert sync to async", or wants to remove sync-over-async patterns before review.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`csharp-async-modernize`) is not installed in this environment, follow the
workflow described in skills/csharp-async-modernize/SKILL.md.
</command-instruction>

<handoff-context-policy id="diff-review">
keep: latest_user, command_instruction, changed_files, diffs, nearby_code, failing_checks
summarize: bash, grep, read, prior_assistant
drop: unrelated_history, stale_tool_results
</handoff-context-policy>
