---
description: tizen-manifest.xml의 API 버전, 애플리케이션 타입, 패키지 ID, 권한, 피처/카테고리/메타데이터 정합성을 점검합니다.
argument_hint: "[tizen-manifest.xml 경로 또는 프로젝트 디렉터리]"
allowed_tools: [bash, read]
---

<command-instruction>
You are running the Tizen manifest review workflow. Invoke the `tizen-manifest-review` skill with the user's optional `target` argument.

Walk the manifest with grep + read (do not require xmllint). Apply the checklist for root attributes, application element choice, privileges, features, categories, metadata, icons, accounts, and background categories. Output findings only — never edit the manifest. Refuse to recommend privilege removal (cross-checking belongs to the privilege-audit skill). Report in English with file:line references and HIGH/MEDIUM/LOW severity tags.
</command-instruction>
