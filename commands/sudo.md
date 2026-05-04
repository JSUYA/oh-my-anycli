---
description: sudo 또는 다른 인터랙티브 입력(ssh-add, gh auth login 등)을 opencode-anycli 안에서 동작시키는 방법을 안내합니다.
argument_hint: "(인자 없음)"
allowed_tools: [bash, read]
---

<command-instruction>
Invoke the `sudo-helper` skill. The recommended fix for "sudo doesn't
work inside the session" is to restart with one flag:

   opencode-anycli --allow-dangerously-skip-permissions

This re-execs the whole session under sudo -E (one password prompt at
startup), so the inner cline + bash subprocesses run as root and can
install packages, start daemons, run docker, etc. without any further
prompts. Nothing is written to /etc/sudoers.d/. Implies --auto-approve
for the same session. Trade-off: files created during the session
become root-owned.

If the user does not want full-session elevation (only one command
needs root, or root-owned outputs are unacceptable), walk them through
the two narrower workarounds in order:

  1. SUDO_ASKPASS helper (GUI password prompt; `sudo -A`-style use).
  2. Pre-authorise the sudo cache (sudo -v outside OpenCode-AnyCLI,
     then launch within the cache TTL — fragile across tty boundaries).

Never recommend NOPASSWD: ALL or any manual sudoers edit. Never
mention the removed --setup-sudo / --setup-docker flags. Never put a
literal password in the prompt. The cline subprocess's --yolo is
unrelated to sudo and must not be turned off.
</command-instruction>
