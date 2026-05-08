---
description: "Review shell scripts for safety and maintainability."
argument_hint: "[optional arguments]"
allowed_tools: [bash, read, grep]
routes_to_skill: shell-script-review
---

<command-instruction>
Run the `shell-script-review` skill workflow on the user's request.

When to use: User asks "/shell-review", "review this script", or has just authored or modified a `.sh`/`.bash`/`.zsh` script. Useful before committing build/deploy scripts.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`shell-script-review`) is not installed in this environment, follow the
workflow described in skills/shell-script-review/SKILL.md.
</command-instruction>
