---
description: "Collect TODO and FIXME comments into a prioritized report."
argument_hint: "[optional arguments]"
allowed_tools: [bash, read, grep]
routes_to_skill: todo-harvester
---

<command-instruction>
Run the `todo-harvester` skill workflow on the user's request.

When to use: User asks "/todo", "what TODOs are still open", "any FIXMEs left in this module". Useful before a release, before handing off a project, or during a quarterly tech-debt review.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`todo-harvester`) is not installed in this environment, follow the
workflow described in skills/todo-harvester/SKILL.md.
</command-instruction>
