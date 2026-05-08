---
description: "Explain a SQL execution plan and suggest tuning options."
argument_hint: "[optional arguments]"
allowed_tools: [bash, read]
routes_to_skill: sql-explain-reader
---

<command-instruction>
Run the `sql-explain-reader` skill workflow on the user's request.

When to use: Use this when the user asks for sql explain reader support.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`sql-explain-reader`) is not installed in this environment, follow the
workflow described in skills/sql-explain-reader/SKILL.md.
</command-instruction>
