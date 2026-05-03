---
description: tizen-manifest.xml에 선언된 권한과 실제 소스 코드의 API 호출을 대조해 UNUSED/MISSING 권한을 보고합니다.
argument_hint: "[프로젝트 경로]"
allowed_tools: [bash, read]
---

<command-instruction>
You are running the Tizen privilege audit workflow. Invoke the `tizen-privilege-audit` skill with the user's optional `target` argument.

Extract declared privileges from tizen-manifest.xml. Use the curated privilege ↔ API mapping table embedded in the skill body (do not fetch from the internet). Cross-check against C/C++/C# source files. Report UNUSED-PRIVILEGE (declared but no matching call) and MISSING-PRIVILEGE (API used but privilege not declared) with file:line references for every match. Never auto-edit the manifest; report findings only and let the user decide. Report in English.
</command-instruction>
