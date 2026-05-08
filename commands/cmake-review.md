---
description: "Review CMakeLists.txt against modern CMake practices and report prioritized findings."
argument_hint: "[CMakeLists.txt path or directory]"
allowed_tools: [bash, read]
routes_to_skill: cmake-review
---

<command-instruction>
Run the `cmake-review` skill workflow on the user's request.

When to use: User invokes "/cmake-review", asks to "review the CMake build", or wants a sanity check on a new CMakeLists.txt before merging.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`cmake-review`) is not installed in this environment, follow the
workflow described in skills/cmake-review/SKILL.md.
</command-instruction>
