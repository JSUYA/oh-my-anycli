---
name: sudo-helper
description: Help the user enable sudo / interactive prompts inside an opencode-anycli session. Explains the multi-layer TTY chain, the --tty flag, and the three practical workarounds when --tty alone is not enough.
version: 1.0.0
when_to_use: User asks "how do I sudo inside opencode-anycli?", "sudo says no tty", "ssh-add hangs", "gh auth login asks for input but nothing happens", or invokes "/sudo". Also useful when a skill the agent is running needs root privileges and the bash tool errors out.
inputs: []
required_tools: [bash, read]
---

# sudo-helper skill

## Goal

Tell the user how to make interactive subprocess prompts (sudo password,
ssh-add, gh auth login, expect-style password entry, etc.) actually work
inside an opencode-anycli session. The honest answer involves multiple
layers and there is no single magic switch — explain each layer and the
three practical workarounds.

## The TTY chain

Three layers, each independently controlling whether the next layer can
read from the user's terminal:

```
your terminal (TTY)
   │ stdio: inherit
   ▼
opencode-anycli wrapper      ← we always inherit stdio for this layer
   │ stdio: inherit
   ▼
opencode (the agent runtime) ← it has TTY; whether ITS bash tool gives
   │                           the spawned bash a TTY is opencode's call
   │ stdio depends on opencode
   ▼
opencode's bash tool      OR  cline subprocess (provider call)
                                │ stdio: ignore (default) or inherit (--tty)
                                ▼
                              cline's own bash tool
                                │ stdio depends on cline
                                ▼
                              sudo / ssh-add / gh auth ← needs TTY
```

The two layers we can control:

| Layer | Default | How to disable |
|---|---|---|
| opencode-anycli wrapper | always inherits | (not configurable — TUI requires TTY) |
| cline subprocess (our provider) | **inherit** (TTY ON since v0.1.x) | `opencode-anycli --no-tty` or `OPENCODE_ANYCLI_TTY=0` (CI / piped input) |

Layers we cannot control:

- **opencode's bash tool**: whether it gives spawned commands a TTY is
  opencode's implementation. Often agent bash tools capture stdin/stdout
  for parsing, so interactive prompts may still fail.
- **cline's bash tool**: same — cline decides how to spawn its bash
  subprocesses. `--tty` gives cline TTY-stdin, but cline's bash tool may
  or may not pass that down.

## The honest answer

The wrapper now keeps the cline subprocess stdin connected to the parent
TTY by default. That removes ONE pipe in the chain — sudo prompts can
reach the user IF cline's bash tool also forwards stdin to its child
process. Whether cline does so is cline's implementation; in practice it
usually does. If sudo still fails after a normal launch, fall back to
one of the three workarounds below.

## Step 1 — Just launch normally and try

```bash
opencode-anycli
```

Then ask the agent to run the sudo command. If sudo prompts and you
can type the password, you're done. If sudo says "no tty" or the prompt
never appears, continue to the workarounds below.

(Opt-out: `opencode-anycli --no-tty` or `OPENCODE_ANYCLI_TTY=0` for
unattended / CI runs where cline must not consume stdin.)

## Step 2 — Workaround A: passwordless sudo for the package manager (RECOMMENDED)

**Easiest, most reliable.** opencode-anycli ships an installer that
auto-detects the user's package manager and writes a scoped sudoers
rule:

```bash
opencode-anycli --setup-sudo            # interactive: detect + confirm + apply
opencode-anycli --setup-sudo --yes      # non-interactive
opencode-anycli --setup-sudo --print    # preview without writing
opencode-anycli --setup-sudo --remove   # undo
```

It supports `apt`/`dnf`/`yum`/`pacman`/`zypper`/`apk`. macOS short-
circuits with a no-op (Homebrew does not need sudo). Validates with
`visudo` before installing.

After this, `sudo apt-get install <pkg>` runs without prompting from
inside opencode-anycli sessions.

If the user wants additional non-package-manager commands whitelisted,
they can append to `/etc/sudoers.d/opencode-anycli` manually with
`sudo visudo`. Always keep the list scoped — **never `NOPASSWD: ALL`**.

## Step 3 — Workaround B: SUDO_ASKPASS helper

For GUI / out-of-band password entry. Set up an askpass helper:

```bash
# macOS — use a tiny osascript helper:
cat > ~/.local/bin/askpass-osa <<'EOF'
#!/usr/bin/env bash
osascript -e 'Tell application "System Events" to display dialog "sudo password:" default answer "" with hidden answer' \
  -e 'text returned of result' 2>/dev/null
EOF
chmod +x ~/.local/bin/askpass-osa
export SUDO_ASKPASS=$HOME/.local/bin/askpass-osa

# Linux — use ssh-askpass / x11-askpass / zenity wrapper:
export SUDO_ASKPASS=$(command -v ssh-askpass || command -v zenity-askpass)

# Then invoke sudo with -A:
sudo -A apt-get update
```

Tell the agent (in your prompt) to use `sudo -A` whenever it needs root.

## Step 4 — Workaround C: pre-authorize the session

Run sudo once outside opencode-anycli to refresh the credential cache,
then start the session within the cache TTL (default 5 min):

```bash
sudo -v                          # refresh the timestamp
opencode-anycli --tty            # subsequent sudo calls use the cache
```

This is the laziest option. Risk: anyone who can run commands in your
shell during the cache TTL gets free sudo.

## Output format

When the user asks "how do I sudo here?", reply with:

1. The one-line `--tty` instruction (Step 1).
2. A one-paragraph "if that doesn't work, here are three options" with a
   short summary of each workaround.
3. The exact commands for the workaround that fits their case (ask if
   unclear: do they want passwordless for specific commands, GUI prompt,
   or just session-cache?).

If the user asks for the full picture (e.g. "explain the TTY chain"),
walk through the diagram + table above.

## Anti-patterns

- Telling the user "just use `--tty`" without acknowledging that it's
  necessary but not always sufficient.
- Recommending `NOPASSWD: ALL` — that defeats the point of sudo. Always
  scope to the specific commands the agent needs.
- Suggesting the user disable cline's `--yolo` to "regain interactive
  control". cline's `--yolo` is the agent's auto-approve loop, not the
  bash subprocess stdio. Disabling it would just hang every cline call
  inside the cline agent's own approval prompts.
- Suggesting `sudo -S` with a literal password in the prompt the agent
  sees. That ends up in opencode's session log and possibly the model's
  context — never put a real password in a prompt or skill body.
