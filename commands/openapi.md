---
description: "Validate a local OpenAPI or Swagger specification."
argument_hint: "[optional arguments]"
allowed_tools: [bash, read, grep]
routes_to_skill: openapi-validator
---

<command-instruction>
Run the `openapi-validator` skill workflow on the user's request.

When to use: User asks "/openapi", "validate this spec", or has just edited `openapi.yaml`/`swagger.json` and wants a quick consistency pass before publishing or generating clients.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`openapi-validator`) is not installed in this environment, follow the
workflow described in skills/openapi-validator/SKILL.md.
</command-instruction>

<handoff-context-policy id="diff-review">
keep: latest_user, command_instruction, changed_files, diffs, nearby_code, failing_checks
summarize: bash, grep, read, prior_assistant
drop: unrelated_history, stale_tool_results
</handoff-context-policy>
