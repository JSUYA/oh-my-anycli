---
description: "Explain code in clear English while preserving technical identifiers."
argument_hint: "<path[:functionName]> [depth=summary|walkthrough|deep-dive]"
allowed_tools: [bash, read, grep]
routes_to_skill: explain-code
---

<command-instruction>
Run the `explain-code` skill workflow on the user's request.

When to use: User asks "/explain", "what does this do?", "walk me through this file", or wants onboarding context on an unfamiliar module. Read-only — never modifies code.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`explain-code`) is not installed in this environment, follow the
workflow described in skills/explain-code/SKILL.md.
</command-instruction>
