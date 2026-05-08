---
description: "Find likely unused code without deleting anything automatically."
argument_hint: "[optional arguments]"
allowed_tools: [bash, read, grep]
routes_to_skill: dead-code-finder
---

<command-instruction>
Run the `dead-code-finder` skill workflow on the user's request.

When to use: User asks "/dead-code", "any unused code?", "clean up imports", or wants to prune a module before refactoring. Useful before extracting a library or shrinking a bundle.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`dead-code-finder`) is not installed in this environment, follow the
workflow described in skills/dead-code-finder/SKILL.md.
</command-instruction>
