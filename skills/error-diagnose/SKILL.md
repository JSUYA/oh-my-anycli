---
name: error-diagnose
description: Walks through an error message and optional stack trace — literal interpretation, ranked root-cause hypotheses, one-line fix per cause, and a list of what to gather if the cause is still unclear. Encourages reproducer creation. Policy-neutral.
version: 1.0.0
when_to_use: User pastes an error/stack trace, says "this broke", "/diagnose this error", or asks for help interpreting a panic/exception/assertion. Useful before opening a bug ticket.
inputs:
  - name: error_text
    description: The raw error message and (optionally) stack trace, in the original language. Required.
  - name: file_context
    description: Optional path to the file the error originates from, if known. Improves accuracy of root-cause ranking.
required_tools: [bash, read, grep]
---

# Error Diagnose Skill

## Goal

Diagnose an error from literal evidence, produce ranked hypotheses, and identify
the cheapest falsifying experiment before proposing edits.

## Workflow

1. Restate the failure in one sentence using the exact error text, command, and
   location if known. If the trigger is missing, ask for it or infer only from
   local logs/tests.
2. Read the top live stack frame and its immediate caller. For failing tests,
   read the failing test before implementation files.
3. Reproduce with the smallest safe command when practical. If reproduction is
   expensive or destructive, state the command instead of running it.
4. Produce exactly three ranked hypotheses:
   - probability;
   - suspect `file:line`;
   - one-line fix;
   - falsifier that should take under two minutes.
5. Run the cheapest safe falsifier first. Update the ranking based on observed
   output.
6. Stop when the root cause is identified or list the precise missing signal
   needed next.

## Output Format

```markdown
### Failure
`TypeError: x is undefined` from `npm test -- user.test.ts`.

### Hypotheses
1. P=0.65 `src/user.ts:42`: `findUser` can return `undefined`.
   fix: handle missing user before reading `.name`.
   falsify: add a log/assert around the return value in the failing test.

### Next experiment
- Run `npm test -- user.test.ts -t "missing user"`; if it fails at the same
  line, apply the guard.
```

## Guardrails

- Do not edit code unless the user asked for a fix, not just a diagnosis.
- Do not produce more than three hypotheses to look thorough.
- Do not invent stack frames, versions, or log output.
- Do not recommend broad refactors as the first fix.
