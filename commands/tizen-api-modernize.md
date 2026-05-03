---
description: Find deprecated Tizen native API usage in changed files and report replacement functions, headers, and migration notes.
argument_hint: "[path or target_api, for example 8.0]"
allowed_tools: [bash, read]
---

<command-instruction>
You are running the Tizen API modernize workflow. Invoke the `tizen-api-modernize` skill with the user's optional `target` and `target_api` arguments.

Read `target_api` from `tizen-manifest.xml` if not provided. Use only the curated deprecation table embedded in the skill body (do not fetch from the internet). For each deprecated symbol found in source, report the replacement, header changes, signature/error-code differences, and the deprecation version. Do not auto-rewrite source. Report in English with file:line references.
</command-instruction>
