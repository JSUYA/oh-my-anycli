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

Write database migrations with rollback and verification notes.

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
