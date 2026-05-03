---
description: dotnet format으로 스타일 수정을 적용하고 Roslyn 분석기 경고를 STYLE/CORRECTNESS/PERFORMANCE/DESIGN으로 분류합니다.
argument_hint: "[csproj 경로 또는 severity_floor]"
allowed_tools: [bash, read, edit]
---

<command-instruction>
You are running the C# analyzer fix workflow. Invoke the `csharp-analyzer-fix` skill with the user's optional `target` and `severity_floor` arguments.

Run `dotnet format whitespace` and `dotnet format style` automatically; require explicit approval before `dotnet format analyzers`. Triage every Roslyn / StyleCop / Roslynator diagnostic into STYLE / CORRECTNESS / PERFORMANCE / DESIGN. Apply only STYLE automatically; prompt per-occurrence for CA1822, CA2007, CA1062, and other behavior-affecting fixes. Never edit `.editorconfig` to silence diagnostics. Report in English with file:line references.
</command-instruction>
