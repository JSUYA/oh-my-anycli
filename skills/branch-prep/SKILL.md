---
name: branch-prep
description: Prepares the current feature branch for review by checking divergence from the base branch, running lint and tests, surfacing obvious blockers, and pushing only after explicit confirmation. Refuses history rewrites without explicit --force-with-lease consent.
version: 1.0.0
when_to_use: User asks "/branch-prep", "ready this branch for PR", or "rebase and push for review". Useful right before opening a PR.
inputs:
  - name: base
    description: Optional base branch. Defaults to "main", then "master", then "develop" — first existing remote branch wins.
required_tools: [bash, read]
---

# Branch Prep Skill

## Goal

Determine whether the current branch is ready for review and provide the
smallest safe next actions. This skill may run local read-only Git, lint, and
test commands. It does not rebase, push, or edit files unless the user
explicitly asks for that action in the current request.

## Boundary

Use `branch-prep` for readiness checks and optional branch operations. Use
`git-commit-helper` when the immediate task is a staged commit, and
`pr-description-writer` when the commits already exist and the user only needs
PR text. Do not duplicate full code review here; call out that `/review` should
handle correctness findings.

## Workflow

1. Inspect branch state:
   ```bash
   git status --short --branch
   git remote -v
   ```
2. Resolve the base branch in this order unless the user supplied one:
   `origin/main`, `origin/master`, `origin/develop`, `main`, `master`,
   `develop`.
3. Compare against the base:
   ```bash
   git merge-base HEAD <base>
   git diff --stat <merge-base>..HEAD
   git diff --name-only <merge-base>..HEAD
   git log --oneline <merge-base>..HEAD
   ```
4. Check review blockers: dirty worktree, untracked generated files, branch
   behind base, likely conflicts, no commits on branch, mixed-purpose commits,
   missing tests for changed behavior, debug logs, secrets, migrations, or
   versioned docs that need explicit review.
5. Detect project test commands from existing files (`package.json`, `Makefile`,
   `pyproject.toml`, `Cargo.toml`, `go.mod`, `tests/run-all.sh`) and run the
   lowest-cost relevant command first. Do not invent a new command.
6. If the user asked to rebase or push, restate the exact command and risk
   before executing. Never use plain `--force`; require explicit
   `--force-with-lease` consent.

## Output Format

```markdown
### Branch readiness
Base: origin/main
Range: <merge-base>..HEAD

#### Status
- worktree: clean|dirty
- commits ahead/behind: <n>/<m>
- changed files: <n>

#### Blockers
- <file or command>: <specific issue>

#### Checks run
- `npm test -- --runInBand`: passed|failed|not found

#### Next actions
1. <smallest safe action>
```

## Guardrails

- Do not rebase, reset, push, tag, or delete branches unless explicitly asked.
- Do not hide a dirty tree by stashing unless the user requested it.
- Do not say checks passed unless the commands actually ran.
- Do not modify files as part of branch prep unless that edit was explicitly
  requested.
