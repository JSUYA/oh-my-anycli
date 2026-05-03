---
name: rust-clippy-triage
description: Runs cargo clippy with all-targets and pedantic lints on the touched files, groups findings by category, and applies cargo clippy --fix only after explicit per-file user approval while honoring existing #[allow(...)] attributes.
version: 1.0.0
when_to_use: User invokes "/rust-clippy", asks to "triage clippy warnings", or wants a clippy pass before opening a PR.
inputs:
  - name: target
    description: Optional package or path. Defaults to the workspace and filters to files changed on the current branch.
  - name: pedantic
    description: Set to false to skip clippy::pedantic. Defaults to true.
required_tools: [bash, read, edit]
---

# Rust Clippy Triage Skill

## Goal

Run cargo clippy with a consistent ruleset, narrow output to the files changed on the current branch, classify findings into ALWAYS-FIX / STYLE-PREFERENCE / DENY-CANDIDATE, and apply autofixes only on explicit per-file approval.

## Inputs

- `target`: optional `-p <package>` or path filter; default is the workspace.
- `pedantic`: include `clippy::pedantic` lints (default true).

## Steps

1. Verify the toolchain and that clippy is installed.
   ```bash
   rustup component list --installed | grep -q '^clippy' || \
     { echo "clippy not installed; run: rustup component add clippy"; exit 1; }
   cargo --version && cargo clippy --version
   ```
   Do not run `rustup component add` from this skill; ask the user.

2. Detect the project's existing clippy configuration so the run respects the project's intent.
   ```bash
   ls clippy.toml .clippy.toml 2>/dev/null
   grep -nE 'lints\.|workspace\.lints|clippy::' Cargo.toml 2>/dev/null
   ```
   If a `[lints.clippy]` table exists in Cargo.toml (Rust 1.74+) or a `clippy.toml` is present, do not pass `-W` flags that conflict with it.

3. Resolve the file list (changed files on the branch).
   ```bash
   git diff --name-only --diff-filter=ACMRT \
     $(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main) \
     -- '*.rs'
   ```

4. Run clippy across the workspace, capture the JSON output, then filter to the changed files.
   ```bash
   PEDANTIC_FLAG="-W clippy::pedantic"
   [ "$pedantic" = "false" ] && PEDANTIC_FLAG=""
   cargo clippy --all-targets --all-features --message-format=json -- \
     -D warnings $PEDANTIC_FLAG \
     2>/dev/null | jq -r 'select(.reason=="compiler-message") | .message'
   ```
   Filter the JSON to entries whose `spans[].file_name` is in the changed-file set. Do not parse human-readable clippy output for triage; it is unstable across versions.

5. Triage every diagnostic into one of three buckets.

   ### ALWAYS-FIX (correctness, performance, suspicious)
   - `clippy::correctness` (entire group)
   - `clippy::suspicious` (entire group)
   - `clippy::perf` (entire group)
   - Selected high-value lints from `clippy::style`: `redundant_clone`, `needless_collect`, `useless_conversion`, `single_match_else`, `or_fun_call`, `iter_nth_zero`, `manual_strip`, `manual_map`, `redundant_pattern_matching`.
   - Selected from `clippy::pedantic`: `manual_assert`, `cast_lossless`, `explicit_iter_loop`, `redundant_else`, `unnecessary_wraps`.

   ### STYLE-PREFERENCE (default to fix, but accept user opinion)
   - Most of `clippy::style` and `clippy::complexity` not listed above.
   - `clippy::nursery` lints — these are unstable and can change behavior across releases.
   - `module_name_repetitions`, `must_use_candidate`, `missing_errors_doc`, `missing_panics_doc` — these are typical pedantic-noise lints in business code.

   ### DENY-CANDIDATE (rare but real false positives)
   - `clippy::pedantic::cast_possible_truncation` on intentional narrowing.
   - `clippy::pedantic::cast_sign_loss` on bit-width preserving conversions.
   - `clippy::pedantic::similar_names` on conventional pairs (`req`/`res`).
   - `clippy::needless_pass_by_value` on FFI-adjacent code where the signature is fixed.
   - `clippy::missing_const_for_fn` on functions whose constness is not part of their public contract.
   - For each: recommend `#[allow(clippy::lint_name)]` at the smallest scope (item, not crate) with a one-line `// reason: ...` comment.

6. Honor existing `#[allow(clippy::...)]` attributes already in code. Do not re-flag a lint that the project has explicitly silenced.

7. Apply autofixes only on explicit per-file approval.
   ```bash
   # Per file, after user says yes:
   cargo clippy --fix --allow-dirty --allow-staged \
     --message-format=human \
     -p <package> -- -D warnings $PEDANTIC_FLAG
   ```
   `--fix` rewrites only what clippy is confident about; some ALWAYS-FIX lints have no machine fix and must be patched by hand.

8. After applying any fixes, re-run clippy to confirm zero remaining warnings on the touched files; report the diff.

## Fix application notes

### `cargo clippy --fix` semantics
- Requires a clean working tree by default. Pass `--allow-dirty` and `--allow-staged` only when you have a specific reason; never use `--allow-no-vcs` (silently drops safety).
- Operates on the workspace target by default; pass `-p <package>` to scope.
- Some lints have `--fix` available but the rewrite is intentionally conservative; the diagnostic remains until a manual rewrite.

### Workspace lint configuration (Rust 1.74+)
Projects can centralize lint policy in the root Cargo.toml:
```toml
[workspace.lints.clippy]
pedantic = { level = "warn", priority = -1 }
needless_pass_by_value = "allow"
```
Per-crate overrides go in each crate's Cargo.toml under `[lints]`. Honor this configuration; do not pass conflicting `-W` / `-A` flags.

### Suppression scope
- `#![allow(clippy::lint_name)]` in lib.rs / main.rs — crate-wide; rarely justified.
- `#[allow(clippy::lint_name)]` on a module — appropriate for module-scoped patterns (e.g., FFI module silencing `cast_possible_truncation`).
- `#[allow(clippy::lint_name)]` on a single item — preferred default.
- `#[expect(clippy::lint_name)]` (Rust 1.81+) — preferred over `allow` because clippy will warn if the lint stops firing.

## Output format

```markdown
### rust-clippy-triage report

Toolchain: rustc 1.79.0 / clippy 0.1.79
Files scanned: 6 (changed on branch)
Lints config: workspace.lints.clippy in Cargo.toml (pedantic = "warn")
Findings: 27 (ALWAYS-FIX 9, STYLE-PREFERENCE 13, DENY-CANDIDATE 5)

#### crates/core/src/parser.rs (8 findings)
ALWAYS-FIX (3):
  - L42:13 [perf::redundant_clone] `.clone()` on `String` immediately moved
  - L88:5  [correctness::let_underscore_lock] `let _ = mutex.lock()` drops the guard immediately
  - L120:9 [perf::or_fun_call] `unwrap_or(expensive())` → `unwrap_or_else(|| expensive())`
STYLE-PREFERENCE (4):
  - L17:1  [style::needless_return]
  - L33:5  [pedantic::explicit_iter_loop]
  - L66:9  [pedantic::redundant_else]
  - L99:5  [complexity::needless_collect]
DENY-CANDIDATE (1):
  - L155:21 [pedantic::cast_possible_truncation] intentional u32→u16 narrowing for protocol field
    suggested: `#[allow(clippy::cast_possible_truncation)] // reason: protocol field is u16 by spec`

Apply ALWAYS-FIX autofixes for crates/core/src/parser.rs? [y/N]

#### crates/api/src/handler.rs (...)
...
```

## Anti-patterns

- Do not pass `-D clippy::all -D clippy::pedantic` and call the result "clean" — pedantic warnings are advisory by design and a clean run usually requires opinionated `#[allow]` annotations the project did not ask for.
- Do not use `cargo clippy --fix --allow-dirty` over the entire workspace in one shot. Some autofixes conflict across files and the diff becomes unreviewable.
- Do not blanket-add `#![allow(clippy::pedantic)]` at the crate root to make warnings disappear; that hides real findings forever.
- Do not enable `clippy::restriction` lints. They are mutually contradictory by design and turning the group on is documented as wrong.
- Do not "fix" `clippy::missing_errors_doc` by adding empty `# Errors` sections; the doc must explain what errors are returned and when.
- Do not apply `clippy::redundant_clone` autofixes blindly — sometimes the clone is required because the borrow checker cannot prove the original is no longer used (especially across `await` points).
- Do not run clippy with `--no-default-features` and call it complete; many lints fire only when feature-gated code is compiled.
- Do not assume `cargo clippy --fix` runs `rustfmt` afterwards; it does not. Run `cargo fmt` separately.
- Do not enable `clippy::cargo` lints in this skill; they require network access and depend on `Cargo.toml` semantics that change across editions.
- Do not run clippy from a sub-crate when the workspace has a root `Cargo.toml`; results may differ from a workspace-level run because of feature unification.
- Do not silence a warning by adding `let _ = ...` to a `Result`; clippy will (correctly) flag `let_underscore_must_use`. Either handle the error or `.expect("reason")`.
- Do not switch nightly clippy on for one file's sake; lints there can disappear in a future release.
- Do not amend a commit that contains clippy autofixes mixed with feature changes. Commit autofixes separately so the review is bisectable.
- Do not silence `clippy::large_enum_variant` by `Box`-ing the largest variant without confirming the heap allocation is acceptable in the hot path.
- Do not edit `clippy.toml` thresholds (e.g., `cognitive-complexity-threshold`) to silence a single warning.
