---
name: karpathy-guidelines
description: Behavioral guidelines to reduce common LLM coding mistakes. Use when writing, reviewing, or refactoring code — bias toward thinking before coding, surgical changes, surfacing assumptions, and verifiable success criteria.
version: 1.0.0
when_to_use: User invokes "/karpathy", "/guidelines", or asks for the Karpathy guidelines explicitly. Also invoke at the START of any non-trivial coding task as a self-checklist before reaching for the keyboard.
inputs: []
required_tools: [read]

# Attribution / 출처
# Adapted from forrestchang/andrej-karpathy-skills (skills/karpathy-guidelines/SKILL.md),
# which is itself derived from Andrej Karpathy's public observations on LLM coding pitfalls.
# Upstream: https://github.com/forrestchang/andrej-karpathy-skills
# Upstream license: MIT (declared in the upstream SKILL.md frontmatter).
# This adaptation: MIT (per oh-my-clinecli's project license).
# Changes from upstream:
#   - Wrapped in oh-my-clinecli's standard frontmatter shape
#   - Added "When to use" / "Inputs" / "Output format" / "Anti-patterns" sections to
#     match the rest of this catalog
#   - The four core sections (Think Before Coding / Simplicity First / Surgical
#     Changes / Goal-Driven Execution) are preserved verbatim from upstream
---

# Karpathy guidelines skill

Behavioral guidelines to reduce common LLM coding mistakes, derived from
[Andrej Karpathy's observations](https://github.com/forrestchang/andrej-karpathy-skills)
on LLM coding pitfalls. The four sections below are the canonical guidelines —
keep them open as a checklist while writing, reviewing, or refactoring code.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial
tasks, use judgment.

## Goal

Apply the four guidelines below as a self-imposed checklist on every
non-trivial code change. The expected outcome is fewer "AI sprawl" patterns
(speculative abstraction, drive-by refactoring, hidden assumptions, vague
success criteria) and more deliberate, reviewable diffs.

## When to apply

- Before starting any task that touches more than ~30 lines of code
- Before reviewing a PR or proposing changes to existing code
- Whenever you're tempted to add an abstraction, a flag, a helper, or
  "while I'm here" cleanup
- Whenever a task description is vague — surface the ambiguity instead of
  guessing

## The four guidelines (canonical, preserved from upstream)

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes,
simplify.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria
("make it work") require constant clarification.

## How to use this skill in practice

Before producing a code-changing response, run through this internal
checklist. If any item fails, address it before writing code:

| # | Question | If failed |
|---|---|---|
| 1 | Have I stated my interpretation of the task in one sentence? | Restate, ask if ambiguous |
| 2 | Have I named the simplest viable approach? | Reduce scope, drop speculation |
| 3 | Did I avoid touching code unrelated to the request? | Revert drive-by changes |
| 4 | Do I have a verifiable success criterion (tests, output match, lint pass)? | Define one before coding |
| 5 | Did I clean up imports/symbols my own change orphaned? | Sweep before submitting |

## Output format

When this skill is invoked explicitly (e.g. via `/karpathy`), reply with:

1. A one-line acknowledgement that the guidelines are now in effect for the
   current task.
2. The user's task restated in one sentence ("My understanding: ...").
3. The proposed approach in 1-3 sentences, plus the success criterion.
4. Any assumptions or alternatives that need user input before coding.

If invoked implicitly (start of any non-trivial task without `/karpathy`),
internalize the checklist silently and only surface assumptions/alternatives
that need the user.

## Anti-patterns

- Treating these guidelines as suggestions rather than a checklist.
- Quoting "Simplicity First" while still adding speculative abstractions
  ("but this might be useful later").
- Surgical-changes lip service while reformatting whole files.
- Declaring a verbal "success criterion" without an actual test or
  observable output to check against.
- Removing pre-existing dead code "while you're at it" — that's #3
  violation.
- Asking the user to choose between options when you could just propose
  the simpler one and note the alternative.
- Preserving this skill verbatim across edits is intentional —
  do NOT "improve" the four core sections; they came from upstream and
  changes should be limited to formatting / surrounding sections.
