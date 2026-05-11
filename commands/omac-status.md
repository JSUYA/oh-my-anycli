---
description: "Summarize the installed oh-my-anycli status."
argument_hint: "[optional arguments]"
allowed_tools: [bash]
---

<command-instruction>
This command is implemented by the `omac` CLI itself, not by an LLM skill.
When invoked, run the appropriate `omac` subcommand and report its output.
Do not attempt destructive operations beyond what `omac` itself performs.
</command-instruction>

<handoff-context-policy id="doc-explain">
keep: latest_user, command_instruction, requested_files, read_results, identifiers
summarize: bash, search_results, prior_assistant
drop: unrelated_history, stale_tool_results
</handoff-context-policy>
