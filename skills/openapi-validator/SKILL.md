---
name: openapi-validator
description: Validates a local OpenAPI / Swagger specification for internal consistency — undefined $refs, missing required fields, response status coverage, schema-vs-example mismatches, and security schemes that are defined but never applied. Local file only.
version: 1.0.0
when_to_use: User asks "/openapi", "validate this spec", or has just edited `openapi.yaml`/`swagger.json` and wants a quick consistency pass before publishing or generating clients.
inputs:
  - name: spec_path
    description: Path to the OpenAPI/Swagger spec file (`openapi.yaml`, `openapi.yml`, `openapi.json`, `swagger.json`, etc.). Required.
required_tools: [bash, read, grep]
---

# OpenAPI Validator Skill

## Goal

Validate a local OpenAPI or Swagger specification for internal consistency
without uploading it anywhere.

## Boundary

Use this skill for one spec's internal validity. Use `api-changelog` when the
question is "what changed between two versions?" or whether a spec edit is
breaking for clients.

## Workflow

1. Resolve `spec_path`. If absent, search for `openapi.yaml`, `openapi.yml`,
   `openapi.json`, `swagger.yaml`, or `swagger.json`.
2. Parse with project tooling when available (`spectral`, `swagger-cli`,
   `redocly`, `openapi-generator validate`, `yq`, `jq`). If no parser exists,
   perform shallow static checks and label that limitation.
3. Validate references and structure:
   - every `$ref` resolves locally;
   - paths have methods with `responses`;
   - path template variables have matching `in: path` required parameters;
   - schemas listed in `required` exist under `properties`;
   - examples match schema shape where cheaply checkable;
   - request/response content types are explicit;
   - security schemes are defined and applied intentionally;
   - operationIds are unique when present.
4. Flag severity:
   - HIGH: invalid `$ref`, missing response, invalid required field, broken path
     parameter;
   - MEDIUM: security scheme mismatch, duplicate operationId, schema/example
     mismatch;
   - LOW: docs consistency and naming issues.
5. Report exact JSON pointer or path/method evidence.

## Output Format

```markdown
### OpenAPI validation
Spec: `openapi.yaml`

#### HIGH
- `#/paths/~1users~1{id}/get/parameters`: `{id}` appears in the path but no
  required `in: path` parameter named `id` is declared.

#### MEDIUM
- `#/components/securitySchemes/BearerAuth`: defined but never applied.

#### Verification
- `npx spectral lint openapi.yaml`: failed with 2 errors
```

## Guardrails

- Do not fetch remote schemas or validators.
- Do not edit the spec from this validation skill.
- Do not treat description text as contract unless the schema is ambiguous and
  you label the finding as LOW confidence.
