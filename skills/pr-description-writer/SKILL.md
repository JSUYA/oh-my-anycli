---
name: pr-description-writer
description: Generates a PR description from commits-since-base and diff statistics. Sections cover Summary, Why, What changed, Testing notes, and Risk. Honors any project PR template if found; otherwise emits a clean neutral structure.
version: 1.0.0
when_to_use: User asks "/pr-desc", "write the PR description", or "summarize this branch for review". Run after commits land on the branch and before opening the PR.
inputs:
  - name: base
    description: Optional base branch. Defaults to "main", then "master", then "develop".
required_tools: [bash, read]
---

# PR Description Writer Skill

## Goal

Draft a pull request description from local branch context, commits, and diff
statistics while matching the project's existing template when one exists.

## Boundary

Use this skill for writing PR text. Use `branch-prep` to decide whether the
branch is ready, and `git-commit-helper` to create or message a commit. This
skill may mention blockers it observes, but it should not perform readiness
repairs, rebases, pushes, or commits.

## Workflow

1. Resolve the base branch: user-provided value, then `origin/main`,
   `origin/master`, `origin/develop`, `main`, `master`, `develop`.
2. Gather context:
   ```bash
   git status --short
   git log --oneline <base>..HEAD
   git diff --stat <base>..HEAD
   git diff --name-only <base>..HEAD
   ```
3. Read `.github/pull_request_template*`, `docs/`, or prior local PR templates
   if present. Match section names and checkbox style.
4. Group changes by intent: feature, fix, refactor, docs, tests, build/chore.
5. Include testing evidence only from commands actually run. If no tests ran,
   write "Not run" with the reason.
6. Call out risk and rollback based on changed files: migrations, config,
   public API, auth/security, release/versioning, or generated artifacts.

## Output Format

```markdown
## Summary
- <why this PR exists>

## Changes
- <grouped user-facing changes>

## Testing
- [x] `./tests/run-all.sh`
- [ ] Not run: <reason>

## Risk / Rollback
<one concise paragraph>
```

## Guardrails

- Do not create or update the PR remotely from this skill.
- Do not include issue or PR URLs unless the user explicitly supplied them.
- Do not invent tests, reviewers, release dates, or deployment status.
- Do not hide a dirty worktree; mention it.
