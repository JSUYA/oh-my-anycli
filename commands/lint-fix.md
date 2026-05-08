---
description: "Run the configured linter and apply fixes only after user approval."
argument_hint: "[optional arguments]"
allowed_tools: [bash, read, edit]
routes_to_skill: lint-fix
---

<command-instruction>
Run the `lint-fix` skill workflow on the user's request.

When to use: User asks "/lint-fix", "run the linter", "fix lint warnings", or wants to clean up a file before review. Useful before opening a PR or after a large refactor.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`lint-fix`) is not installed in this environment, follow the
workflow described in skills/lint-fix/SKILL.md.
</command-instruction>
