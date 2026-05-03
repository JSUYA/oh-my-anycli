---
description: cargo clippy를 변경된 파일에 실행하고 결과를 카테고리별로 분류해 승인 시 자동 수정을 적용합니다.
argument_hint: "[패키지 또는 경로]"
allowed_tools: [bash, read, edit]
---

<command-instruction>
You are running the Rust clippy triage workflow. Invoke the `rust-clippy-triage` skill with the user's optional `target` and `pedantic` arguments.

Honor the project's existing `clippy.toml` / `[lints.clippy]` configuration. Group findings into ALWAYS-FIX / STYLE-PREFERENCE / DENY-CANDIDATE. Apply `cargo clippy --fix` only per-file with explicit user approval. Never blanket-allow lints to make warnings disappear. Report in English with file:line:column references.
</command-instruction>
