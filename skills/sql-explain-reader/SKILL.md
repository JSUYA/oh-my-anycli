---
name: sql-explain-reader
description: Interprets a SQL EXPLAIN or EXPLAIN ANALYZE output for Postgres, MySQL, or SQLite in plain English, covering scan types, index trade-offs, sort/hash join cost, and related performance clues. Read-only; never connects to a database.
version: 1.0.0
when_to_use: User pastes SQL EXPLAIN / EXPLAIN ANALYZE output, asks why a query is slow, or wants help interpreting a Postgres, MySQL, or SQLite query plan. Read-only; never connects to a database.
inputs:
  - name: explain_output
    description: The raw EXPLAIN / EXPLAIN ANALYZE output. Required. Pass the full text including the leading "QUERY PLAN" header if Postgres.
  - name: query_text
    description: Optional — the original SQL statement. Improves index suggestions because the skill can see WHERE/JOIN clauses.
  - name: engine_hint
    description: Optional — "postgres", "mysql", or "sqlite". If absent the skill auto-detects from the output's syntax.
required_tools: [bash, read]
---

# SQL Explain Reader Skill

## Goal

Interpret a pasted SQL execution plan and suggest query or index changes based
only on the plan text and optional query text.

## Workflow

1. Identify the engine from the plan syntax or `engine_hint`: Postgres, MySQL,
   or SQLite. If unclear, state assumptions.
2. Preserve the user's plan text. Do not connect to a database.
3. Read plans in engine order:
   - Postgres: top node is final operation; read child nodes for access paths,
     compare estimated vs actual rows, loops, buffers, sort spill, hash batches;
   - MySQL: inspect `type`, `possible_keys`, `key`, `rows`, `filtered`, `Extra`;
   - SQLite: inspect scan/search operations and whether indexes are used.
4. Look for common signals:
   sequential scan on large table, nested loop with high outer rows, sort/hash
   spill, row estimate mismatch, `Rows Removed by Filter`, missing composite
   index order, non-sargable predicates, OR conditions, functions on indexed
   columns, and over-fetching.
5. Suggest the smallest change: query rewrite, index candidate, stats refresh,
   or schema adjustment. Include trade-offs for write-heavy tables.
6. Ask for the original query or `EXPLAIN ANALYZE` only when the pasted plan is
   insufficient for a claim.

## Output Format

```markdown
### Plan reading
Engine: Postgres

#### Main cost driver
- `Nested Loop` executes inner index lookup 120k times; actual rows are far
  above estimate.

#### Suggestions
1. Add candidate index: `CREATE INDEX ...` (helps WHERE + JOIN order).
2. Run `ANALYZE <table>` if estimates are stale.

#### Need to confirm
- original SQL text, because predicate order and selected columns are unknown.
```

## Guardrails

- Do not connect to a database or run DDL.
- Do not recommend indexes without naming the query predicate/order they serve.
- Do not ignore write-amplification or table size trade-offs.
- Do not claim runtime improvement without measurements.
