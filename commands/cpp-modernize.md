---
description: 변경된 C/C++ 파일을 모던 C++17/20 관용구로 마이그레이션하고 위험도별로 분류합니다.
argument_hint: "[경로 또는 표준 (예: c++17)]"
allowed_tools: [bash, read, edit]
---

<command-instruction>
You are running the C++ modernize workflow. Invoke the `cpp-modernize` skill with the user's optional `target` and `standard` arguments.

Detect the project's compile standard from `compile_commands.json`, `CMakeLists.txt`, or `Makefile` first. Apply only SAFE hunks after summary approval. Treat NEEDS-REVIEW per-hunk and never apply API-BREAKING changes. Do not silently upgrade the project's standard. Report results in English with file:line references.
</command-instruction>
