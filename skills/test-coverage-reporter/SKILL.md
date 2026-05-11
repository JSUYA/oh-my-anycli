---
name: test-coverage-reporter
description: Runs the project's existing coverage tool, summarizes overall and per-file results, and highlights recently-changed files that lack coverage. No external services or upload steps.
version: 1.0.0
when_to_use: User asks "/coverage", "what's our test coverage?", "show coverage gaps", or wants a pre-PR check that new code is covered. Useful right after `/test` or before opening a PR.
inputs:
  - name: scope
    description: Optional path or glob to scope the coverage run. Defaults to the project default.
required_tools: [bash, read]
---

# Test Coverage Reporter Skill

## Goal

Run the project's existing coverage workflow and summarize coverage gaps,
especially around recently changed files.

## Boundary

Use this skill to measure and prioritize coverage gaps. It does not write tests.
Use `unit-test-writer` or `integration-test-writer` after deciding which missing
behavior should be covered.

## Workflow

1. Detect coverage tooling from existing configuration:
   `package.json`, `nyc`, `vitest --coverage`, `jest --coverage`,
   `coverage.py`, `pytest --cov`, `go test -cover`, `cargo tarpaulin`,
   `lcov`, `gcov`, CI scripts, or `Makefile`.
2. Run the existing coverage command. If dependencies are missing, report the
   exact command that failed and stop.
3. Parse available output files when present: `coverage/lcov.info`,
   `coverage-summary.json`, `.coverage`, `htmlcov`, `target/coverage`, or
   tool stdout.
4. Compare coverage against changed files when Git history is available:
   `git diff --name-only <merge-base>..HEAD`.
5. Highlight:
   - files with low or zero coverage;
   - changed files without coverage movement;
   - uncovered branches in risky code paths;
   - threshold failures.
6. Recommend targeted tests, not arbitrary percentage chasing.

## Output Format

```markdown
### Coverage summary
Command: `pytest --cov=src`
Overall: 84.2% lines, threshold 80%

#### Changed-file gaps
- `src/billing.py`: 42% lines, uncovered error path around declined cards.

#### Suggested tests
- add regression for declined payment response mapping.
```

## Guardrails

- Do not add or change tests from this reporting skill.
- Do not upload reports to coverage services.
- Do not invent coverage numbers if the tool output is unavailable.
- Do not recommend broad test rewrites when a focused missing behavior is clear.
