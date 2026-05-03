---
name: rust-unsafe-review
description: Locates every unsafe block in the changed Rust files, audits each against a soundness checklist (SAFETY comments, pointer validity, lifetimes, FFI, transmute), and refuses to suggest removing the unsafe keyword unless a safe replacement is obviously sound.
version: 1.0.0
when_to_use: User invokes "/rust-unsafe", asks to "audit unsafe blocks", or wants a soundness review before merging FFI/perf code.
inputs:
  - name: target
    description: Optional path. Defaults to the Rust files changed on the current git branch.
required_tools: [bash, read]
---

# Rust Unsafe Review Skill

## Goal

For every `unsafe { ... }` block, `unsafe fn`, `unsafe trait`, and `unsafe impl` in the touched files, audit against a fixed checklist and report each as SAFETY-COMMENT-MISSING, NEEDS-REVIEW, or SOUND-WITH-NOTES. This skill never edits unsafe code; it only reports.

## Inputs

- `target`: optional path; default is changed Rust files on the branch.

## Steps

1. Resolve target files.
   ```bash
   git diff --name-only --diff-filter=ACMRT \
     $(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main) \
     -- '*.rs'
   ```

2. Find every unsafe construct in those files.
   ```bash
   # Block: `unsafe {`
   grep -nE '\bunsafe\s*\{' <files>
   # Function declaration: `unsafe fn` or `pub unsafe fn`
   grep -nE '\b(pub(\s*\([^)]*\))?\s+)?unsafe\s+fn\b' <files>
   # Impl: `unsafe impl ... for ...`
   grep -nE '\bunsafe\s+impl\b' <files>
   # Trait: `unsafe trait`
   grep -nE '\bunsafe\s+trait\b' <files>
   # Attribute on extern blocks: `unsafe extern "C" {`
   grep -nE '\bunsafe\s+extern\b' <files>
   ```

3. For each finding, read 30 lines of context (10 above, 20 within/below). Apply the checklist:

   ### A. SAFETY comment present
   Every unsafe block should be immediately preceded by a `// SAFETY: ...` comment that justifies why the operation is sound. The Rust standard library and most reviewed crates use this convention. Missing → **SAFETY-COMMENT-MISSING**, regardless of actual soundness. The comment should answer: which invariants are required, why are they upheld here.

   ### B. Pointer dereferences (`*ptr`, `ptr.read()`, `ptr.write()`)
   Verify (or flag for review):
   - `ptr` is non-null (preferably `NonNull<T>` in the type or guarded with a check).
   - `ptr` is properly aligned for `T`.
   - `ptr` points to a valid `T` (initialized, of correct provenance).
   - Bounds: for arrays/slices, the index is within range.
   - Aliasing: no overlapping `&mut` exists at the same time.

   ### C. Slice / pointer-arith creation (`slice::from_raw_parts(ptr, len)`)
   - `ptr` is valid for reads of `len * size_of::<T>()` bytes.
   - All `len` elements are initialized.
   - The lifetime of the returned slice does not outlive the underlying allocation.
   - `len * size_of::<T>()` does not overflow `isize::MAX`.

   ### D. `mem::transmute`
   - Source and destination types have identical size AND identical validity invariants.
   - Prefer `as` casts, `from_le_bytes`/`to_le_bytes`, or `Pod`-style traits (`bytemuck::cast`) when possible.
   - Transmuting between references requires lifetime equality.
   - Transmuting `&T` to `&mut T` is undefined behavior even if `T == T`.

   ### E. FFI boundaries (`extern "C" { fn ... }`, `extern "C" fn`)
   - Function signature matches the C declaration exactly: types, calling convention, ABI.
   - Pointer arguments document ownership (callee borrows? takes ownership? returns owning pointer?).
   - String args: `*const c_char` consumers must accept NUL-terminated; producers must guarantee NUL termination.
   - Callbacks: use `extern "C" fn` (not closures) for callback function pointers.
   - Errors are checked (`errno`, return code) before using output values.
   - On Rust 2024 edition: `unsafe extern` blocks need every item in the block to be `unsafe`-callable.

   ### F. Lifetime laundering
   - `transmute::<&'a T, &'b T>` to extend lifetime is almost always unsound.
   - `mem::transmute` of references where one lifetime is `'static` is suspect.
   - Self-referential structs hidden behind raw pointers: prefer `Pin` + `PhantomPinned` or established crates.

   ### G. `Send` / `Sync` impls (`unsafe impl Send for ...`, `unsafe impl Sync for ...`)
   - The type's interior must actually be safe to send across threads / share across threads.
   - Raw pointer wrappers require explicit reasoning about thread access patterns.

   ### H. `from_utf8_unchecked` and friends
   - Caller must guarantee the byte slice is valid UTF-8; require either an upstream validator or a comment proving the source's invariants.

   ### I. Inline assembly (`asm!`, `global_asm!`)
   - Constraints accurately describe register/memory clobbers.
   - `options(...)` correctly reflect side effects (`nomem`, `readonly`, `preserves_flags`, etc.).

4. Classify each finding:
   - **SAFETY-COMMENT-MISSING**: no `// SAFETY:` immediately preceding the block (or function-level docs for `unsafe fn`).
   - **NEEDS-REVIEW**: a checklist item cannot be confirmed from the surrounding code; describe the specific concern.
   - **SOUND-WITH-NOTES**: checklist appears satisfied; record any non-obvious invariants in the report.

5. Suggest a safe replacement only when one is unambiguously available. Examples that ARE acceptable to suggest:
   - `unsafe { v.get_unchecked(i) }` → `v[i]` if bounds are not actually a hot path.
   - `transmute::<u32, f32>` → `f32::from_bits`.
   - `slice::from_raw_parts(ptr, len)` for a `Vec` source → `&v[..]` if `v` is in scope.
   - `from_utf8_unchecked` immediately after a UTF-8 validation → `str::from_utf8(...).unwrap()` or `?`.
   - `unsafe { libc::malloc(n) }` for typed allocation → `Box::<T>::new_uninit()` / `Vec::with_capacity`.

   For everything else, do not suggest removing `unsafe`.

## Output format

```markdown
### rust-unsafe-review report

Files scanned: 4 (changed on branch)
Unsafe items found: 7 (3 blocks, 2 unsafe fn, 1 unsafe impl, 1 extern block)
Classification: SAFETY-COMMENT-MISSING 3, NEEDS-REVIEW 3, SOUND-WITH-NOTES 1

#### crates/ffi/src/lib.rs

L42-L49 — unsafe block — SAFETY-COMMENT-MISSING
  Operation: slice::from_raw_parts(buf, len)
  Concerns: no SAFETY comment; cannot verify `buf` validity from this scope.
  Suggested SAFETY comment: "// SAFETY: `buf` originates from FooBuffer::ptr(), which is non-null and points to `len` initialized bytes for the lifetime of `self`."

L88 — unsafe fn `read_raw` — NEEDS-REVIEW
  Function is `pub unsafe fn read_raw(ptr: *const u8, len: usize) -> &'static [u8]`.
  Concerns:
    - returns &'static lifetime from a raw pointer with no static guarantee
    - caller cannot reasonably uphold this invariant
  Recommendation: change return type to `&'a [u8]` with explicit lifetime tied to `ptr`'s provenance.

L120-L123 — transmute — NEEDS-REVIEW
  `mem::transmute::<u32, f32>(bits)` — prefer `f32::from_bits(bits)` (safe, identical semantics).
  Recommendation: replace with the safe equivalent.

L155 — unsafe impl Send — SOUND-WITH-NOTES
  `unsafe impl Send for FooHandle {}` — handle is an opaque integer with no thread-affinity per FFI docs (libfoo §3.2).
  Note: confirm libfoo's threading guarantees in your binding's documentation.
```

## Anti-patterns

- Do not propose deleting `unsafe` to make the function safe. The keyword is the contract; removing it does not change the underlying operation.
- Do not autofix `unsafe` code. Every change here needs human eyes; this skill reports.
- Do not assume that "the test passed" means "the unsafe is sound". Undefined behavior often appears as correct behavior in tests and breaks in production.
- Do not suggest `Miri` runs as part of this skill — Miri requires nightly, is slow, and is best a separate step the user opts into.
- Do not silently accept an `unsafe impl Send for T {}` where `T` contains a raw pointer; raw pointers are `!Send` by default for a reason.
- Do not flag `unsafe { core::hint::unreachable_unchecked() }` as automatically wrong; it is sometimes correct in performance-critical match arms, but always require a SAFETY comment proving the unreachability.
- Do not recommend replacing `unsafe { std::ptr::copy_nonoverlapping(...) }` with safe slice copies if the source/dest are not already slices; the conversion may add bounds checks the perf path avoided intentionally.
- Do not require a SAFETY comment on calls to `unsafe fn` inside an `unsafe fn` body — the function's safety doc covers it. Still flag if the doc itself is missing.
- Do not propose changing `from_utf8_unchecked` to `from_utf8` in a tight loop without measuring; the validation cost is per-byte.
- Do not "improve" raw FFI signatures by adding lifetimes the C declaration does not have; you may introduce unsoundness.
- Do not assume `repr(C)` types are interchangeable with C structs of the same field names; field ordering and padding rules differ subtly across platforms.
- Do not approve transmutes between `Vec<T>` and `Vec<U>` even when `T` and `U` have the same size; layout of `Vec` is not guaranteed to be transparent.
- Do not declare an `unsafe impl Sync for T` based on "the field is `Mutex`-protected" without confirming all methods actually go through the mutex.
- Do not approve `extern "C" fn` callbacks without `#[no_mangle]` or `#[unsafe(no_mangle)]` (Rust 2024) when the callback is registered with C — the symbol may be stripped.
- Do not delete a `// SAFETY:` comment because it is "obvious"; reviewers downstream will not have the original author's context.
