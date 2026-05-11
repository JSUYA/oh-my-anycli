---
name: unit-test-writer
description: Generates a unit test file for a given function or source file, auto-detecting the project's existing test framework and matching its style and conventions.
version: 1.0.0
when_to_use: User asks "/test path/to/file.ts", "write tests for X", or wants test coverage for a newly-added function. Use after implementing new code, or to backfill missing tests.
inputs:
  - name: target
    description: Path to the source file (or function-qualified path like "src/util.ts:formatDate") to be tested.
required_tools: [bash, read, edit]
---

# Unit Test Writer Skill

## Goal

Create focused unit tests for the requested code using the project's existing
test framework and style.

## Boundary

Use this skill for isolated functions, classes, and modules with collaborators
mocked or faked according to local style. Use `integration-test-writer` when the
behavior must cross HTTP, DB, queue, CLI, filesystem, or service boundaries. Use
`test-coverage-reporter` when the user asks what is covered rather than asking
to write tests.

## Workflow

1. Resolve the target source file and optional function/symbol.
2. Detect the existing test framework and nearest test location. Read 1-2
   neighboring tests before writing anything.
3. Choose behavior-oriented tests:
   - the primary happy path;
   - one realistic edge case;
   - one error path if the contract includes errors.
4. Avoid tests that only assert implementation shape or duplicate every branch.
5. Write the smallest new test file or append to the closest existing one.
6. Run the narrowest test command. If it fails because the code is buggy, stop
   and report the code issue instead of weakening the test.

## Output Format

```markdown
### Unit tests added
- `src/__tests__/formatDate.test.ts`

### Command
- `npm test -- formatDate.test.ts`: 4 passed

### Not covered
- timezone database edge cases
```

## Guardrails

- Do not introduce a new test runner or assertion library.
- Do not mock the function under test.
- Do not weaken or delete existing tests.
- Do not use snapshots for logic-heavy behavior unless the project already does
  so for that exact kind of output.
