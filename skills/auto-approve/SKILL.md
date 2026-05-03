---
name: auto-approve
description: Explain opencode-anycli's auto-approve mechanism, when to use it, and how to enable it for the current or next session. Surfaces opencode's runtime-toggle limitation honestly.
version: 1.0.0
when_to_use: User asks how to skip permission prompts ("yolo", "auto-approve", "stop asking me", "dangerous"), or invokes "/auto-approve". Also useful when the user is frustrated by repeated "Allow this edit?" prompts in a long-running session.
inputs: []
required_tools: [bash, read]
---

# Auto-approve skill

## Goal

Tell the user exactly how to enable auto-approve in opencode-anycli, what
gets auto-approved, and what the limitations are. Auto-approve is a
**session-scope** decision in opencode (config-driven, not runtime-toggleable),
so the answer is always "relaunch with `--auto-approve`" — there is no
in-TUI toggle today.

## Two layers of permission to understand

opencode-anycli wraps two agents that each have their own permission gate:

| Layer | What it gates | Already auto-approve? | How to control |
|---|---|---|---|
| **opencode** (outer) | file edits, bash exec, web fetch, external dirs, etc. | ❌ default = ask | `--auto-approve` flag (CLI) or `permission` block (config) |
| **cline** (inner, our subprocess) | cline's own tool calls during its agent loop | ✅ already (we spawn with `--yolo`) | Hard-coded ON by the provider; toggling off requires editing `provider-cline-cli/src/cline-runner.ts` |

So when a user says "I want auto-approve", they almost always mean the
**outer opencode layer**.

## Steps

1. **Tell the user the one-line answer first.** They want a short, actionable
   instruction:

   ```text
   Restart opencode-anycli with --auto-approve:
       opencode-anycli --auto-approve
   ```

   Aliases: `--yolo`, `-y`. Or set `OPENCODE_ANYCLI_AUTO_APPROVE=1` in their
   shell profile to make it the default.

2. **Explain what gets auto-approved.** When `--auto-approve` is on, the
   wrapper writes a temp opencode.json with every documented permission set
   to `"allow"`:

   - `read`, `edit`, `glob`, `grep`, `bash`, `task`, `skill`, `lsp`,
     `question`, `webfetch`, `websearch`, `external_directory`, `doom_loop`,
     and the catch-all `*`.

   Per-key `"deny"` rules the user has explicitly set in their own config
   are preserved (so `bash: "deny"` in the user's opencode.json still
   blocks bash, even with `--auto-approve`).

3. **Explain why there is no runtime toggle.** opencode's permission system
   is loaded once at session start; there is no documented slash command,
   env reload, or signal that makes it re-read config. So:

   ```text
   "Can I turn auto-approve on without restarting?"
       Not today. opencode reads the permission config at session start
       and does not watch the file. You need to exit (Ctrl+D / Ctrl+C) and
       re-launch with --auto-approve.
   ```

   If the user pushes back, do NOT pretend a workaround exists. Tell them
   the honest answer above.

4. **Mention the cline subprocess is already auto-approve.** The user does
   not need to do anything for the inner cline layer — the provider
   already passes `--yolo` to every cline subprocess invocation. Their
   "Allow this edit?" prompts are from opencode's outer layer, not cline.

5. **Warn about the obvious risks.** Recommend the user only use
   `--auto-approve` when:
   - working in a throwaway directory or a fresh git branch with frequent
     commits;
   - the project has good test coverage they can run after each change;
   - they will review the diff before pushing.

   Do NOT recommend it for: production credentials, shared machines, or
   first-time use of an unfamiliar repo.

## Output format

Reply in three short blocks: the one-line restart command, a one-paragraph
"what gets auto-approved", and a one-paragraph "why no runtime toggle". If
the user asked "how", lead with the command. If the user asked "why",
lead with the explanation. If the user asked both, command first.

## Anti-patterns

- Claiming there is a slash command or shortcut that toggles auto-approve
  at runtime — there isn't. Don't invent one.
- Suggesting the user edit `~/.config/opencode-anycli/opencode/opencode.json`
  directly to add `permission: { "*": "allow" }`. That works but the wrapper
  manages the config; the recommended path is `--auto-approve`.
- Suggesting the user disable cline's `--yolo` to "regain control". Cline
  is the inner agent; turning off its yolo means cline will pause inside
  every LLM call asking the user something — opencode-anycli has no UI
  channel for that, so it would just hang.
- Recommending `--auto-approve` for production work without the risk
  warnings above.
