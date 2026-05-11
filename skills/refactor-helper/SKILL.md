---
name: refactor-helper
description: Performs small, targeted refactors only — extract function, rename, dead-code removal, simplify conditional. Explicitly refuses grand refactors and architectural rewrites.
version: 1.0.0
when_to_use: User asks "/refactor", "extract this into a function", "rename this variable across the file", or "remove this dead code". Do NOT use for "redesign this module" or "convert to TypeScript".
inputs:
  - name: scope
    description: Target file path and the specific refactor requested (e.g. "src/auth.ts — extract validateToken helper").
required_tools: [bash, read, edit]
---

# Refactor Helper Skill

## Goal

Perform a small, targeted refactor while preserving behavior and keeping the
diff easy to review.

## Boundary

Use this skill for applying a known, narrow change. Use `dead-code-finder` to
discover candidates before removal, and `lint-fix` for purely tool-reported
formatting/import/style fixes. Do not use this as a substitute for
`architect`-style module redesign.

## Workflow

1. Confirm the requested refactor is narrow: extract function, rename within a
   known scope, simplify a conditional, remove explicitly confirmed dead code,
   or split a small helper.
2. Read the target file and nearby tests. If behavior is unclear, ask or write a
   characterization test before changing code.
3. Define behavior-preservation checks: existing tests, focused command, or
   before/after grep for public names.
4. Make the smallest edit that satisfies the request. Avoid opportunistic
   formatting or style cleanup.
5. Remove only unused imports/variables created by the refactor.
6. Run the narrowest relevant verification and report any remaining risk.

## Output Format

```markdown
### Refactor complete
- changed: `src/auth.ts`
- intent: extracted `validateToken` without changing callers

### Verification
- `npm test -- auth`: passed

### Residual risk
- no integration test covers expired refresh tokens
```

## Guardrails

- Do not perform broad architecture rewrites under this skill.
- Do not change public behavior to make the refactor easier.
- Do not delete pre-existing dead code unless the user explicitly asked for
  removal and the evidence is strong.
- Do not move files across module boundaries without a separate plan.
