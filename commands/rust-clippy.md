---
description: Run cargo clippy on changed files, categorize the findings, and apply automatic fixes only when approved.
argument_hint: "[package or path]"
allowed_tools: [bash, read, edit]
---

<command-instruction>
You are running the Rust clippy triage workflow. Invoke the `rust-clippy-triage` skill with the user's optional `target` and `pedantic` arguments.

Honor the project's existing `clippy.toml` / `[lints.clippy]` configuration. Group findings into ALWAYS-FIX / STYLE-PREFERENCE / DENY-CANDIDATE. Apply `cargo clippy --fix` only per-file with explicit user approval. Never blanket-allow lints to make warnings disappear. Report in English with file:line:column references.
</command-instruction>
