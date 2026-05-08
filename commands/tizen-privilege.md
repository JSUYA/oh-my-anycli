---
description: "Compare privileges declared in tizen-manifest.xml with API calls in source code and report UNUSED or MISSING privileges."
argument_hint: "[project path]"
allowed_tools: [bash, read]
routes_to_skill: tizen-privilege-audit
---

<command-instruction>
Run the `tizen-privilege-audit` skill workflow on the user's request.

When to use: User invokes "/tizen-privilege", asks to "audit Tizen privileges", or wants to verify the manifest matches actual API usage before a release.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`tizen-privilege-audit`) is not installed in this environment, follow the
workflow described in skills/tizen-privilege-audit/SKILL.md.
</command-instruction>
