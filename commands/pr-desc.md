---
description: "Draft a pull request description from commits and diff context."
argument_hint: "[optional arguments]"
allowed_tools: [bash, read]
routes_to_skill: pr-description-writer
---

<command-instruction>
Run the `pr-description-writer` skill workflow on the user's request.

When to use: User asks "/pr-desc", "write the PR description", or "summarize this branch for review". Run after commits land on the branch and before opening the PR.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`pr-description-writer`) is not installed in this environment, follow the
workflow described in skills/pr-description-writer/SKILL.md.
</command-instruction>
