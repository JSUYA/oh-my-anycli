---
description: "Run the existing coverage tool and summarize coverage gaps."
argument_hint: "[optional arguments]"
allowed_tools: [bash, read]
routes_to_skill: test-coverage-reporter
---

<command-instruction>
Run the `test-coverage-reporter` skill workflow on the user's request.

When to use: User asks "/coverage", "what's our test coverage?", "show coverage gaps", or wants a pre-PR check that new code is covered. Useful right after `/test` or before opening a PR.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`test-coverage-reporter`) is not installed in this environment, follow the
workflow described in skills/test-coverage-reporter/SKILL.md.
</command-instruction>
