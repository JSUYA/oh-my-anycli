---
description: "Create or update unit tests for the requested code."
argument_hint: "<source-path>[:functionName]"
allowed_tools: [bash, read, edit]
routes_to_skill: unit-test-writer
---

<command-instruction>
Run the `unit-test-writer` skill workflow on the user's request.

When to use: User asks "/test path/to/file.ts", "write tests for X", or wants test coverage for a newly-added function. Use after implementing new code, or to backfill missing tests.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`unit-test-writer`) is not installed in this environment, follow the
workflow described in skills/unit-test-writer/SKILL.md.
</command-instruction>
