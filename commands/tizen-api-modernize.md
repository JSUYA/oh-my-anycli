---
description: 변경된 파일에서 deprecated된 Tizen 네이티브 API 사용을 찾아 교체 함수, 헤더, 마이그레이션 노트를 보고합니다.
argument_hint: "[경로 또는 target_api (예: 8.0)]"
allowed_tools: [bash, read]
---

<command-instruction>
You are running the Tizen API modernize workflow. Invoke the `tizen-api-modernize` skill with the user's optional `target` and `target_api` arguments.

Read `target_api` from `tizen-manifest.xml` if not provided. Use only the curated deprecation table embedded in the skill body (do not fetch from the internet). For each deprecated symbol found in source, report the replacement, header changes, signature/error-code differences, and the deprecation version. Do not auto-rewrite source. Report in English with file:line references.
</command-instruction>
