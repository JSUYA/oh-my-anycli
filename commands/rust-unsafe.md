---
description: Audit unsafe blocks in changed Rust files with a safety checklist and categorized findings.
argument_hint: "[path]"
allowed_tools: [bash, read]
---

<command-instruction>
You are running the Rust unsafe review workflow. Invoke the `rust-unsafe-review` skill with the user's optional `target` argument.

Locate every `unsafe` block, `unsafe fn`, `unsafe impl`, and `unsafe trait` via grep. For each, audit against the soundness checklist (SAFETY comment, pointer validity, slice creation, transmute, FFI, lifetime, Send/Sync, asm). Classify as SAFETY-COMMENT-MISSING / NEEDS-REVIEW / SOUND-WITH-NOTES. Never edit unsafe code; only report. Refuse to remove the `unsafe` keyword unless a safe replacement is obviously sound. Report in English.
</command-instruction>
