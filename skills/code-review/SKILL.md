---
name: code-review
description: Reviews changed files on the current git branch and surfaces concrete, actionable issues across correctness, security, performance, style, and test coverage with file:line references.
version: 1.0.0
when_to_use: User asks for a code review, opens a PR locally, or invokes "/review". Also useful before pushing a feature branch.
inputs:
  - name: pr_or_branch
    description: Optional PR number or branch name. Defaults to the current checked-out branch compared against its merge base with main/master.
required_tools: [bash, read]
---

# Code Review Skill

## Goal

Review the current branch or specified diff for correctness, regressions,
security issues, and missing tests. This skill is read-only and should behave
like a code review, not a refactor session.

## Boundary

Use this skill for broad diff review. Use `security-scan` for a dedicated local
secret/unsafe-pattern sweep, `dead-code-finder` for unused-code analysis,
`log-level-auditor` for debug logging, and domain review skills for CMake,
Dockerfile, CI, shell, OpenAPI, or Tizen-specific checklists. A code review may
flag those issues when seen in the diff, but it should not run every specialized
scan by default.

## Workflow

1. Resolve the review range:
   - use the user-specified commit/range when provided;
   - otherwise use `git merge-base HEAD origin/main` when available, falling
     back to `main`, `master`, or staged/unstaged diff.
2. List changed files and skim the diff before reading full files:
   ```bash
   git diff --stat <range>
   git diff --name-only <range>
   git diff -- <file>
   ```
3. Read only the changed hunks plus enough surrounding context to understand
   behavior. Read callers/callees only when a claim depends on them.
4. Prioritize findings:
   - correctness: null/empty cases, off-by-one, state mutation, error paths,
     idempotency, concurrency, resource lifetime;
   - security: validation, authn/authz, escaping, secrets, unsafe
     deserialization, command/SQL injection;
   - regressions: changed public contracts, removed defaults, data migrations;
   - tests: missing coverage for new behavior or tests that assert too little.
5. Avoid style comments unless the style issue can cause confusion or the diff
   already has no higher-priority findings.
6. For every finding, include `file:line`, why it matters, and the smallest
   suggested fix. If no issue is found, say so and mention residual test gaps.

## Output Format

```markdown
Verdict: BLOCKING | NITS | LGTM

## Blocking
- `src/auth.ts:42`: role is trusted from request body, so a normal user can
  escalate privileges. Read role from the verified session instead.

## Tests
- missing: regression test for unauthenticated access to `/admin`

## Residual Risk
One sentence.
```

## Guardrails

- Do not edit files.
- Do not review unrelated files just because they are nearby.
- Do not invent merge-base, CI, or test results.
- Do not bury blocking findings under summaries.
