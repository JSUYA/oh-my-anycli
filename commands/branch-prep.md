---
description: "Check whether the current branch is ready for review."
argument_hint: "[optional arguments]"
allowed_tools: [bash, read]
routes_to_skill: branch-prep
---

<command-instruction>
Run the `branch-prep` skill workflow on the user's request.

When to use: User asks "/branch-prep", "ready this branch for PR", or "rebase and push for review". Useful right before opening a PR.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`branch-prep`) is not installed in this environment, follow the
workflow described in skills/branch-prep/SKILL.md.
</command-instruction>
