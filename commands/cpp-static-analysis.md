---
description: "Run clang-tidy or cppcheck on changed C/C++ files only and categorize the results."
argument_hint: "[target path or check set]"
allowed_tools: [bash, read, edit]
routes_to_skill: cpp-static-analysis
---

<command-instruction>
Run the `cpp-static-analysis` skill workflow on the user's request.

When to use: User invokes "/cpp-static-analysis", asks to "run clang-tidy", or wants a static-analysis pass before opening a PR.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`cpp-static-analysis`) is not installed in this environment, follow the
workflow described in skills/cpp-static-analysis/SKILL.md.
</command-instruction>
