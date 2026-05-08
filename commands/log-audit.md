---
description: "Find logging statements that may be inappropriate for production code."
argument_hint: "[optional arguments]"
allowed_tools: [bash, read, grep]
routes_to_skill: log-level-auditor
---

<command-instruction>
Run the `log-level-auditor` skill workflow on the user's request.

When to use: User asks "/log-audit", "any console.log left", "what print statements still in the codebase". Useful before a release or after picking up an unfamiliar repository where prior debugging code may have leaked.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`log-level-auditor`) is not installed in this environment, follow the
workflow described in skills/log-level-auditor/SKILL.md.
</command-instruction>
