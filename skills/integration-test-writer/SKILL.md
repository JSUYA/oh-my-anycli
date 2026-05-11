---
name: integration-test-writer
description: Generates integration tests that exercise actual external dependencies (DB, API, message bus) or cross-module interactions. Auto-detects framework (jest+supertest, pytest+requests, go testing+testcontainers) and matches existing style. Distinct from unit tests by scope.
version: 1.0.0
when_to_use: User asks "/test-int", "write integration tests for the auth flow", or wants end-to-end coverage of a feature touching the DB or HTTP layer. Use after a feature ships and unit coverage is in place.
inputs:
  - name: target
    description: Path to the source file or feature module under test (e.g. "src/auth/login-flow.ts" or "internal/orders/").
required_tools: [bash, read, edit]
---

# Integration Test Writer Skill

## Goal

Create integration tests around a real feature boundary using the project's
existing test framework and infrastructure.

## Boundary

Use this skill when the test must exercise real collaborators or a feature
boundary. Use `unit-test-writer` for isolated logic where dependencies can be
mocked or faked. Use `test-coverage-reporter` to measure gaps before deciding
which tests to add.

## Workflow

1. Identify the integration boundary: HTTP route, DB-backed workflow, message
   queue, CLI command, file IO, or cross-module service.
2. Detect the existing integration framework from neighboring tests, scripts,
   and config. Do not introduce a new runner, container library, or assertion
   library.
3. Read 1-2 closest integration tests and mirror:
   file location, naming pattern, fixture setup, cleanup, async style, and
   external dependency fences.
4. Choose 1-3 behavior tests:
   - primary happy path through real collaborators;
   - one realistic failure or validation path;
   - one persistence/side-effect assertion when the feature writes state.
5. Write the smallest test file or modify the closest existing test file.
6. Run the narrowest relevant test command. If dependencies are missing, report
   the exact blocker and command that should be run in the normal environment.

## Output Format

```markdown
### Integration tests added
- `tests/integration/auth-login.test.ts`

### Command
- `npm test -- auth-login.test.ts`: 3 passed

### Coverage
- covered: valid login persists session
- not covered: rate limiting, third-party IdP outage
```

## Guardrails

- Do not mock the boundary that makes the test an integration test.
- Do not use real production services or credentials.
- Do not add sleeps for synchronization; use the project's existing wait/fake
  clock patterns.
- Do not weaken existing tests to make new tests pass.
