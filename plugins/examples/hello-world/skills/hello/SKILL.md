---
name: hello
description: Greets the user by name. Useful as a sanity check that the plugin pipeline is working end-to-end.
version: 0.1.0
when_to_use: User invokes "/hello" or asks the assistant to "say hi".
inputs:
  - name: name
    description: Optional name to greet. Defaults to "world".
required_tools: []
---

# Hello World Skill

## Goal

Greet the user by name as a sanity check that the plugin pipeline (clone →
install → prefix-rename → reapply) is working end-to-end.

## Workflow

1. Read the optional `name` input. Default to `world` when absent.
2. Print exactly one line: `Hello, <name>!` — no banners, no extra text.
3. Stop. Do not propose follow-up actions.

## Output

A single greeting line. Nothing more.

## Guardrails

- Do not invent extra context about the user.
- Do not perform filesystem or network operations.
- Treat this skill as a no-op canary; if it ever does more than print one
  line, the plugin pipeline test is wrong.
