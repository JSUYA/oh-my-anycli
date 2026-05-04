---
description: sudo 또는 다른 인터랙티브 입력(ssh-add, gh auth login 등)을 opencode-anycli 안에서 동작시키는 방법을 안내합니다.
argument_hint: "(인자 없음)"
allowed_tools: [bash, read]
---

<command-instruction>
Invoke the `sudo-helper` skill. The fastest fix for "sudo doesn't work
inside the session" is the bundled auto-installer:

   opencode-anycli --setup-sudo

This auto-detects the user's package manager (apt/dnf/yum/pacman/zypper/
apk) and writes a SCOPED /etc/sudoers.d/opencode-anycli rule (NOPASSWD
for those binaries only — never NOPASSWD: ALL). macOS short-circuits
because Homebrew does not need sudo.

If the user needs prompts beyond the package manager (ssh-add,
gh auth login, custom scripts), walk them through the two remaining
workarounds in order:

  1. SUDO_ASKPASS helper (GUI password prompt).
  2. Pre-authorise the sudo cache (sudo -v outside OpenCode-AnyCLI,
     then launch within the cache TTL).

Never recommend NOPASSWD: ALL. Never put a literal password in the
prompt. The cline subprocess's --yolo is unrelated to sudo and must
not be turned off.
</command-instruction>
