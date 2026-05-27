---
description: "Pick and preview the right sdb command for Tizen device actions such as install, launch, logs, file transfer, screenshot, shell, port forwarding, and reboot."
argument_hint: "[sdb action request]"
allowed_tools: [bash, read]
routes_to_skill: tizen-sdb-helper
---

<command-instruction>
Run the `tizen-sdb-helper` skill workflow on the user's request.

When to use: User asks for one sdb action ("install this tpk", "tail the logs", "screenshot the TV", "push this file", "open a shell", "forward port 9229", "reboot the device"), or invokes a named recipe like "install-and-launch", "install-launch-and-log", "reinstall-and-launch", or "kill-and-relaunch".

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`tizen-sdb-helper`) is not installed in this environment, follow the
workflow described in skills/tizen-sdb-helper/SKILL.md.
</command-instruction>

<handoff-context-policy id="debug-diagnose">
keep: latest_user, command_instruction, requested_files, read_results, bash
summarize: search_results, prior_assistant
drop: unrelated_history, stale_tool_results
</handoff-context-policy>
