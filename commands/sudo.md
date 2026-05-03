---
description: sudo 또는 다른 인터랙티브 입력(ssh-add, gh auth login 등)을 opencode-anycli 안에서 동작시키는 방법을 안내합니다.
argument_hint: "(인자 없음)"
allowed_tools: [bash, read]
---

<command-instruction>
Invoke the `sudo-helper` skill. opencode-anycli now ships with TTY ON
by default — the cline subprocess inherits the parent's stdin — so a
plain launch is the first thing to try:

   opencode-anycli

If sudo still fails ("no tty" / no prompt / hangs) because the inner
bash tool doesn't forward stdin, walk the user through the three
reliable workarounds in order of safety:

1. Passwordless sudo for ONLY the specific commands the agent needs
   (`/etc/sudoers.d/<file>` with `NOPASSWD: /usr/bin/apt-get update`).
2. SUDO_ASKPASS helper that opens a GUI password prompt.
3. Pre-authorise the sudo cache (`sudo -v` outside opencode-anycli,
   then launch within the cache TTL).

Never recommend `NOPASSWD: ALL`. Never put a literal password in the
prompt. The cline subprocess's `--yolo` is unrelated to sudo and must
not be turned off.
</command-instruction>
