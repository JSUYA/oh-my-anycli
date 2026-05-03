---
description: Compare privileges declared in tizen-manifest.xml with API calls in source code and report UNUSED or MISSING privileges.
argument_hint: "[project path]"
allowed_tools: [bash, read]
---

<command-instruction>
You are running the Tizen privilege audit workflow. Invoke the `tizen-privilege-audit` skill with the user's optional `target` argument.

Extract declared privileges from tizen-manifest.xml. Use the curated privilege ↔ API mapping table embedded in the skill body (do not fetch from the internet). Cross-check against C/C++/C# source files. Report UNUSED-PRIVILEGE (declared but no matching call) and MISSING-PRIVILEGE (API used but privilege not declared) with file:line references for every match. Never auto-edit the manifest; report findings only and let the user decide. Report in English.
</command-instruction>
