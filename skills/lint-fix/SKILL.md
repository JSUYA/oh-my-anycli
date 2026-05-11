---
name: lint-fix
description: Detects the project's configured linter and runs it. Surfaces fixable issues, proposes patches, and applies fixes only after explicit user approval. Refuses to invent a linter that the project did not configure.
version: 1.0.0
when_to_use: User asks "/lint-fix", "run the linter", "fix lint warnings", or wants to clean up a file before review. Useful before opening a PR or after a large refactor.
inputs:
  - name: target
    description: Optional file or directory path to scope the linter to. Defaults to the project root (whatever the linter's default scope is).
required_tools: [bash, read, edit]
---

# Lint Fix Skill

## Goal

Run the configured linter, separate auto-fixable issues from risky ones, and
apply fixes only when the request explicitly allows edits.

## Boundary

Use this skill for the project's generic configured lint command. Prefer
language/domain-specific skills when the user names their tool or domain:
`rust-clippy-triage` for `cargo clippy`, `cpp-static-analysis` for
`clang-tidy`/`cppcheck`, and `csharp-analyzer-fix` for Roslyn or
`dotnet format`. Use `refactor-helper` for behavior-preserving code changes not
driven by linter diagnostics.

## Workflow

1. Detect configured linters from project files: `package.json`, `pyproject.toml`,
   `ruff.toml`, `.eslintrc*`, `Cargo.toml`, `go.mod`, `.golangci.yml`,
   `.clang-tidy`, `.editorconfig`, `Makefile`, and CI.
2. Run the narrowest safe lint command for the requested target. Do not install
   tools or invent a new linter.
3. Classify results:
   - SAFE-AUTOFIX: formatting/import/order changes with project tooling;
   - NEEDS-REVIEW: code transformations, public API changes, broad rewrites;
   - FALSE-POSITIVE: generated/vendor/test fixture or intentional suppression.
4. If edits are allowed, apply only SAFE-AUTOFIX items and keep changes scoped
   to lint output. Otherwise, present the patch plan.
5. Re-run the same lint command after edits and report exact output summary.

## Output Format

```markdown
### Lint result
Command: `npm run lint -- src/foo.ts`

#### Fixed
- `src/foo.ts`: import order

#### Needs review
- `src/api.ts:42`: `no-explicit-any`; requires choosing a public type

#### Verification
- `npm run lint -- src/foo.ts`: passed
```

## Guardrails

- Do not add or change linter configuration unless explicitly asked.
- Do not silence diagnostics with blanket ignore comments.
- Do not run formatters over unrelated files.
- Do not claim autofix safety for behavior-changing transformations.
