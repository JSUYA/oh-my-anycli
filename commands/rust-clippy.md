---
description: "Run cargo clippy on changed files, categorize the findings, and apply automatic fixes only when approved."
argument_hint: "[package or path]"
allowed_tools: [bash, read, edit]
routes_to_skill: rust-clippy-triage
---

<command-instruction>
Run the `rust-clippy-triage` skill workflow on the user's request.

When to use: User invokes "/rust-clippy", asks to "triage clippy warnings", or wants a clippy pass before opening a PR.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`rust-clippy-triage`) is not installed in this environment, follow the
workflow described in skills/rust-clippy-triage/SKILL.md.
</command-instruction>
