---
description: clang-tidy 또는 cppcheck로 변경된 C/C++ 파일만 정적 분석하고 결과를 분류합니다.
argument_hint: "[대상 경로 또는 체크 셋]"
allowed_tools: [bash, read, edit]
---

<command-instruction>
You are running the C++ static analysis workflow. Invoke the `cpp-static-analysis` skill with the user's optional `target` and `checks` arguments.

Prefer clang-tidy over cppcheck when both are installed. Detect `compile_commands.json`; warn if missing. Triage every diagnostic into AUTO-FIXABLE / MANUAL-FIXABLE / IGNORE-CANDIDATE. Apply autofixes only per-file with explicit user approval. Never insert `// NOLINT` to silence warnings. Report findings in English with file:line:column references.
</command-instruction>
