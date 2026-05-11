---
description: "Check tizen-manifest.xml for API version, application type, package ID, privileges, features, categories, and metadata consistency."
argument_hint: "[tizen-manifest.xml path or project directory]"
allowed_tools: [bash, read]
routes_to_skill: tizen-manifest-review
---

<command-instruction>
Run the `tizen-manifest-review` skill workflow on the user's request.

When to use: User invokes "/tizen-manifest", asks to "review the Tizen manifest", or wants a sanity check before signing/packaging a TPK/WGT.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`tizen-manifest-review`) is not installed in this environment, follow the
workflow described in skills/tizen-manifest-review/SKILL.md.
</command-instruction>

<handoff-context-policy id="diff-review">
keep: latest_user, command_instruction, changed_files, diffs, nearby_code, failing_checks
summarize: bash, grep, read, prior_assistant
drop: unrelated_history, stale_tool_results
</handoff-context-policy>
