---
description: Karpathy의 LLM 코딩 가이드라인을 현재 작업에 적용합니다 (생각→단순화→외과적 수정→검증 가능 목표).
argument_hint: "(인자 없음 — 전체 가이드라인 적용)"
allowed_tools: [read]
---

<command-instruction>
You are activating the Karpathy guidelines for the current task. Invoke the
`karpathy-guidelines` skill, then before producing any code-changing output:

1. State your one-sentence interpretation of the user's request.
2. Name the simplest viable approach in 1-3 sentences.
3. State the verifiable success criterion (test name, output match, lint
   pass, etc.).
4. Surface any assumption or alternative that needs the user's input
   before code is written.

Apply the four guidelines (Think Before Coding, Simplicity First, Surgical
Changes, Goal-Driven Execution) as a hard checklist for the rest of the
session, not as suggestions. Do not "improve" code unrelated to the
request. Do not add abstractions, flags, or features that were not asked
for. Every changed line should trace directly to the user's request.

Attribution: the skill body is adapted from forrestchang/andrej-karpathy-skills
(MIT). Do not modify the four core guideline sections.
</command-instruction>
