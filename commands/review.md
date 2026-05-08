---
description: "Review current branch changes against the merge base."
argument_hint: "[optional arguments]"
allowed_tools: [bash, read]
routes_to_skill: code-review
---

<command-instruction>
Run the `code-review` skill workflow on the user's request.

When to use: User asks for a code review, opens a PR locally, or invokes "/review". Also useful before pushing a feature branch.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`code-review`) is not installed in this environment, follow the
workflow described in skills/code-review/SKILL.md.
</command-instruction>
