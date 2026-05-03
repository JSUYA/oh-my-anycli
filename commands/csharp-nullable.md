---
description: C# 프로젝트에 nullable reference types를 활성화하고 발생한 CS86xx 경고를 분류합니다.
argument_hint: "[csproj 경로 또는 scope (file|project|solution)]"
allowed_tools: [bash, read, edit]
---

<command-instruction>
You are running the C# nullable migrate workflow. Invoke the `csharp-nullable-migrate` skill with the user's optional `target` and `scope` arguments.

Default `scope` is `project`; never apply `solution` scope without explicit confirmation. Triage every CS86xx warning into TRUE-POSITIVE / GUARD-NEEDED / API-BOUNDARY / EF-CORE-NAVIGATION. Refuse to insert `!` (null-forgiving operator) anywhere except the documented EF Core `= null!;` initializer pattern, and only after recognizing the entity context. Report in English with file:line references.
</command-instruction>
