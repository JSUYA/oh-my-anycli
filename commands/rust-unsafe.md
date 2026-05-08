---
description: "Audit unsafe blocks in changed Rust files with a safety checklist and categorized findings."
argument_hint: "[path]"
allowed_tools: [bash, read]
routes_to_skill: rust-unsafe-review
---

<command-instruction>
Run the `rust-unsafe-review` skill workflow on the user's request.

When to use: User invokes "/rust-unsafe", asks to "audit unsafe blocks", or wants a soundness review before merging FFI/perf code.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`rust-unsafe-review`) is not installed in this environment, follow the
workflow described in skills/rust-unsafe-review/SKILL.md.
</command-instruction>
