---
name: git-commit-helper
description: Drafts a conventional commit message from staged changes. Honors any project commit conventions found in CLAUDE.md, AGENTS.md, or CONTRIBUTING; otherwise emits a clean, neutral message.
version: 1.1.0
when_to_use: User asks "/commit", "make a commit message", or has staged changes ready to commit. Especially useful when the user wants a concise Conventional Commits-style message.
inputs:
  - name: scope_hint
    description: Optional scope (e.g. "auth", "ui") if the user wants to override the auto-detected scope.
required_tools: [bash, read]
---

# Git Commit Helper Skill

## Goal

Prepare a focused commit plan and message from staged changes while honoring
project commit rules.

## Boundary

Use this skill only for staged-change commit readiness and commit messages. Use
`branch-prep` for branch state, lint/test readiness, rebase, or push decisions.
Use `pr-description-writer` for PR body text after commits exist.

## Workflow

1. Inspect repository rules first: `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING*`,
   `.gitmessage`, and recent commits.
2. Inspect staged changes:
   ```bash
   git status --short
   git diff --cached --stat
   git diff --cached --name-only
   git diff --cached
   ```
3. If nothing is staged, do not invent a commit. Report what is modified and
   ask whether to stage files.
4. Check commit scope:
   - staged files should share one intent;
   - generated files should be intentional;
   - secrets, local config, and unrelated churn should not be staged.
5. Draft a concise message. Prefer the existing project style; otherwise use a
   conventional form like `type(scope): summary`.
6. If the user asked to create the commit, use the project-required author and
   committer identities, and never add URLs or co-author trailers.

## Output Format

```markdown
### Commit readiness
- staged files: <n>
- intent: <one sentence>
- risk: <tests or missing checks>

Suggested message:
`fix(install): keep manifest pruning portable on macOS`

Command:
`GIT_COMMITTER_NAME="JunsuChoi" GIT_COMMITTER_EMAIL="jsuya.choi@samsung.com" git commit --author="JunsuChoi <jsuya.choi@samsung.com>" -m "..."`
```

## Guardrails

- Do not commit unstaged files unless the user explicitly asked to stage them.
- Do not include issue, PR, or external URLs in commit messages.
- Do not add `Co-authored-by:` trailers.
- Do not claim tests were run unless they were.
