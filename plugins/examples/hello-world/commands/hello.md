---
description: Run the hello workflow.
argument_hint: "[optional arguments]"
allowed_tools: []
---

<command-instruction>
Run the `hello` skill from the hello-world plugin.

This is a no-op canary command: it prints exactly one greeting line and
returns. Use it after `omac plugin add` to confirm that a plugin's
commands, skills, and agents all reached the target config directory.

If the `hello` skill is not installed in this environment, the plugin
pipeline did not complete — re-run `omac reapply` and check
`omac doctor`.
</command-instruction>
