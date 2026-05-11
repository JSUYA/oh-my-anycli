---
description: "Apply Karpathy-inspired LLM coding guidelines to the current task: think first, simplify, make surgical edits, and define verifiable goals."
argument_hint: "(no arguments; apply the full guideline set)"
allowed_tools: [read]
routes_to_skill: karpathy-guidelines
---

<command-instruction>
Run the `karpathy-guidelines` skill workflow on the user's request.

When to use: User invokes "/karpathy", "/guidelines", or asks for the Karpathy guidelines explicitly. Also invoke at the START of any non-trivial coding task as a self-checklist before reaching for the keyboard.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`karpathy-guidelines`) is not installed in this environment, follow the
workflow described in skills/karpathy-guidelines/SKILL.md.
</command-instruction>

<handoff-context-policy id="doc-explain">
keep: latest_user, command_instruction, requested_files, read_results, identifiers
summarize: bash, search_results, prior_assistant
drop: unrelated_history, stale_tool_results
</handoff-context-policy>
