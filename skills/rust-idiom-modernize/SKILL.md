---
name: rust-idiom-modernize
description: Migrates older Rust patterns in the touched files to current idioms (try! to ?, manual loops to iterators, match to combinators, .unwrap to ? in non-test code, error handling via existing project pattern) without introducing new dependencies unflagged.
version: 1.0.0
when_to_use: User invokes "/rust-modernize", asks to "modernize this Rust code", or wants idiom cleanup before review.
inputs:
  - name: target
    description: Optional path. Defaults to Rust files changed on the current branch.
  - name: error_pattern
    description: Optional override (anyhow, thiserror, eyre, std). Defaults to the pattern detected from existing code.
required_tools: [bash, read, edit]
---

# Rust Idiom Modernize Skill

## Goal

Bring legacy Rust idioms in touched files up to current style without introducing new dependencies unflagged and without changing observable behavior. Match the project's existing error-handling pattern; do not impose a different one.

## Inputs

- `target`: file/directory; default is changed Rust files on the branch.
- `error_pattern`: optional override; otherwise detect from `Cargo.toml` deps and existing code (`anyhow::Result`, `thiserror::Error` derives, `Result<_, Box<dyn Error>>`, `eyre::Result`, plain `std::io::Result`, etc.).

## Steps

1. Detect the project's edition.
   ```bash
   grep -nE 'edition\s*=' Cargo.toml
   ```
   - 2015: very legacy; many idioms below do not apply (e.g., `dyn Trait` was added in 2018).
   - 2018: `?` operator, `dyn Trait`, NLL.
   - 2021: disjoint captures in closures, `panic!` macro changes.
   - 2024: `unsafe extern`, `gen` blocks, prelude additions.

2. Detect error-handling pattern.
   ```bash
   grep -nE 'use\s+(anyhow|thiserror|eyre|color_eyre|snafu)' --include='*.rs' -r .
   grep -nE '#\[derive\(.*Error' --include='*.rs' -r .
   grep -nE 'Result<.*Box<dyn' --include='*.rs' -r .
   ```
   Pick the dominant pattern. If multiple, ask the user which to align to.

3. Resolve target files.
   ```bash
   git diff --name-only --diff-filter=ACMRT \
     $(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main) \
     -- '*.rs'
   ```

4. Scan for legacy patterns. Each row below is a candidate; confirm by reading context.

   ### A. Operator and macro modernization

   | Legacy | Modern | Notes |
   |--------|--------|-------|
   | `try!(expr)` | `expr?` | Macro removed in edition 2018. |
   | `panic!("{}", "literal")` | `panic!("literal")` | Edition 2021 removed implicit `Display` formatting fall-through. |
   | `match x { Ok(v) => v, Err(e) => return Err(e.into()) }` | `x?` | Only when the surrounding signature returns `Result<_, E>` where `e.into(): E`. |
   | `result.map(\|v\| v).unwrap_or_else(\|e\| ...)` | `result.unwrap_or_else(\|e\| ...)` | Drop identity `.map`. |
   | `if let Some(x) = opt { ... } else { ... }` | `match opt { ... }` only when both arms exist; if-let-else (Rust 1.65+) for single-bind-or-default. |
   | `let-else`: `let Some(x) = opt else { return Err(...) }` | preferred over `if let Some(x) = opt { ... do work ... } else { return ... }` when the `else` always diverges (Rust 1.65+). |

   ### B. Iterator combinators (when shorter and not less clear)

   | Legacy | Modern |
   |--------|--------|
   | `for i in 0..v.len() { let x = &v[i]; ... }` | `for x in &v { ... }` |
   | `for (i, x) in v.iter().enumerate()` when `i` unused | `for x in &v` |
   | manual `let mut acc = 0; for x in v { acc += x.field; }` | `v.iter().map(\|x\| x.field).sum::<u64>()` |
   | manual filter + push to Vec | `iter.filter(...).collect()` |
   | `match opt { Some(x) => f(x), None => default }` | `opt.map_or(default, f)` (when `default` is cheap) or `opt.map(f).unwrap_or(default)` |
   | `match opt { Some(x) => Some(g(x)), None => None }` | `opt.map(g)` |
   | `match res { Ok(x) => Ok(g(x)), Err(e) => Err(e) }` | `res.map(g)` |
   | `match opt { Some(x) if pred(&x) => Some(x), _ => None }` | `opt.filter(pred)` |
   | `vec.iter().cloned().collect::<Vec<_>>()` of small Copy types | `vec.to_vec()` |

   ### C. Error handling

   - `Result<T, Box<dyn Error>>` in application code → `anyhow::Result<T>` (if anyhow is in deps).
   - `Result<T, Box<dyn Error>>` in library code → custom error enum with `thiserror::Error` (if thiserror is in deps).
   - `.unwrap()` in non-test code → `?` if the function returns `Result`; `.expect("reason")` if it must panic.
   - `Result<T, E1>` propagated where `E2: From<E1>` is expected → `?` (already idiomatic; flag legacy `try!`).
   - Do not introduce `anyhow` or `thiserror` if neither is in `Cargo.toml`. Flag the suggestion and ask the user.

   ### D. Common micro-cleanups

   | Legacy | Modern |
   |--------|--------|
   | `.clone().to_string()` on `&str` | `.to_string()` |
   | `String::from(s).clone()` | `s.to_string()` |
   | `format!("{}", x)` where `x: Display` and the result is the only `format!` arg | `x.to_string()` |
   | `vec![]` followed by `.push(...)` × N | `vec![a, b, c]` |
   | `&**arc` or `&**box` | `&arc` (auto-deref usually suffices) |
   | `Option::is_some()` then `.unwrap()` | `if let Some(x) = opt` |
   | manual `Default::default()` for type T where `T: Default` and a literal works | the literal (`0`, `String::new()`, `Vec::new()`) |
   | `.into_iter().collect::<Vec<_>>()` where the source is already `Vec<T>` | drop the round-trip |
   | `&Vec<T>` as a function parameter | `&[T]` |
   | `&String` as a function parameter | `&str` |
   | `-> &Vec<T>` as a return type from a method | `-> &[T]` |
   | `String::from("literal")` | `"literal".to_string()` is equivalent; choose project style and be consistent |
   | `.lines().map(\|l\| l.to_string()).collect::<Vec<_>>()` | consider keeping the borrow if downstream allows |

   ### E. Concurrency / async

   - `tokio::spawn(async move { ... }).await.unwrap()` in tests → propagate via `?` if test returns `Result`.
   - `Arc::clone(&x)` is preferred over `x.clone()` for clarity (but `.clone()` is correct).
   - `mpsc::channel()` (unbounded) → bounded `mpsc::channel(n)` if backpressure matters; flag as NEEDS-REVIEW.
   - `.await` on a `Mutex::lock()` from `std::sync::Mutex` inside an async context → switch to `tokio::sync::Mutex` or restructure.

5. For each candidate, generate a diff hunk. Group findings per file, then per category (operator, iterator, error, micro). Apply only after explicit user approval per file.

6. After applying, run `cargo check` (not `cargo build`) on the affected package to confirm the file compiles.
   ```bash
   cargo check --all-targets -p <package>
   ```

## Output format

```markdown
### rust-idiom-modernize report

Edition: 2021
Error pattern detected: anyhow (in workspace deps)
Files scanned: 5

#### crates/cli/src/cmd.rs (11 candidates)
Operator (3):
  - L42  try!(parse(s)) → parse(s)?
  - L88  match res { Ok(v) => v, Err(e) => return Err(e.into()) } → res?
  - L120 if let Some(x) = opt { do(x) } else { return Err(...) } → let Some(x) = opt else { return Err(...) }

Iterator (4):
  - L66  manual for+push → .filter().collect()
  - L99  for i in 0..v.len() → for x in &v
  - L155 match opt { Some(x) => Some(g(x)), None => None } → opt.map(g)
  - L188 match res { Ok(x) => Ok(g(x)), Err(e) => Err(e) } → res.map(g)

Error (3):
  - L210 Result<T, Box<dyn Error>> → anyhow::Result<T> (matches workspace pattern)
  - L233 .unwrap() in production code path → ? (function already returns Result)
  - L260 .expect("should not fail") with no reason → add explanation or convert to ?

Micro (1):
  - L277 .clone().to_string() on &str → .to_string()

Apply Operator + Iterator + Micro fixes for crates/cli/src/cmd.rs? (Error category needs separate review) [y/N]
```

## Anti-patterns

- Do not introduce `anyhow`, `thiserror`, `eyre`, or any other dependency without flagging it as a separate proposal. Adding to `Cargo.toml` is a project decision, not an idiom fix.
- Do not change `Result<T, E>` return types in public APIs without flagging the API break — downstream callers' `?` chains depend on the error type.
- Do not "modernize" `match` to `map_or` if the `default` arm has side effects; `map_or` always evaluates the default.
- Do not replace `.unwrap()` with `?` in a function whose signature does not already return `Result`; that requires changing the signature, which is a behavior change.
- Do not replace `String::from("...")` with `"...".to_string()` (or vice versa) project-wide; either is fine — match local style.
- Do not collapse `if let Some(x) = opt { do(x) }` into a method-chain version when the body is multi-statement; readability wins.
- Do not convert `for` loops with `break`/`continue` to iterator chains unless the chain remains readable. `try_for_each` exists but is often less clear than the loop.
- Do not introduce `.iter().copied()` over `.iter().cloned()` for non-`Copy` types; that is a compile error.
- Do not silently change `Vec<T>` to `&[T]` in a function that calls `.push()` — type inference will fail somewhere downstream.
- Do not "modernize" `Box<dyn Error>` away in tests; tests benefit from broad error catching, and the dynamic dispatch cost is irrelevant.
- Do not assume `let-else` is available; check edition / MSRV (Rust 1.65+).
- Do not auto-replace `format!("{}", x)` with `x.to_string()` if the project sets a custom `Display` impl that uses the formatter's options (precision, fill, etc.).
- Do not silently bump MSRV when applying these idioms; record the minimum Rust version each change requires and roll up at the end of the report.
- Do not modernize generated code (`prost-build`, `tonic-build`, `bindgen` output, `build.rs` artifacts).
- Do not run `cargo fmt` as part of this skill; modernization commits should be reviewable on their own first.
