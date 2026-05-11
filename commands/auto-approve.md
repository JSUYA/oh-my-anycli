---
description: "opencode-anycli의 auto-approve 사용법을 안내합니다 (재시작 명령 + 한계 설명)."
argument_hint: "(인자 없음)"
allowed_tools: [bash, read]
routes_to_skill: auto-approve
---

<command-instruction>
Run the `auto-approve` skill workflow on the user's request.

When to use: User asks how to skip permission prompts ("yolo", "auto-approve", "stop asking me", "dangerous"), or invokes "/auto-approve". Also useful when the user is frustrated by repeated "Allow this edit?" prompts in a long-running session.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`auto-approve`) is not installed in this environment, follow the
workflow described in skills/auto-approve/SKILL.md.
</command-instruction>

<handoff-context-policy id="doc-explain">
keep: latest_user, command_instruction, requested_files, read_results, identifiers
summarize: bash, search_results, prior_assistant
drop: unrelated_history, stale_tool_results
</handoff-context-policy>
