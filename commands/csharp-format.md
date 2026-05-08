---
description: "Apply style fixes with dotnet format and categorize Roslyn analyzer warnings as STYLE, CORRECTNESS, PERFORMANCE, or DESIGN."
argument_hint: "[csproj path or severity_floor]"
allowed_tools: [bash, read, edit]
routes_to_skill: csharp-analyzer-fix
---

<command-instruction>
Run the `csharp-analyzer-fix` skill workflow on the user's request.

When to use: User invokes "/csharp-format", asks to "run dotnet format", or wants Roslyn analyzer triage before opening a PR.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`csharp-analyzer-fix`) is not installed in this environment, follow the
workflow described in skills/csharp-analyzer-fix/SKILL.md.
</command-instruction>
