---
name: api-changelog
description: Compares two OpenAPI / GraphQL spec files (or two git revisions of the same spec) and produces a structured breaking-change report covering removed endpoints, changed parameter types, removed enum values, and response shape changes. Categorized as BREAKING / NON-BREAKING / ADDITIVE.
version: 1.0.0
when_to_use: User asks "/api-diff", "what changed in this spec", or before publishing a new API version. Useful for downstream client teams who need a heads-up on breaking changes.
inputs:
  - name: old_spec
    description: Path to the older spec file, OR a git revision (e.g. "HEAD~1:openapi.yaml", "v1.2.0:openapi.yaml").
  - name: new_spec
    description: Path to the newer spec file, OR a git revision. Defaults to the current working-tree version of the same path as `old_spec`.
required_tools: [bash, read, grep]
---

# API Changelog Skill

## Goal

Compare two API specs or revisions and produce a reviewer-ready changelog
that separates BREAKING, NON-BREAKING, and ADDITIVE changes. This skill is
read-only; it does not rewrite specs.

## Boundary

Use this skill for cross-version API comparison. Use `openapi-validator` first
when the task is to validate a single local OpenAPI/Swagger file or resolve
`$ref`/schema consistency issues.

## Workflow

1. Resolve the old and new specs. Accept plain paths or `rev:path` syntax. If
   only one path is provided, compare the merge-base version against the working
   tree version when Git history is available.
2. Identify the format before comparing:
   - OpenAPI / Swagger: inspect `openapi`, `swagger`, `paths`, `components`,
     `definitions`, and `security`.
   - GraphQL SDL: inspect `type`, `input`, `enum`, `interface`, `union`,
     directives, and field argument changes.
3. Prefer structured parsing tools when present (`yq`, `jq`, `python -m
   json.tool`, project OpenAPI tooling). Use text diffs only as a fallback and
   label the result as shallow.
4. Compare public surface area, not formatting:
   - removed path, method, operationId, query/header/path parameter;
   - parameter requiredness or type changes;
   - request body requiredness, content type, schema, enum, min/max changes;
   - response status removal, schema narrowing, enum value removal;
   - authentication or scope becoming stricter;
   - GraphQL field/type/enum removal, nullability tightening, or required
     argument/input field additions.
5. Classify each change:
   - BREAKING: existing clients can fail or need code changes.
   - NON-BREAKING: behavior or docs changed, existing clients should still work.
   - ADDITIVE: new endpoint, field, enum value, optional parameter, or response.
6. Include evidence: spec path, JSON pointer or GraphQL type/member, and old
   value -> new value.

## Output Format

```markdown
### API changelog

Compared:
- old: <path-or-rev>
- new: <path-or-rev>

#### BREAKING
- `GET /v1/users/{id}` response `200#/properties/name`: `string` -> removed
  impact: clients reading `name` fail or receive undefined

#### NON-BREAKING
- `POST /v1/users` description changed; no schema change detected

#### ADDITIVE
- `GET /v1/users` optional query parameter `includeInactive`

#### Verification
- parser/tool used, or "shallow text comparison only" with reason
```

## Guardrails

- Do not call an online API diff service or upload specs.
- Do not mark formatting, description-only, or example-only changes as breaking.
- Do not assume removing an undocumented field is safe; if it appears in the
  schema, treat removal as breaking.
- Do not invent semantic behavior from names alone. If the spec lacks detail,
  call out the uncertainty.
