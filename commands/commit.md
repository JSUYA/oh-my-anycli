---
description: "Prepare a scoped Git commit message and commit flow."
argument_hint: "[optional arguments]"
allowed_tools: [bash, read]
routes_to_skill: git-commit-helper
---

<command-instruction>
Run the `git-commit-helper` skill workflow on the user's request.

When to use: User asks "/commit", "make a commit message", or has staged changes ready to commit. Especially useful when the user wants a concise Conventional Commits-style message.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`git-commit-helper`) is not installed in this environment, follow the
workflow described in skills/git-commit-helper/SKILL.md.
</command-instruction>

<handoff-context-policy id="release-git">
keep: latest_user, command_instruction, git_status, staged_diff, commit_log, changed_files
summarize: full_diff, successful_tool_output, prior_assistant
drop: unrelated_history, stale_tool_results
</handoff-context-policy>
