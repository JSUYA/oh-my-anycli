---
name: sudo-helper
description: Help the user enable sudo / interactive prompts inside an opencode-anycli session. Explains the multi-layer TTY chain and the three practical workarounds (--allow-dangerously-skip-permissions, SUDO_ASKPASS, pre-authorized cache) when the default TTY-inheriting launch is not enough.
version: 1.0.0
when_to_use: User asks "how do I sudo inside opencode-anycli?", "sudo says no tty", "ssh-add hangs", "gh auth login asks for input but nothing happens", or invokes "/sudo". Also useful when a skill the agent is running needs root privileges and the bash tool errors out.
inputs: []
required_tools: [bash, read]
---

# sudo-helper skill

## Goal

Tell the user how to make interactive subprocess prompts (sudo password,
ssh-add, gh auth login, expect-style password entry, etc.) actually work
inside an OpenCode-AnyCLI session. The honest answer involves multiple
layers and there is no single magic switch — explain each layer and the
three practical workarounds.

## Boundary

Use this skill for commands that need interactive stdin, a TTY, or root
privileges (`sudo`, `ssh-add`, `gh auth login`). Use `auto-approve` for
opencode's own allow/deny prompts. `--allow-dangerously-skip-permissions`
implies auto-approve, but it is recommended here only when the root/TTY problem
requires full-session elevation.

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
| OpenCode-AnyCLI wrapper | always inherits | (not configurable — TUI requires TTY) |
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

## Step 2 — Workaround A: --allow-dangerously-skip-permissions (RECOMMENDED)

**Easiest, most reliable.** Restart the session with one flag and the
whole process tree (opencode → cline → bash) runs as root for the
duration of that session. There is exactly **one** sudo password prompt
at startup; nothing is written to `/etc/sudoers.d/`, no system
configuration is changed.

```bash
opencode-anycli --allow-dangerously-skip-permissions
opencode-anycli --dangerously-skip-permissions      # alias
OPENCODE_ANYCLI_DANGEROUS=1 opencode-anycli         # env-var equivalent
```

How it works:

1. The wrapper detects the flag, prints a clear warning, and re-execs
   itself under `sudo -E -- env PATH=$PATH HOME=$HOME ... node <script>`.
   PATH is forwarded explicitly because sudo's `secure_path` would
   otherwise drop the user's PATH (and root could not find opencode /
   cline / nvm-managed node).
2. From that point, every subprocess inherits the elevated euid, so the
   agent can run `apt install`, `systemctl`, `docker`, `usermod`, etc.
   without ever hitting another prompt.
3. The flag also implies `--auto-approve`, so opencode's per-tool
   permission prompts stay quiet for the same session.

Trade-offs (this is why "dangerously" is in the name):

- Files the agent creates during the session will be **root-owned**.
  Run `chown -R "$USER":"$USER" .` afterwards if a follow-up build
  needs user ownership.
- The agent has full root for the session. Only opt in when you trust
  the agent's full action set, and prefer running inside a disposable
  VM / container / fresh checkout when stronger isolation matters.
- If `sudo` is missing or the password is rejected, the wrapper exits
  with a clear error rather than silently degrading.

This replaces the older `--setup-sudo` flow that wrote a scoped
`/etc/sudoers.d/opencode-anycli` rule. That flag has been removed —
mention only the new flag from now on.

## Step 3 — Workaround B: SUDO_ASKPASS helper

For GUI / out-of-band password entry without elevating the whole
session. Useful when only one or two commands need root and the
`--allow-dangerously-skip-permissions` blast radius is unwanted.

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

Run sudo once outside OpenCode-AnyCLI to refresh the credential cache,
then start the session within the cache TTL (default 5 min):

```bash
sudo -v                          # refresh the timestamp
opencode-anycli                  # subsequent sudo calls use the cache
```

This is the laziest option. Risk: anyone who can run commands in your
shell during the cache TTL gets free sudo. Also fragile — sudo's
default `timestamp_type=tty` ties the cache to the parent tty, and the
inner cline subprocess may run in a different tty than the cache was
set in, in which case the cache is invisible to it.

## Output format

When the user asks "how do I sudo here?", reply with:

1. Confirm that the wrapper already inherits the parent TTY by default
   (Step 1 — try a normal launch first).
2. A one-paragraph "if that doesn't work, here are three options" with
   a short summary of each workaround. Lead with
   `--allow-dangerously-skip-permissions` as the recommended path, with
   its trade-offs spelled out (root-owned files, full-session
   elevation).
3. The exact commands for the workaround that fits their case (ask if
   unclear: do they want full session elevation, a GUI prompt for one
   command, or just the cached-credentials trick?).

If the user asks for the full picture (e.g. "explain the TTY chain"),
walk through the diagram + table above.

## Anti-patterns

- Suggesting `--setup-sudo`, `--setup-docker`, or any other flag that
  writes to `/etc/sudoers.d/`. Those flags were removed; the single
  replacement is `--allow-dangerously-skip-permissions`.
- Recommending `NOPASSWD: ALL` (or any manual sudoers edit) as a
  workaround. Whole-session elevation via the new flag is simpler,
  scoped to one session, and leaves no persistent privilege change to
  roll back.
- Suggesting the user disable cline's `--yolo` to "regain interactive
  control". cline's `--yolo` is the agent's auto-approve loop, not the
  bash subprocess stdio. Disabling it would just hang every cline call
  inside the cline agent's own approval prompts.
- Suggesting `sudo -S` with a literal password in the prompt the agent
  sees. That ends up in opencode's session log and possibly the model's
  context — never put a real password in a prompt or skill body.
- Recommending `--allow-dangerously-skip-permissions` for shared /
  long-running / production environments. It is a single-session
  elevation; if the workload runs unattended for hours it should run
  in a disposable container, not on a developer laptop.
