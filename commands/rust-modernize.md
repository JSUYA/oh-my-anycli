---
description: Modernize changed Rust files from older patterns to current idioms such as try! to ?, manual loops to iterators, and clearer error handling.
argument_hint: "[path or error pattern (anyhow|thiserror|eyre|std)]"
allowed_tools: [bash, read, edit]
---

<command-instruction>
You are running the Rust idiom modernize workflow. Invoke the `rust-idiom-modernize` skill with the user's optional `target` and `error_pattern` arguments.

Detect the project's edition and existing error-handling pattern from Cargo.toml and source. Apply changes per-file with explicit approval. Never introduce new dependencies (anyhow, thiserror, etc.) without flagging them as a separate proposal. Never change public API return types without flagging the API break. Report in English with file:line references grouped by category (Operator / Iterator / Error / Micro).
</command-instruction>
