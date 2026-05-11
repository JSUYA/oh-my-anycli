---
description: "Modernize changed Rust files from older patterns to current idioms such as try! to ?, manual loops to iterators, and clearer error handling."
argument_hint: "[path or error pattern (anyhow|thiserror|eyre|std)]"
allowed_tools: [bash, read, edit]
routes_to_skill: rust-idiom-modernize
---

<command-instruction>
Run the `rust-idiom-modernize` skill workflow on the user's request.

When to use: User invokes "/rust-modernize", asks to "modernize this Rust code", or wants idiom cleanup before review.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`rust-idiom-modernize`) is not installed in this environment, follow the
workflow described in skills/rust-idiom-modernize/SKILL.md.
</command-instruction>

<handoff-context-policy id="diff-review">
keep: latest_user, command_instruction, changed_files, diffs, nearby_code, failing_checks
summarize: bash, grep, read, prior_assistant
drop: unrelated_history, stale_tool_results
</handoff-context-policy>
