---
name: sql-explain-reader
description: Interprets a SQL EXPLAIN or EXPLAIN ANALYZE output (Postgres / MySQL / SQLite) in plain Korean — scan types, why an index might help, sequential vs index scan trade-offs, sort/hash join cost. Read-only; never connects to a database.
version: 1.0.0
when_to_use: Use this when the user asks for sql explain reader support.
inputs:
  - name: explain_output
    description: The raw EXPLAIN / EXPLAIN ANALYZE output. Required. Pass the full text including the leading "QUERY PLAN" header if Postgres.
  - name: query_text
    description: Optional — the original SQL statement. Improves index suggestions because the skill can see WHERE/JOIN clauses.
  - name: engine_hint
    description: Optional — "postgres", "mysql", or "sqlite". If absent the skill auto-detects from the output's syntax.
required_tools: [bash, read]
---

# Sql Explain Reader Skill

## Goal

Explain SQL execution plans and tuning opportunities.

## Workflow

1. Read the user's request and identify the target files or project area.
2. Gather only the local context needed for the task.
3. Apply the skill's domain checklist with scoped, evidence-backed reasoning.
4. Report findings, edits, or recommendations in English.
5. Include verification steps or residual risks when relevant.

## Output

Use concise English. Preserve code identifiers, file paths, command names, and API names exactly as they appear in the project.

## Guardrails

- Do not invent facts, test results, issue links, or external references.
- Do not make unrelated edits.
- Do not perform destructive actions without explicit user approval.
- Keep examples generic and free of sensitive or organization-specific data.
