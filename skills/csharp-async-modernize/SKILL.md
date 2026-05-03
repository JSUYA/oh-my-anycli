---
name: csharp-async-modernize
description: Detects sync-over-async deadlock risks (.Result, .Wait, GetAwaiter().GetResult()) and converts to async/await with Async suffix, CancellationToken propagation, and ConfigureAwait policy chosen by project type, while warning about async void event-handler conversions.
version: 1.0.0
when_to_use: User invokes "/csharp-async", asks to "convert sync to async", or wants to remove sync-over-async patterns before review.
inputs:
  - name: target
    description: Optional path. Defaults to .cs files changed on the current branch.
  - name: project_type
    description: library | aspnetcore | wpf | winforms | console. Defaults to detection from csproj.
required_tools: [bash, read, edit]
---

# C# Async Modernize Skill

## Goal

Replace sync-over-async anti-patterns with proper `async`/`await`, propagate `CancellationToken` where the call chain supports it, choose a `ConfigureAwait` policy based on project type, and protect the user from accidentally converting event handlers (which would become `async void`).

## Inputs

- `target`: file/directory; default is changed `.cs` files.
- `project_type`: explicit override; otherwise detect:
  - `library` if csproj output is a class library AND no `Sdk="Microsoft.NET.Sdk.Web"`.
  - `aspnetcore` if `Sdk="Microsoft.NET.Sdk.Web"` or references `Microsoft.AspNetCore.*`.
  - `wpf` if `<UseWPF>true</UseWPF>`.
  - `winforms` if `<UseWindowsForms>true</UseWindowsForms>`.
  - `console` otherwise.

## Steps

1. Detect project type per containing csproj.
   ```bash
   grep -nE 'Sdk=|UseWPF|UseWindowsForms|TargetFramework|<OutputType' <project>.csproj
   ```

2. Resolve target files (changed on branch).
   ```bash
   git diff --name-only --diff-filter=ACMRT \
     $(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main) \
     -- '*.cs'
   ```

3. Find sync-over-async patterns.
   ```bash
   grep -nE '\.Result\b|\.Wait\(\)|\.GetAwaiter\(\)\.GetResult\(\)' <files>
   ```
   For each match, read 20 lines of context to confirm. False positives include `Process.Start().Result` (no — `Process.Start` is sync), `Task.WaitAll(...)` on sync entry points (legitimate at top level), and properties named `Result` on non-Task types.

4. Find candidate methods to convert.
   - Methods that internally call sync-over-async.
   - Methods that call other async methods using `.Result` / `.Wait()`.
   - Methods that return `void` and `await` something — `async void` candidates needing extra care.
   - Methods that take a `CancellationToken` parameter but call cancellable APIs without forwarding it.

5. Apply the conversion checklist for each candidate method.

   ### A. Method signature
   - Add `async` to the method.
   - Change return type:
     - `void` → `Task` (preferred) or `void` only if it is an event handler.
     - `T` → `Task<T>`.
     - `IEnumerable<T>` produced by `yield return` plus async ops → `IAsyncEnumerable<T>` (.NET Core 3.0+).
   - Add `Async` suffix to the method name (TAP convention). Update all call sites in the changed files. Out-of-scope call sites: list as follow-up work, do not touch.
   - For interface or virtual methods, the override/implementation must match. Flag if the user controls only part of the hierarchy.

   ### B. Body conversion
   - `task.Result` → `await task`.
   - `task.Wait()` → `await task`.
   - `task.GetAwaiter().GetResult()` → `await task`.
   - `Thread.Sleep(ms)` → `await Task.Delay(ms, cancellationToken)`.
   - `WaitHandle.WaitOne(timeout)` → no async equivalent; flag, do not convert.
   - `lock (obj) { await ... }` is a compile error; flag for user to switch to `SemaphoreSlim.WaitAsync`.

   ### C. CancellationToken propagation
   - If the enclosing method or class accepts a `CancellationToken`, forward it into every call that accepts one.
   - If not, add a `CancellationToken cancellationToken = default` parameter to the method (NEEDS-REVIEW — public-API change).
   - For ASP.NET Core: controller actions can accept `CancellationToken` directly; the framework binds the request-aborted token.

   ### D. ConfigureAwait policy
   - `library` → add `.ConfigureAwait(false)` to every `await` (guards consumer-side sync contexts; reduces deadlock risk).
   - `aspnetcore` → leave default (no SynchronizationContext on the request thread; `ConfigureAwait(false)` adds noise without benefit).
   - `wpf` / `winforms` → leave default in UI-touching methods (the continuation must run on the UI thread); use `ConfigureAwait(false)` only inside helpers that never touch UI.
   - `console` → leave default; no SynchronizationContext is captured anyway.

6. Event handler caution.
   - If a candidate method matches `void OnXxx(object sender, ...EventArgs e)` or is wired up via `+=`, do not convert without warning.
   - If the user approves: `async void` is the only legal form, and its exceptions cannot be caught by the caller. Wrap the body in `try { await ... } catch (Exception ex) { /* log, don't rethrow */ }`. Surface this rule in the report.

7. Detect newly-async methods that need plumbing further up.
   - Callers that became sync-over-async by virtue of calling a now-async method must be converted in turn. Walk up one level of callers in the changed files and flag.
   - Out-of-scope callers (in files not changed on the branch) are listed as follow-up work; do not edit them in this pass.

## Methods that should not be converted

- Constructors — there is no `async` constructor. Use a static async factory method instead.
- Property getters/setters — properties are not awaitable; if you need async, convert to a method.
- Override methods where the base class is sync — overriding a sync virtual with async changes the contract.
- Iterator methods (`yield return`) — convert to `IAsyncEnumerable<T>` instead, but only if the project targets .NET Core 3.0+ / .NET Standard 2.1+.
- Operators — `operator +`, etc. cannot be async.

8. After edits, run an analyzer pass to catch what got missed:
   ```bash
   dotnet build -clp:NoSummary -v:quiet 2>&1 | grep -E 'CS4014|CS1998|VSTHRD|CA2007'
   ```
   - **CS4014**: Awaitable not awaited.
   - **CS1998**: Async method lacks await operators.
   - **VSTHRD100/101/103**: Microsoft.VisualStudio.Threading analyzer warnings.
   - **CA2007**: Consider calling ConfigureAwait — only relevant in libraries.

## Output format

```markdown
### csharp-async-modernize report

Project type: library (no UI; will apply ConfigureAwait(false))
Files scanned: 4

#### MyLib/Services/HttpClient.cs (6 candidates)
Conversions (4):
  - L42 `string GetUserName(int id)` → `Task<string> GetUserNameAsync(int id, CancellationToken ct = default)`
       body: `client.GetStringAsync(url).Result` → `await client.GetStringAsync(url, ct).ConfigureAwait(false)`
       call sites in this file (3) updated
       call sites outside changed scope: 2 (UserController.GetById, ReportBuilder.Build) — NEEDS-REVIEW
  - L88 `void Refresh()` → `Task RefreshAsync(CancellationToken ct = default)`
       body: `task.Wait()` → `await task.ConfigureAwait(false)`

Event handler (1, NOT converted, requires user approval):
  - L155 `void OnButtonClick(object sender, EventArgs e)` calls `_svc.GetUserName(id)`.
       Conversion would produce `async void OnButtonClick(...)`. Risks: exceptions become unobservable;
       multiple invocations may overlap. Confirm and wrap body in try/catch with logging.

Cannot convert (1):
  - L210 `var resp = client.SomeOp().GetAwaiter().GetResult();` inside a `lock(_sync) { ... }` block.
       `await` inside `lock` is illegal. Switch to SemaphoreSlim.

#### MyLib/Workers/Pump.cs (...)
...
```

## Anti-patterns

- Do not convert event handlers to `async Task` — that breaks the event delegate signature. They must remain `async void`, and the user must accept the unhandled-exception risk.
- Do not add `ConfigureAwait(false)` in ASP.NET Core code; there is no SynchronizationContext to capture, and the noise hides real ConfigureAwait usage in libraries.
- Do not mix `Result` removal with unrelated refactors. The conversion alone is risky enough; bundle it with nothing else.
- Do not convert constructors to async by adding "Async factory methods" automatically. That is a design change requiring user approval.
- Do not silence CS1998 (async method without await) by removing the `async` keyword if the method is in an interface contract — the contract dictates the signature.
- Do not convert `Main` to `async Task Main` in a project targeting .NET Framework 4.x without confirming compiler support (works only in .NET Core / .NET 5+).
- Do not assume that `task.Wait(timeout)` is safe to convert to `await Task.WhenAny(task, Task.Delay(timeout))` without preserving the timeout's exception semantics.
- Do not add `CancellationToken` parameters to interface methods you do not own; that is an API break for downstream implementers.
- Do not propagate `CancellationToken.None` "for safety" into APIs that already accept a real token; that disables cancellation downstream.
- Do not convert `Parallel.ForEach` to `Task.WhenAll(items.Select(async ...))` blindly — `Parallel.ForEach` has work-stealing scheduling characteristics the async version does not.
- Do not convert `lock { await }` by switching to `Monitor.Enter`/`Monitor.Exit` around the await — that has the same problem (the lock is reentered on a possibly different thread).
- Do not delete `.Result` access on `Task<T>` properties that the user explicitly wants synchronously (top-of-`Main` initialization, for example). Convert to `Task.Run(...).GetAwaiter().GetResult()` only at the very top, never inside library code.
- Do not assume `IAsyncEnumerable<T>` is available on the project's target framework; it requires .NET Core 3.0+ or .NET Standard 2.1+.
- Do not rename a public method by adding `Async` without bumping the package version and noting the API break.
- Do not add ConfigureAwait(false) to `await using` declarations without verifying the project uses `Microsoft.Bcl.AsyncInterfaces` or .NET Core 3.0+; older targets do not support `IAsyncDisposable`.
