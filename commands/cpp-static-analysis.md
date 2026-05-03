---
description: Run clang-tidy or cppcheck on changed C/C++ files only and categorize the results.
argument_hint: "[target path or check set]"
allowed_tools: [bash, read, edit]
---

<command-instruction>
You are running the C++ static analysis workflow. Invoke the `cpp-static-analysis` skill with the user's optional `target` and `checks` arguments.

Prefer clang-tidy over cppcheck when both are installed. Detect `compile_commands.json`; warn if missing. Triage every diagnostic into AUTO-FIXABLE / MANUAL-FIXABLE / IGNORE-CANDIDATE. Apply autofixes only per-file with explicit user approval. Never insert `// NOLINT` to silence warnings. Report findings in English with file:line:column references.
</command-instruction>
