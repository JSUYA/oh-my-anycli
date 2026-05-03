---
name: cpp-static-analysis
description: Runs clang-tidy (preferred) or cppcheck (fallback) on the touched C/C++ files only and triages findings into AUTO-FIXABLE, MANUAL-FIXABLE, and IGNORE-CANDIDATE classes, refusing mass autofix without per-file approval.
version: 1.0.0
when_to_use: User invokes "/cpp-static-analysis", asks to "run clang-tidy", or wants a static-analysis pass before opening a PR.
inputs:
  - name: target
    description: Optional file or directory. Defaults to the C/C++ files changed on the current git branch.
  - name: checks
    description: Optional clang-tidy `-checks=` override. Defaults to the project's `.clang-tidy` or a conservative built-in set.
required_tools: [bash, read, edit]
---

# C++ Static Analysis Skill

## Goal

Provide accurate, scoped clang-tidy / cppcheck findings on the changed files, classify each diagnostic by fix safety, and apply autofixes only with per-file user approval. Refuse to silently mass-modify legacy code.

## Inputs

- `target`: file/directory; default is files changed on the current branch.
- `checks`: optional override for clang-tidy `-checks=` argument; defaults to the project's `.clang-tidy` file or this fallback when none exists:
  `bugprone-*,cert-*,clang-analyzer-*,cppcoreguidelines-*,modernize-*,performance-*,portability-*,readability-*,-modernize-use-trailing-return-type,-readability-identifier-length,-cppcoreguidelines-avoid-magic-numbers,-readability-magic-numbers`

## Steps

1. Detect tooling.
   ```bash
   command -v clang-tidy >/dev/null && clang-tidy --version
   command -v cppcheck >/dev/null && cppcheck --version
   ```
   Prefer clang-tidy when both are available. If neither is installed, stop and tell the user which tool to install (do not attempt installation).

2. Detect the compilation database. Without one, clang-tidy cannot resolve includes correctly on most projects.
   ```bash
   ls compile_commands.json build/compile_commands.json 2>/dev/null | head -1
   ```
   If absent, suggest:
   - CMake: `cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON`
   - Bear: `bear -- make`
   - Meson: configure with `-Dbackend=ninja`; ninja generates one automatically.
   Without a compilation database, run clang-tidy with explicit `--` flags only after confirming with the user (results may be incomplete).

3. Resolve target files (changed-files only).
   ```bash
   git diff --name-only --diff-filter=ACMRT \
     $(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main) \
     -- '*.cpp' '*.cc' '*.cxx' '*.c' '*.h' '*.hpp' '*.hxx'
   ```

4. Run clang-tidy on the changed files.
   ```bash
   clang-tidy -p build --quiet --warnings-as-errors='' \
     --header-filter='^(?!.*(/build/|/third_party/|/vendor/|/external/)).*' \
     <changed-files>
   ```
   Capture full output for parsing. Do not pass `--fix` on the first run.

5. If clang-tidy is unavailable, fall back to cppcheck:
   ```bash
   cppcheck --enable=warning,style,performance,portability,information \
     --inline-suppr --suppress=missingIncludeSystem \
     --template='{file}:{line}:{column}: {severity}: {message} [{id}]' \
     --quiet <changed-files>
   ```

6. Triage every diagnostic into one of:

   - **AUTO-FIXABLE**: clang-tidy ships `--fix` for it AND the check is in this safe set:
     `modernize-use-nullptr, modernize-use-override, modernize-use-using, modernize-use-equals-default, modernize-use-equals-delete, modernize-redundant-void-arg, readability-redundant-*, readability-braces-around-statements, readability-isolate-declaration, performance-unnecessary-value-param (locals only), bugprone-suspicious-include, llvm-namespace-comment`.
   - **MANUAL-FIXABLE**: real bug or modernization that requires human judgment (e.g., `bugprone-use-after-move`, `cppcoreguidelines-pro-bounds-pointer-arithmetic`, `cert-err58-cpp`, `clang-analyzer-cplusplus.NewDeleteLeaks`, anything in `cert-*`).
   - **IGNORE-CANDIDATE**: known noisy in legacy code (`readability-identifier-length`, `readability-implicit-bool-conversion`, `cppcoreguidelines-pro-type-vararg`, `cppcoreguidelines-avoid-magic-numbers`, `modernize-use-trailing-return-type`, `fuchsia-*`, `llvmlibc-*`). Do not silently suppress; recommend the user add a project-wide `.clang-tidy` exclusion if the count is high.

7. Present a summary per file. Ask the user, per file, whether to apply AUTO-FIXABLE diagnostics. Only on explicit approval, run:
   ```bash
   clang-tidy -p build --fix --fix-errors --checks='<approved-list>' <one-file>
   ```
   Apply per file, never globally in one shot. Show the resulting diff before moving on to the next file.

8. For MANUAL-FIXABLE diagnostics, propose a patch hunk in the report; do not apply.

9. For IGNORE-CANDIDATEs, list them with counts and a note that suppression should be project-wide via `.clang-tidy`, not in-line `// NOLINT`. Do not add `// NOLINT` comments unless the user explicitly asks for them.

## Detailed check guidance

### `bugprone-use-after-move`
Triggers when a value is read after `std::move(x)`. The fix is rarely an autofix; either remove the move, copy first, or restructure to avoid the read. Look 20 lines around the diagnostic; the move and the read can be far apart in conditional branches.

### `clang-analyzer-cplusplus.NewDeleteLeaks`
Path-sensitive; the analyzer tracks allocation across branches. Common false positive: ownership transferred to an opaque registration callback. If genuinely a leak, prefer `unique_ptr` over manual `delete` insertion.

### `cppcoreguidelines-pro-type-reinterpret-cast`
Almost always justified in low-level code (FFI, serialization, hardware registers); add a project-wide exclusion in `.clang-tidy` for the modules where it lives, do not litter `// NOLINT` everywhere.

### `modernize-use-trailing-return-type`
Stylistic preference, not a defect. Project-wide noise generator; default to IGNORE-CANDIDATE.

### `readability-identifier-length`
Defaults flag any name shorter than 3 chars. In math-heavy code (`x`, `y`, `z`, `i`, `j`, `k`) the warning is wrong by convention. Set `MinimumVariableNameLength: 1` in `.clang-tidy` if the project wants that style.

### `cert-err58-cpp`
Static initializers that throw cannot be safely caught. Often genuine in legacy code with global registries. The fix is usually to move initialization into `main` or a Meyers singleton.

### `performance-unnecessary-value-param`
Triggers when a function takes a parameter by value but never modifies it and never moves from it. Fix: change to `const T&`. False positive on small trivial types where pass-by-value is cheaper than indirection (`int`, `enum`, two-pointer-or-less).

### `cppcoreguidelines-init-variables`
Wants every variable initialized at declaration. Conflicts with the idiom of declare-then-output-param-fill (`int v; if (try_get(&v)) { use(v); }`). Often noise; consider IGNORE-CANDIDATE for projects using TryGet-style APIs.

### `bugprone-easily-swappable-parameters`
Flags adjacent parameters of the same type. Real bug source (transposed args), but very noisy in C-style APIs. Fix is usually a strong-typedef wrapper, which is a design change beyond an autofix.

## Output format

```markdown
### cpp-static-analysis report

Tool: clang-tidy 17.0.6
Compilation DB: build/compile_commands.json (147 TUs)
Files scanned: 5 (changed on branch)
Findings: 38 (AUTO-FIXABLE 14, MANUAL-FIXABLE 9, IGNORE-CANDIDATE 15)

#### src/parser.cpp (12 findings)
AUTO-FIXABLE (5): modernize-use-nullptr (3), readability-redundant-string-init (1), modernize-use-override (1)
MANUAL-FIXABLE (3):
  - L142:14 [bugprone-use-after-move] `cfg` is read after std::move
  - L201:9  [clang-analyzer-cplusplus.NewDeleteLeaks] `payload` may leak on early return at L207
  - L233:5  [cert-err58-cpp] thread-unsafe static initializer `g_table`
IGNORE-CANDIDATE (4): readability-identifier-length (3), modernize-use-trailing-return-type (1)

Apply AUTO-FIXABLE fixes for src/parser.cpp? [y/N]

#### src/util.h (6 findings)
...
```

## Anti-patterns

- Do not run `clang-tidy --fix` over the entire repository. Even safe checks can produce conflicting fixes when applied across many files at once.
- Do not pass `-DCMAKE_BUILD_TYPE=Debug` or trigger a full reconfigure as a side effect; only use the existing `compile_commands.json`.
- Do not enable `cppcoreguidelines-owning-memory` on legacy C-style code. The `gsl::owner` annotation it expects is rarely present and the noise drowns real findings.
- Do not "fix" `readability-identifier-length` warnings by renaming variables in unrelated code; that is scope creep.
- Do not apply `modernize-pass-by-value` autofix to constructors with non-trivially-movable members; it can pessimize.
- Do not silence findings with `// NOLINT` to make the build green. Either fix it, leave it open with a TODO that references the diagnostic, or suppress it project-wide in `.clang-tidy`.
- Do not run cppcheck with `--enable=all`; the `unusedFunction` check is unreliable across translation units and produces false positives that bury real issues.
- Do not run static analysis on generated headers (moc, protobuf, flatbuffers); add them to `--header-filter` exclusion or `.clang-tidy` `HeaderFilterRegex`.
- Do not change diagnostic severity levels in `.clang-tidy` to hide warnings; that is the same as `// NOLINT` at scale.
- Do not run clang-tidy without a compilation database on a non-trivial project and call the result "clean" — it almost certainly missed include-dependent warnings.
- Do not mix clang-tidy versions across CI and local; pin one in the project's tooling docs (do not edit those docs in this skill).
- Do not invoke `clang-tidy` with `-warnings-as-errors=*` during triage; it short-circuits on the first finding and you lose the full picture.
- Do not apply `modernize-use-auto` autofix in headers — it can change the public type if the right-hand side type changes later.
- Do not assume cppcheck and clang-tidy will agree; treat them as complementary, not redundant.
- Do not autofix files that have unstaged changes; stash or commit first to keep the diff clean.
