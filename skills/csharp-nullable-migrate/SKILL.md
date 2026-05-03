---
name: csharp-nullable-migrate
description: Enables nullable reference types in the touched csproj scope and triages the resulting CS86xx warnings into TRUE-POSITIVE, GUARD-NEEDED, API-BOUNDARY, and EF-CORE-NAVIGATION categories, refusing to add the null-forgiving operator (!) without explicit per-occurrence approval.
version: 1.0.0
when_to_use: User invokes "/csharp-nullable", asks to "enable NRT", or wants to migrate a project to nullable annotations safely.
inputs:
  - name: target
    description: Optional .csproj path or directory. Defaults to projects whose source files changed on the current branch.
  - name: scope
    description: file | project | solution. Defaults to project. The skill never changes solution-wide settings without explicit confirmation.
required_tools: [bash, read, edit]
---

# C# Nullable Migrate Skill

## Goal

Turn on nullable reference types (NRT) for one project at a time, classify the resulting `CS86xx` warnings, and apply minimal annotations that match each cause. The null-forgiving suffix `!` is never inserted automatically.

## Inputs

- `target`: a `.csproj`, a directory, or empty (project containing changed files).
- `scope`: `file` (use `#nullable enable` pragma), `project` (set `<Nullable>enable</Nullable>` in csproj), or `solution` (touch every csproj — requires explicit confirmation).

## Steps

1. Detect the current nullable setting in each candidate csproj.
   ```bash
   grep -nE '<Nullable>' <project>.csproj
   grep -rnE '#nullable\s+(enable|disable|restore)' --include='*.cs' <project-dir>
   ```
   States: `disable` (default for older projects), `warnings`, `annotations`, `enable`. If already `enable` project-wide, scope to files that have `#nullable disable`.

2. Detect target framework — annotation behavior differs.
   ```bash
   grep -nE '<TargetFramework' <project>.csproj
   ```
   - .NET Framework 4.x: NRT is supported but lacks attributes like `[NotNullWhen]`; treat as legacy.
   - .NET Standard 2.0: same caveat; consider polyfilling annotations.
   - .NET 6+: full annotation support including generic constraint `T?` where `T : notnull`.

3. Apply the chosen scope.
   - `file`: insert `#nullable enable` at the top of the file (after `using` directives is also acceptable; pick one and be consistent).
   - `project`: add `<Nullable>enable</Nullable>` inside an existing `<PropertyGroup>` of the csproj. Do not create a new PropertyGroup if one exists.
   - `solution`: ask user to confirm; iterate per project.

4. Build to gather diagnostics. Capture warnings only on touched files.
   ```bash
   dotnet build <project>.csproj -c Debug -clp:NoSummary -v:quiet \
     /p:TreatWarningsAsErrors=false /p:WarningsNotAsErrors='' \
     2>&1 | grep -E ': warning CS86' | sort -u
   ```
   The diagnostics produced by NRT enablement are roughly:
   - **CS8600**: Converting null literal or possible null value to non-nullable type.
   - **CS8601**: Possible null reference assignment.
   - **CS8602**: Dereference of a possibly null reference.
   - **CS8603**: Possible null reference return.
   - **CS8604**: Possible null reference argument.
   - **CS8618**: Non-nullable field/property must contain a non-null value when exiting constructor.
   - **CS8625**: Cannot convert null literal to non-nullable reference type.
   - **CS8629**: Nullable value type may be null.
   - **CS8714**: The type cannot be used as type parameter — nullability of type argument doesn't match constraint.

5. Triage every warning into one of:

   ### A. TRUE-POSITIVE
   The code has a real null path.
   - Action: fix the null path. Either ensure non-null at the source, or accept null and propagate via `?.`, `??`, or pattern matching.
   - Example: `s.Length` where `s` may be null → guard `if (s is null) return 0; return s.Length;` or `s?.Length ?? 0`.

   ### B. GUARD-NEEDED
   A field, parameter, or return value is correctly nullable but lacks the `?` annotation.
   - Action: change the type to `string?`, `Foo?`, etc. Cascading warnings may appear in callers — address as their own findings.
   - Auto-applicable when the change is internal to a single file. Cross-file ripple → flag.

   ### C. API-BOUNDARY
   The warning is on a `public` or `protected` member; changing the annotation is part of the public contract.
   - Action: deliberate decision required. Options:
     1. Accept the new nullable annotation (semver minor or major depending on consumer impact).
     2. Add a runtime null check at the boundary and keep the type non-nullable (`ArgumentNullException.ThrowIfNull(value)`).
     3. Preserve current behavior with `[AllowNull]`, `[DisallowNull]`, `[MaybeNull]`, `[NotNull]`, `[NotNullWhen(true)]`, `[MemberNotNull(...)]`.
   - Never silently change a public API; surface the choice to the user.

   ### D. EF-CORE-NAVIGATION
   Entity Framework Core navigation and required-relationship properties commonly trigger CS8618 even when the runtime never sees null (EF materializes them).
   - Action options, project-style dependent:
     1. `public Order Order { get; set; } = null!;` — common EF Core pattern; the `null!` is the recommended "trust me, EF will fill this" form.
     2. Backing field with private setter and `[MemberNotNull(nameof(Order))]` on a "load" method.
     3. Switch to required reference properties: `public required Order Order { get; set; }` (.NET 7+).
   - The `null!` initializer is the only place this skill is allowed to add `!` automatically, and only when the field is part of an EF Core entity (look for `DbSet<Foo>` references or `[Table]`/`[Key]` attributes).

6. Refusal rule: never insert `!` (null-forgiving) anywhere except option D.1 above. If a warning seems to require `!` to silence, escalate to the user with: "this requires `!` at <file>:<line>; please confirm because this suppresses a real warning."

7. Re-run the build after edits per file; keep a running tally of remaining warnings.

## Annotation reference

The nullable annotation surface is small but easy to misuse. Quick reference:

- `T?` on a parameter or return type: the value may be null; callers must check.
- `T` on a parameter or return type: the value is not null; callers may rely on this.
- `[NotNull]` parameter: caller passes possibly null; method guarantees non-null thereafter (typically by throwing).
- `[MaybeNull]` return: declared `T` but may legitimately be null in some cases (e.g., generic with `default`).
- `[NotNullWhen(true)] out T x`: when the method returns true, `x` is non-null. The TryGet pattern.
- `[MemberNotNull(nameof(_field))]` on a method: after this method returns, `_field` is non-null. Tells the compiler that the method initializes the field.
- `[MemberNotNullWhen(true, nameof(_field))]` on a method returning bool: when true, `_field` is non-null.
- `[DisallowNull]` on a property setter: even though the type is `T?`, callers may not assign null.
- `[AllowNull]` on a property setter: even though the type is `T`, callers may assign null (the setter handles it).

These attributes live in `System.Diagnostics.CodeAnalysis`. On .NET Standard 2.0 / .NET Framework 4.x they are not in the runtime; either polyfill (declare them yourself in the project's namespace) or upgrade the target.

## Output format

```markdown
### csharp-nullable-migrate report

Scope applied: project (added <Nullable>enable</Nullable> to MyApp.csproj:14)
Target framework: net8.0
Build warnings introduced: 47
Triage: TRUE-POSITIVE 12, GUARD-NEEDED 21, API-BOUNDARY 8, EF-CORE-NAVIGATION 6

#### MyApp/Services/UserService.cs (9 warnings)
TRUE-POSITIVE (3):
  - L42 CS8602 Dereference of `user.Email` (user resolved from FindAsync, may be null)
    Fix: guard with `if (user is null) return NotFound();`
  - L88 CS8604 Argument `name` may be null in call to `Slugify(string)`
    Fix: validate `name` at L80 entry.
GUARD-NEEDED (4):
  - L17 field `_cache` is initialized lazily → `ConcurrentDictionary<string, User>?`
  - L33 param `prefix` should be `string?` (callers pass null in 2 places)
  - ...
API-BOUNDARY (2):
  - L120 public method `GetUser(string id)` — return type Task<User> (warning CS8603 because of catch-and-rethrow pattern). Choose: change to `Task<User?>` (consumer impact 7 call sites) OR add explicit `throw` with detail at the catch site.

#### MyApp/Data/Order.cs (4 warnings)
EF-CORE-NAVIGATION (4):
  - L8  public Customer Customer { get; set; } → suggest: `= null!;` (EF entity)
  - L9  public ICollection<OrderItem> Items { get; set; } → suggest: `= new List<OrderItem>();`
  - ...
```

## Anti-patterns

- Do not enable `<Nullable>enable</Nullable>` solution-wide in one commit on a large project. Migrate per project, ideally per file with `#nullable enable`, so the diff stays reviewable.
- Do not add the `!` operator to silence warnings; that converts a compile-time signal into a runtime crash. The only exception is the EF Core `= null!` initializer pattern.
- Do not use `[NullableContext(0)]` / `[Nullable(0)]` directly — these are compiler-generated.
- Do not paper over CS8618 by changing fields to nullable; if the field is genuinely required, initialize it (constructor, field initializer, `required` keyword) rather than annotating away the safety guarantee.
- Do not mass-add `ArgumentNullException.ThrowIfNull` to silence CS8604 on internal helpers; internal callers should be teaching the type system, not enforcing at every boundary.
- Do not enable nullable in a project that consumes generated code (Entity Framework migrations, T4 templates, gRPC stubs) without regenerating those files first; the regenerated output may differ.
- Do not assume `[MaybeNullWhen]` etc. are available on .NET Framework 4.x without polyfill; check the target framework first.
- Do not "fix" CS8602 by wrapping every dereference in `?.`; if the value should never be null, fix the source. Runtime null → `null` cascade can hide bugs.
- Do not add `[NotNull]` on a parameter and then call `value!` inside the method; the attribute documents the contract but does not enforce it. Add a runtime check.
- Do not change `out` parameters to nullable casually; many legacy callers pattern-match `if (TryGet(out var x))` assuming `x` is non-null in the true branch — use `[NotNullWhen(true)]`.
- Do not enable nullable in test projects until the production code is clean; test fixtures often use `null!` heavily and the noise hides real findings.
- Do not silently turn off specific CS86xx codes via `<NoWarn>`; either fix them or document a project-wide exception with rationale.
- Do not migrate a project to nullable without first ensuring its build is otherwise clean; mixing pre-existing warnings with NRT warnings makes triage impossible.
- Do not change a public method's return type from `Foo` to `Foo?` without bumping the package version and noting the API break in release notes (the user owns release notes).
