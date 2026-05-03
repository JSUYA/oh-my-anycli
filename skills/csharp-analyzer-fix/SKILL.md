---
name: csharp-analyzer-fix
description: Runs dotnet format and triages Roslyn analyzer / .editorconfig diagnostics on the touched C# files, applies trivial style fixes automatically, and prompts before any behavior-affecting change (CA1822, CA2007, CA1062, etc.).
version: 1.0.0
when_to_use: User invokes "/csharp-format", asks to "run dotnet format", or wants Roslyn analyzer triage before opening a PR.
inputs:
  - name: target
    description: Optional .csproj or path. Defaults to the project that contains files changed on the current branch.
  - name: severity_floor
    description: info | suggestion | warning | error. Defaults to warning.
required_tools: [bash, read, edit]
---

# C# Analyzer Fix Skill

## Goal

Run `dotnet format` for whitespace/style on the changed files, then triage Roslyn analyzer (`Microsoft.CodeAnalysis.NetAnalyzers`, `StyleCop.Analyzers`, `Roslynator`, etc.) findings into STYLE / CORRECTNESS / PERFORMANCE / DESIGN buckets and apply only the trivial style fixes automatically.

## Inputs

- `target`: csproj or path; default is the project containing changed files.
- `severity_floor`: minimum diagnostic severity to surface; default `warning`.

## Steps

1. Detect tooling.
   ```bash
   dotnet --version
   dotnet format --version 2>/dev/null || true
   ```
   `dotnet format` ships with the .NET SDK 6+; for older SDKs it is a separate global tool. Do not install it from this skill — ask the user.

2. Detect editor config and analyzer packages.
   ```bash
   find . -maxdepth 4 -name '.editorconfig' -not -path '*/bin/*' -not -path '*/obj/*'
   grep -nE 'Microsoft\.CodeAnalysis\.NetAnalyzers|StyleCop\.Analyzers|Roslynator|SonarAnalyzer' --include='*.csproj' -r .
   ```
   Look at top-level `<EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>` and `<AnalysisMode>` (`Default`, `Recommended`, `All`, `Minimum`) — these control which analyzers run.

3. Resolve target files (changed on branch).
   ```bash
   git diff --name-only --diff-filter=ACMRT \
     $(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main) \
     -- '*.cs' '*.editorconfig' '*.csproj'
   ```

4. Run `dotnet format` on the changed files only. Three sub-modes exist; run them in order.
   ```bash
   # Whitespace only (extremely safe)
   dotnet format whitespace --include <changed-files> --verbosity minimal

   # Editor config style rules (safe; covers IDE0xxx)
   dotnet format style --include <changed-files> --verbosity minimal

   # Analyzer-driven (broader; includes CAxxxx, can be behavioral)
   dotnet format analyzers --include <changed-files> --severity warn --verbosity minimal --no-restore
   ```
   Capture each step's diff before moving on. Do not run the third step (`analyzers`) without explicit user approval after they see the first two diffs.

5. Run a build to surface any remaining analyzer diagnostics that the format tool did not auto-fix.
   ```bash
   dotnet build --no-incremental -clp:NoSummary -v:quiet \
     /p:TreatWarningsAsErrors=false 2>&1 \
     | grep -E ': (warning|info|error) (CA|CS|IDE|SA|RCS|S)[0-9]+'
   ```
   Filter to the touched files.

6. Triage every diagnostic into:

   ### A. STYLE (auto-applied by `dotnet format style`; report only)
   - `IDE0001`–`IDE0008`: simplify name, simplify member access, remove unused using.
   - `IDE0011`: add braces.
   - `IDE0040`: add accessibility modifier.
   - `IDE0044`: make field readonly.
   - `IDE0055`: fix formatting.
   - `IDE0060`: remove unused parameter (BEHAVIORAL — exclude from auto-apply if the parameter is part of a public signature).
   - `IDE0090`: simplify `new(...)`.
   - `SA1xxx`: StyleCop layout/spacing.

   ### B. CORRECTNESS (require user review)
   - `CA1062`: validate arguments of public methods. Behavioral: adds runtime checks. Prompt per occurrence.
   - `CA1816`: Dispose methods should call `SuppressFinalize`.
   - `CA1841`: prefer `Dictionary.Contains*` collections.
   - `CA2000`: dispose objects before losing scope.
   - `CA2007`: consider calling `ConfigureAwait` on awaited task. Library-only; see `csharp-async-modernize` skill for policy.
   - `CA2008`: do not create tasks without passing a TaskScheduler.
   - `CA2011`: avoid infinite recursion via setter that calls itself.
   - `CA2200`: rethrow to preserve stack details (`throw;` vs `throw ex;`).
   - `RCS1090`: call `ConfigureAwait`.

   ### C. PERFORMANCE (recommend; usually safe but verify)
   - `CA1822`: mark members as static (small behavioral change — invocation no longer requires instance; can break reflection/serializers).
   - `CA1825`: avoid zero-length array allocations (`new T[0]` → `Array.Empty<T>()`).
   - `CA1827`: do not use `Count()` / `LongCount()` when `Any()` can be used.
   - `CA1829`: use `Length` / `Count` property instead of `Count()` extension.
   - `CA1834`: use `StringBuilder.Append(char)` for single character.
   - `CA1841`: prefer `Dictionary.ContainsKey/Value`.
   - `CA1847`: use `String.Contains(char)` for single character.
   - `CA1848`: use logger source generator (large impact; flag).
   - `CA1854`: prefer `Dictionary.TryGetValue` over `ContainsKey + indexer`.

   ### D. DESIGN (rarely auto-fixable; advisory)
   - `CA1031`: do not catch general exception types.
   - `CA1051`: do not declare visible instance fields.
   - `CA1303`: do not pass literals as localized parameters.
   - `CA1305`: specify `IFormatProvider`.
   - `CA1707`: identifiers should not contain underscores.
   - `CA1716`: identifiers should not match keywords.
   - `CA1812`: avoid uninstantiated internal classes.
   - `CA1814`: prefer jagged arrays over multidimensional.

7. For STYLE diagnostics, the format tool already applied them. For CORRECTNESS/PERFORMANCE/DESIGN, generate a patch hunk per occurrence and present grouped per file. Apply only after explicit per-file user approval.

8. Special case: `// <auto-generated/>` files. Skip entirely. The format tool already does this if the standard preamble is present, but verify.

## Output format

```markdown
### csharp-analyzer-fix report

dotnet 8.0.300; analyzers: NetAnalyzers (Recommended), StyleCop
Files scanned: 6 (changed on branch)
Style fixes applied automatically: 23 across 4 files
Remaining diagnostics: 18 (CORRECTNESS 5, PERFORMANCE 8, DESIGN 5)

#### Auto-applied STYLE (4 files)
- MyApp/Services/Foo.cs: 12 fixes (IDE0005 unused using, IDE0040 accessibility, SA1208 using ordering)
- MyApp/Models/User.cs: 6 fixes (IDE0044 make readonly, IDE0090 simplify new)
- MyApp/Program.cs: 5 fixes (IDE0011 braces)
- MyApp/Data/AppDbContext.cs: 0

#### MyApp/Services/Foo.cs — Remaining (7)
CORRECTNESS (2):
  - L42 CA1062 public method `Process(string input)` does not validate `input` for null
       Suggested patch: add `ArgumentNullException.ThrowIfNull(input);` (BEHAVIORAL — adds runtime check)
  - L88 CA2200 `throw ex;` resets the stack — use `throw;`

PERFORMANCE (3):
  - L17 CA1825 `new int[0]` → `Array.Empty<int>()`
  - L66 CA1854 `if (_dict.ContainsKey(k)) return _dict[k];` → `if (_dict.TryGetValue(k, out var v)) return v;`
  - L120 CA1827 `.Where(x => x.IsValid).Count() > 0` → `.Any(x => x.IsValid)`

DESIGN (2):
  - L8  CA1031 `catch (Exception)` is too broad — list specific exceptions
  - L155 CA1305 `int.Parse(s)` → `int.Parse(s, CultureInfo.InvariantCulture)`

Apply CORRECTNESS+PERFORMANCE patches for MyApp/Services/Foo.cs? [y/N]
```

## Anti-patterns

- Do not run `dotnet format` on the whole solution as a side effect. Scope to the changed files; otherwise the diff buries the user's actual change.
- Do not enable `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>` to "encourage" cleanup — that is a project policy choice, not a fix.
- Do not silence diagnostics by editing `.editorconfig` to lower their severity. Either fix or accept; documenting "we don't enforce CAxxxx because Y" can go in the project's docs (the user owns docs).
- Do not auto-apply CA1062 (`ArgumentNullException.ThrowIfNull`) to internal helpers. The check costs allocations and can spam stack traces; only public APIs benefit.
- Do not auto-apply CA1822 (make static) to virtual methods, methods marked `[ImportingConstructor]`, EF Core entity methods, or methods called via reflection — making them static can break those frameworks.
- Do not run `dotnet format analyzers` without `--severity` set; the default surfaces every suggestion-level diagnostic and the diff becomes unreviewable.
- Do not add `// <auto-generated/>` to manually-written files to skip analyzer scrutiny.
- Do not paper over CA1707 (no underscores in identifiers) by renaming public APIs; that is an API break.
- Do not "fix" CA1031 by listing every framework exception type; the right fix is usually to let the exception propagate or to handle a small known set.
- Do not introduce `using Microsoft.Extensions.Logging` to apply CA1848 (logger source generator) if the project uses `Serilog`/`NLog` directly; the suggestion does not transfer.
- Do not auto-fix RCS analyzers (Roslynator) without confirming the project enabled them; some projects use only `RCS1xxx` selectively.
- Do not run `dotnet format` against generated SDKs or migration files; the tool may rewrite designer-managed regions.
- Do not assume `IDE0028` (use collection initializer) is safe in a generated context (e.g., test fixtures using AutoFixture); the resulting expression may not compile.
- Do not edit `.editorconfig` to widen rule scope as part of this skill; that affects every contributor.
- Do not assume `dotnet format style` and `dotnet format analyzers` are idempotent across SDK versions — pin the SDK in `global.json` if reproducibility matters (the user owns global.json).
