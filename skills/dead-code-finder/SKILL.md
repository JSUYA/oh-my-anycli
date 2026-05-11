---
name: dead-code-finder
description: Finds unused exports, unused imports, and unreachable code. Uses language-aware tools when installed (tsc, ruff, vulture, staticcheck) and falls back to a grep-based shallow check otherwise. Always presents findings; never deletes without confirmation.
version: 1.0.0
when_to_use: User asks "/dead-code", "any unused code?", "clean up imports", or wants to prune a module before refactoring. Useful before extracting a library or shrinking a bundle.
inputs:
  - name: target
    description: Optional file or directory to scope the scan to. Defaults to the project's source root (src/, lib/, app/, or pkg/ — first match).
required_tools: [bash, read, grep]
---

# Dead Code Finder Skill

## Goal

Find likely unused code, rank confidence, and avoid deleting anything without
explicit confirmation.

## Boundary

Use this skill to find deletion candidates. Use `refactor-helper` when the user
has already chosen a specific removal or restructuring task. Use `lint-fix` for
configured linter diagnostics such as unused imports when the linter is the
source of truth.

## Workflow

1. Resolve scope from the user or infer source roots in this order:
   `src/`, `lib/`, `app/`, `pkg/`, `internal/`, current directory.
2. Detect the language and prefer configured tools:
   - TypeScript/JavaScript: `tsc --noEmit`, `eslint`, `ts-prune` if present;
   - Python: `ruff`, `vulture`, `pyflakes` if present;
   - Go: `go test`, `staticcheck` if present;
   - Rust: `cargo check`, `cargo clippy`;
   - C/C++: compiler warnings, `clang-tidy`, `cppcheck`.
3. If language-aware tools are not present, use shallow grep only and label
   findings as LOW confidence.
4. Classify each candidate:
   - HIGH: private symbol has no references and is not exported/reflected;
   - MEDIUM: exported symbol has no local references but may be public API;
   - LOW: generated, plugin, test fixture, reflection, string-based reference,
     CLI entrypoint, framework hook, or migration.
5. Before recommending deletion, check common dynamic entrypoints:
   `package.json` scripts/exports, routing tables, DI containers, migrations,
   plugin manifests, templates, and docs.

## Output Format

```markdown
### Dead-code candidates

#### HIGH confidence
- `src/foo.ts:88`: private function `formatLegacyName` has no references in
  source or tests.
  verify: remove locally and run `npm test -- foo`

#### MEDIUM confidence
- `src/index.ts:12`: exported `oldHelper` has no local references; check public
  API consumers before removal.

#### Not safe to remove
- `migrations/0042.sql`: historical migration, intentionally retained.
```

## Guardrails

- Do not delete code from this skill.
- Do not treat absence of grep hits as proof when reflection, routing, plugins,
  generated code, or public exports are involved.
- Do not remove migrations, snapshots, fixtures, or compatibility shims without
  a project-specific reason.
