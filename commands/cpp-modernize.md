---
description: "Migrate changed C/C++ files toward modern C++17/20 idioms and categorize risks."
argument_hint: "[path or standard, for example c++17]"
allowed_tools: [bash, read, edit]
routes_to_skill: cpp-modernize
---

<command-instruction>
Run the `cpp-modernize` skill workflow on the user's request.

When to use: User invokes "/cpp-modernize", asks to "modernize this C++ file", or wants to bring legacy headers up to a current standard before review.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`cpp-modernize`) is not installed in this environment, follow the
workflow described in skills/cpp-modernize/SKILL.md.
</command-instruction>
