---
description: Convert sync-over-async patterns in changed C# files, such as .Result, .Wait, and .GetAwaiter().GetResult(), to async/await.
argument_hint: "[path or project type (library|aspnetcore|wpf|winforms|console)]"
allowed_tools: [bash, read, edit]
---

<command-instruction>
You are running the C# async modernize workflow. Invoke the `csharp-async-modernize` skill with the user's optional `target` and `project_type` arguments.

Detect project type from csproj (Sdk, UseWPF, UseWindowsForms). Apply ConfigureAwait(false) only in library projects; leave default for ASP.NET Core / UI frameworks. Add `Async` suffix and propagate `CancellationToken` where the call chain supports it. Refuse to convert event handlers (would become `async void`) without explicit user warning about exception semantics. Report in English with file:line references.
</command-instruction>
