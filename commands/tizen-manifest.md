---
description: Check tizen-manifest.xml for API version, application type, package ID, privileges, features, categories, and metadata consistency.
argument_hint: "[tizen-manifest.xml path or project directory]"
allowed_tools: [bash, read]
---

<command-instruction>
You are running the Tizen manifest review workflow. Invoke the `tizen-manifest-review` skill with the user's optional `target` argument.

Walk the manifest with grep + read (do not require xmllint). Apply the checklist for root attributes, application element choice, privileges, features, categories, metadata, icons, accounts, and background categories. Output findings only — never edit the manifest. Refuse to recommend privilege removal (cross-checking belongs to the privilege-audit skill). Report in English with file:line references and HIGH/MEDIUM/LOW severity tags.
</command-instruction>
