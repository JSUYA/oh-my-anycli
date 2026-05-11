---
name: todo-harvester
description: Finds and categorizes TODO/FIXME/HACK/XXX/NOTE comments across the repository. Groups by severity heuristic (HACK/FIXME high, TODO medium, NOTE low) and surfaces age via git blame so older items rank higher. Honors .gitignore.
version: 1.0.0
when_to_use: User asks "/todo", "what TODOs are still open", "any FIXMEs left in this module". Useful before a release, before handing off a project, or during a quarterly tech-debt review.
inputs:
  - name: target
    description: Optional path (file or directory) to scope the harvest. Defaults to the project root.
  - name: max_age_days
    description: Optional. If set, hide items younger than this many days (good for "show me anything older than 60 days"). Defaults to 0 (show all).
required_tools: [bash, read, grep]
---

# Todo Harvester Skill

## Goal

Collect TODO-like comments, classify urgency, and prioritize follow-up work
without editing source files.

## Workflow

1. Resolve scope from the user or default to the repo. Honor `.gitignore` when
   using `git grep`; skip generated/vendor/build directories.
2. Search for `TODO`, `FIXME`, `HACK`, `XXX`, `NOTE`, and project-specific
   markers.
3. Capture file, line, marker, owner if present, and surrounding one-line
   context.
4. Use `git blame` when available to estimate age and author. If the repo has
   no history, omit age rather than guessing.
5. Rank:
   - HIGH: `FIXME`, `HACK`, security/data-loss wording, release blockers;
   - MEDIUM: `TODO` with no owner or older than the requested age threshold;
   - LOW: `NOTE`, documentation reminders, owned near-term tasks.
6. Group duplicates that refer to the same underlying work.

## Output Format

```markdown
### TODO harvest
Scope: `src/`

#### HIGH
- `src/auth.ts:42`: FIXME: token refresh race. age: 184 days.

#### MEDIUM
- `src/report.ts:88`: TODO: paginate exports. owner: none.

#### Summary
- high: 1, medium: 3, low: 5
```

## Guardrails

- Do not delete comments from this skill.
- Do not expose full blame author emails if unnecessary; names or commit age are
  usually enough.
- Do not treat every TODO as urgent; rank by marker, age, and risk language.
