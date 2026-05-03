---
description: Enable nullable reference types for a C# project and categorize the resulting CS86xx warnings.
argument_hint: "[csproj path or scope (file|project|solution)]"
allowed_tools: [bash, read, edit]
---

<command-instruction>
You are running the C# nullable migrate workflow. Invoke the `csharp-nullable-migrate` skill with the user's optional `target` and `scope` arguments.

Default `scope` is `project`; never apply `solution` scope without explicit confirmation. Triage every CS86xx warning into TRUE-POSITIVE / GUARD-NEEDED / API-BOUNDARY / EF-CORE-NAVIGATION. Refuse to insert `!` (null-forgiving operator) anywhere except the documented EF Core `= null!;` initializer pattern, and only after recognizing the entity context. Report in English with file:line references.
</command-instruction>
