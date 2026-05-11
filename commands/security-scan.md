---
description: "Run a local security scan for secrets and risky code patterns."
argument_hint: "[optional arguments]"
allowed_tools: [bash, read, grep]
routes_to_skill: security-scan
---

<command-instruction>
Run the `security-scan` skill workflow on the user's request.

When to use: User asks "/security-scan", "any secrets in this repo?", or wants a quick local audit before pushing.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`security-scan`) is not installed in this environment, follow the
workflow described in skills/security-scan/SKILL.md.
</command-instruction>

<handoff-context-policy id="diff-review">
keep: latest_user, command_instruction, changed_files, diffs, nearby_code, failing_checks
summarize: bash, grep, read, prior_assistant
drop: unrelated_history, stale_tool_results
</handoff-context-policy>
