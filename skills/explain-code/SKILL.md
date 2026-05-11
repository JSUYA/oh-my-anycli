---
name: explain-code
description: Explains a function, file, or module at the requested depth (summary, walkthrough, deep-dive). Preserves code identifiers exactly, traces callers/callees via grep when feasible, and lists related files.
version: 1.0.0
when_to_use: User asks "/explain", "what does this do?", "walk me through this file", or wants onboarding context on an unfamiliar module. Read-only — never modifies code.
inputs:
  - name: target
    description: Path to a file, optionally with a function-qualified suffix (e.g. "src/auth.ts:validateToken").
  - name: depth
    description: One of "summary" (3-5 sentences), "walkthrough" (key steps in order), or "deep-dive" (full control flow, edge cases, callers). Defaults to "walkthrough".
required_tools: [bash, read, grep]
---

# Explain Code Skill

## Goal

Explain an existing function, file, module, or flow at the requested depth while
preserving exact identifiers and avoiding code changes.

## Workflow

1. Resolve the target path and optional symbol. If the target is ambiguous, list
   the candidates and ask for a narrower target.
2. Choose depth:
   - `summary`: 3-5 sentences;
   - `walkthrough`: execution-order bullets with file anchors;
   - `deep-dive`: control flow, edge cases, callers/callees, and data shapes.
3. Read the target first. Use grep for direct callers/callees only when needed
   for the requested depth.
4. Explain in execution order:
   inputs -> important branches -> side effects -> return/output.
5. Preserve identifiers exactly. Use `file:line` anchors for non-obvious claims.
6. Include "Surprises" only when behavior contradicts a name, comment, or common
   expectation.

## Output Format

```markdown
### `parseConfig` (`src/config.ts:18`)

TL;DR: <one sentence>

#### Walkthrough
- `src/config.ts:19` reads `CONFIG_PATH`.
- `src/config.ts:27` falls back to defaults when the file is absent.

#### Surprises
- `src/config.ts:44` mutates the exported `defaults` object.
```

## Guardrails

- Do not edit code.
- Do not paraphrase identifiers.
- Do not explain files you did not read.
- Do not expand into a full architecture review; use `architect` for that.
