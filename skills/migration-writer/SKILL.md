---
name: migration-writer
description: Writes a database migration in the project's detected framework (Rails, Django, Alembic, Prisma, Knex, golang-migrate, Flyway, Liquibase). Always produces forward + reverse, includes safety notes for large tables, and prefers additive over destructive operations. Refuses if no framework is detected.
version: 1.0.0
when_to_use: User asks "/migration", "add a migration for X", "write a column-rename migration", or has just changed an ORM model and needs the corresponding schema change. Useful before creating PRs that touch persistent data.
inputs:
  - name: change_description
    description: One-line description of the schema change. Examples — "add `email_verified` boolean to users (default false)", "rename `users.fullname` to `users.full_name`", "drop unused `legacy_id` column from orders".
  - name: framework_hint
    description: Optional override for framework detection (e.g. "alembic", "prisma"). Use only when auto-detection would pick the wrong one (e.g. monorepo with two ORMs).
required_tools: [bash, read, edit]
---

# Migration Writer Skill

## Goal

Write database migrations in the detected framework with rollback, safety notes,
and verification steps.

## Workflow

1. Detect the migration framework from existing files and commands:
   Rails, Django, Alembic, Prisma, Knex, golang-migrate, Flyway, Liquibase, or
   project-specific scripts.
2. Read recent neighboring migrations and mirror naming, transaction style,
   timestamps, SQL dialect, helpers, and rollback conventions.
3. Classify the requested change:
   - ADDITIVE: new nullable column, new table, new index;
   - NEEDS-CARE: default/backfill, unique constraint, FK on existing data;
   - DESTRUCTIVE: drop/rename/type narrowing/data rewrite.
4. Prefer expand/contract patterns for risky changes:
   add new shape -> backfill safely -> dual-read/write if needed -> remove old
   shape in a later migration.
5. Write forward and reverse paths when the framework supports it. If rollback
   is impossible or unsafe, state why in the migration comment or output.
6. Include verification commands using the project's existing migration tooling.

## Output Format

```markdown
### Migration created
- `db/migrate/20260511093000_add_email_verified_to_users.rb`

Risk: NEEDS-CARE - backfill required before `NOT NULL`.

Verification:
- `bin/rails db:migrate`
- `bin/rails db:rollback STEP=1`
```

## Guardrails

- Do not invent a migration framework if none exists.
- Do not run migrations against a real database without explicit confirmation.
- Do not combine destructive schema changes with data backfills unless the
  existing project already does that safely.
- Do not omit rollback discussion.
