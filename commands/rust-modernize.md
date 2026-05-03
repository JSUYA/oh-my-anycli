---
description: 변경된 Rust 파일의 옛 패턴을 현재 관용구로 마이그레이션합니다 (try!→?, 수동 루프→이터레이터, 에러 핸들링 등).
argument_hint: "[경로 또는 에러 패턴 (anyhow|thiserror|eyre|std)]"
allowed_tools: [bash, read, edit]
---

<command-instruction>
You are running the Rust idiom modernize workflow. Invoke the `rust-idiom-modernize` skill with the user's optional `target` and `error_pattern` arguments.

Detect the project's edition and existing error-handling pattern from Cargo.toml and source. Apply changes per-file with explicit approval. Never introduce new dependencies (anyhow, thiserror, etc.) without flagging them as a separate proposal. Never change public API return types without flagging the API break. Report in English with file:line references grouped by category (Operator / Iterator / Error / Micro).
</command-instruction>
