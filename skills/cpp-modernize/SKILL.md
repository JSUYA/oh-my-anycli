---
name: cpp-modernize
description: Migrates C-style or pre-C++11 code on the touched files to modern C++17/20 idioms with per-hunk risk classification, refusing changes that would break ABI or alter observable behavior.
version: 1.0.0
when_to_use: User invokes "/cpp-modernize", asks to "modernize this C++ file", or wants to bring legacy headers up to a current standard before review.
inputs:
  - name: target
    description: Optional file or directory. Defaults to files changed on the current git branch versus the merge base.
  - name: standard
    description: Optional override (c++17, c++20). Defaults to the standard detected from build flags.
required_tools: [bash, read, edit]
---

# C++ Modernize Skill

## Goal

Convert legacy C or pre-C++11 patterns in the touched files to modern, idiomatic C++17 or C++20 without changing observable behavior or breaking ABI. Every proposed edit must be classifiable as SAFE, NEEDS-REVIEW, or API-BREAKING; API-BREAKING edits are reported but not applied.

## Inputs

- `target`: file, directory, or empty (changed files on current branch).
- `standard`: optional `-std=` override; otherwise detect from `CMakeLists.txt`, `Makefile`, `compile_commands.json`, or `meson.build`.

## Steps

1. Resolve the standard.
   ```bash
   # Prefer compile_commands.json if present
   if [ -f compile_commands.json ]; then
     grep -hoE '\-std=[a-z+0-9]+' compile_commands.json | sort -u
   fi
   # CMake fallback
   grep -nE 'CMAKE_CXX_STANDARD|set\(CMAKE_CXX_STANDARD|cxx_std_' CMakeLists.txt 2>/dev/null
   ```
   If no standard is found, ask the user before assuming. Do not silently upgrade a project from C++98.

2. Resolve target files.
   ```bash
   git diff --name-only --diff-filter=ACMRT $(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main) -- '*.cpp' '*.cc' '*.cxx' '*.h' '*.hpp' '*.hxx'
   ```

3. For each file, scan for modernization opportunities (regex hints below). Treat hits as candidates, not facts; confirm by reading surrounding code.

   | Pattern | Modern replacement | Risk |
   |---------|-------------------|------|
   | `NULL`, `0` as pointer | `nullptr` | SAFE |
   | `typedef X Y;` | `using Y = X;` | SAFE |
   | Manual `for (int i = 0; i < v.size(); ++i)` over container | range-for | SAFE if no index dependency |
   | Raw `new` + `delete` pair scoped to one function | `std::unique_ptr<T>` | NEEDS-REVIEW (ownership) |
   | Owning raw pointer in class members | `std::unique_ptr` / `std::shared_ptr` | API-BREAKING (header change) |
   | `T*` out-param + bool return | `std::optional<T>` | API-BREAKING |
   | Pair of `T*, size_t` | `std::span<T>` (C++20) | API-BREAKING |
   | Long iterator types | `auto` | SAFE if RHS is obvious |
   | C-style cast `(T)x` | `static_cast<T>(x)` etc. | SAFE for arithmetic; NEEDS-REVIEW for pointer |
   | `std::tuple` + `std::get<N>` | structured bindings | SAFE in local scope |
   | `enum E { ... }` | `enum class E { ... }` | API-BREAKING |
   | `#define CONST 42` | `constexpr int CONST = 42;` | NEEDS-REVIEW (linkage) |
   | Functions returning by value w/o `[[nodiscard]]` where return is meaningful | add `[[nodiscard]]` | SAFE behaviorally, NEEDS-REVIEW in headers |
   | Copy in arguments where move would suffice | `std::move` at call sites + value param | NEEDS-REVIEW |
   | `boost::optional`, `boost::variant` | `std::optional`, `std::variant` (if std >= 17) | NEEDS-REVIEW (semantic diffs) |

4. Generate diffs per file. Group hunks by risk class. Do not apply API-BREAKING hunks. For NEEDS-REVIEW, present the diff and require explicit user approval per hunk before applying. SAFE hunks may be applied in a single batch only after the user approves the SAFE summary.

5. After applying any edits, re-run a syntax check if a compiler is available, but do not run a full build:
   ```bash
   # Best-effort syntax check on modified files only
   command -v clang++ >/dev/null && clang++ -fsyntax-only -std=c++17 path/to/file.cpp
   ```

6. Report unmodified API-BREAKING candidates with file:line and a one-line rationale so the user can decide separately.

## Detailed pattern guidance

Below are extra notes for the trickier patterns where a textual rewrite often misses semantic differences.

### `auto` in declarations

Use `auto` when the right-hand side makes the type obvious at the call site (constructors, factories, container methods returning iterators). Avoid `auto` when the function name does not encode the result type (`compute()`, `process()`); a reader would have to chase through the codebase to learn what `x` is. For lambdas, prefer `auto` for the lambda variable itself but spell out parameter types when the lambda is non-trivial.

### Range-for with index dependency

A loop like `for (size_t i = 0; i < v.size(); ++i) { log("idx=%zu val=%d", i, v[i]); }` cannot become a plain range-for; either keep the index loop, switch to `enumerate`-style helper, or restructure the call. Replacing it with `for (auto& x : v)` and dropping the index is a behavior change for the log output.

### Smart pointer ownership

`unique_ptr<T>` for unique ownership; `shared_ptr<T>` only when ownership is genuinely shared and the cost of atomic refcount is acceptable. Never default to `shared_ptr` "to be safe": shared ownership is harder to reason about, not easier. For non-owning observation, raw `T*` (or `T&` if non-null) is correct.

### `const` correctness during modernization

If you switch a parameter from `const T&` to `T` (sink + move), you give up `const`-ness internally. That can be the right choice for value semantics but it is a behavior signal to readers; flag NEEDS-REVIEW.

### `[[nodiscard]]` placement

Apply on functions whose return value is the entire point of the call (factories, error codes, `try_*` operations, `unique_ptr<T>` factories). Skip on builders/setters that return `*this` for chaining; the caller may legitimately discard.

### Header-only constants

Pre-`inline constexpr` (C++17), header-defined `const` storage in multiple TUs caused ODR pain. Modern: `inline constexpr int kFoo = 42;` in a header is safe. `static constexpr int kFoo = 42;` inside a class is also fine.

### Move semantics in arguments

A common modernization is changing `void take(const Foo& f)` + caller `take(make_foo())` to `void take(Foo f)` + caller `take(std::move(make_foo()))`. The sink-by-value pattern is appropriate when the function will store the argument; it is a pessimization when the function only reads from it. Always inspect the callee's body before suggesting.

### Structured bindings outside locals

`auto [k, v] = *map.begin();` is fine for a local binding. Returning a structured binding from a function requires either `std::tuple` / `std::pair` / a struct; the binding itself is not a type. A common mistake is to use structured bindings in a class data member declaration — they cannot live there.

### `std::optional<T&>` does not exist

If you find `boost::optional<T&>` in legacy code, you cannot simply switch to `std::optional<T&>`; the std variant disallows reference types. Options: switch to `T*` (with `nullptr` for absence) or wrap in `std::reference_wrapper<T>`.

## Output format

```markdown
### cpp-modernize report

Standard detected: c++17 (from CMakeLists.txt:42)
Files scanned: 4

#### path/to/foo.cpp
- SAFE (12 hunks): nullptr (3), range-for (2), using-alias (1), static_cast (4), structured bindings (2)
- NEEDS-REVIEW (2 hunks):
  - L88-95: raw new/delete pair → unique_ptr (verify exception path in caller)
  - L210: copy-by-value param → consider sink + std::move
- API-BREAKING (1 finding, NOT applied):
  - L14: public member `Buffer* buf` → unique_ptr would break inline destructor for downstream callers

#### path/to/bar.h
- SAFE (0)
- NEEDS-REVIEW (0)
- API-BREAKING (1, NOT applied):
  - L7: `enum Color` → `enum class Color` would break implicit int conversions in 4 call sites

Apply SAFE hunks across all files? [y/N]
```

## Anti-patterns

- Do not apply API-BREAKING changes silently. Header churn ripples through every translation unit; flag and let the user decide.
- Do not introduce dependencies on a newer standard than the project's build system declares. Upgrading to C++20 features in a C++17 project breaks the build.
- Do not rewrite hot loops to range-for when the existing index is used elsewhere (e.g., in logging, error messages, or paired arrays).
- Do not blanket-replace owning raw pointers with `shared_ptr` "to be safe". Default to `unique_ptr`; reach for `shared_ptr` only when shared ownership is real.
- Do not add `[[nodiscard]]` to setters or fluent-builder methods that legitimately discard the return.
- Do not convert `boost::optional` to `std::optional` without checking that the project is not relying on Boost-specific semantics (e.g., `boost::optional<T&>` references — `std::optional` does not allow reference types).
- Do not change `enum` to `enum class` in a public header unless the user accepts the API break.
- Do not modernize generated code (protobuf, flatbuffers, bison/yacc output, moc files). Identify generators by the typical "DO NOT EDIT" header.
- Do not move `#define` constants to `constexpr` inside headers without considering ODR — prefer `inline constexpr` (C++17+) for header-defined constants.
- Do not replace `printf`-family logging with `std::format`/`std::print` unless the project already uses C++20 and has confirmed a runtime that supports it.
- Do not use `auto` so aggressively that the type is no longer obvious to a reader (e.g., `auto x = compute();` where `compute` returns a domain type).
- Do not assume `std::filesystem` is available on every embedded toolchain claiming C++17; some only ship the language, not the library.
- Do not delete commented-out code that you did not write, even if the modernization made it obviously dead.
- Do not run clang-format or apply unrelated style fixes during a modernize pass; that belongs to a separate skill.
- Do not rewrite virtual function signatures to add `override` on private virtuals you cannot fully audit; missing `override` may indicate intentional shadowing.
- Do not introduce `std::move` on a `const` parameter; it silently degrades to a copy and confuses readers.
