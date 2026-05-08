---
description: "Find deprecated Tizen native API usage in changed files and report replacement functions, headers, and migration notes."
argument_hint: "[path or target_api, for example 8.0]"
allowed_tools: [bash, read]
routes_to_skill: tizen-api-modernize
---

<command-instruction>
Run the `tizen-api-modernize` skill workflow on the user's request.

When to use: User invokes "/tizen-api-modernize", asks to "find deprecated Tizen APIs", or wants a migration plan before bumping the package's api-version.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`tizen-api-modernize`) is not installed in this environment, follow the
workflow described in skills/tizen-api-modernize/SKILL.md.
</command-instruction>
