---
description: Migrate changed C/C++ files toward modern C++17/20 idioms and categorize risks.
argument_hint: "[path or standard, for example c++17]"
allowed_tools: [bash, read, edit]
---

<command-instruction>
You are running the C++ modernize workflow. Invoke the `cpp-modernize` skill with the user's optional `target` and `standard` arguments.

Detect the project's compile standard from `compile_commands.json`, `CMakeLists.txt`, or `Makefile` first. Apply only SAFE hunks after summary approval. Treat NEEDS-REVIEW per-hunk and never apply API-BREAKING changes. Do not silently upgrade the project's standard. Report results in English with file:line references.
</command-instruction>
