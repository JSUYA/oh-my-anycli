---
description: "sudo 또는 다른 인터랙티브 입력(ssh-add, gh auth login 등)을 opencode-anycli 안에서 동작시키는 방법을 안내합니다."
argument_hint: "(인자 없음)"
allowed_tools: [bash, read]
routes_to_skill: sudo-helper
---

<command-instruction>
Run the `sudo-helper` skill workflow on the user's request.

When to use: User asks "how do I sudo inside opencode-anycli?", "sudo says no tty", "ssh-add hangs", "gh auth login asks for input but nothing happens", or invokes "/sudo". Also useful when a skill the agent is running needs root privileges and the bash tool errors out.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`sudo-helper`) is not installed in this environment, follow the
workflow described in skills/sudo-helper/SKILL.md.
</command-instruction>
