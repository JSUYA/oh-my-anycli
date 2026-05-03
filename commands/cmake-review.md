---
description: Review CMakeLists.txt against modern CMake practices and report prioritized findings.
argument_hint: "[CMakeLists.txt path or directory]"
allowed_tools: [bash, read]
---

<command-instruction>
You are running the CMake review workflow. Invoke the `cmake-review` skill with the user's optional `target` argument.

Read the `cmake_minimum_required` value first; do not recommend bumping it without warning the user about policy changes. Apply the checklist (target_-prefixed commands, file(GLOB), policies, find_package vs FetchContent, install rules, CTest gating). Output findings only — never edit CMakeLists.txt. Report in English with file:line references and HIGH/MEDIUM/LOW severity tags.
</command-instruction>
