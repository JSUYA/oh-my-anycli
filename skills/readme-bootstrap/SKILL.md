---
name: readme-bootstrap
description: Generates an initial README from project structure — detects language(s), entry point, infers purpose from manifest description, and proposes Install/Usage/Development sections. Refuses to overwrite an existing README and writes to README.draft.md instead.
version: 1.0.0
when_to_use: User asks "/readme", "draft a README", or starts a new project that lacks one. Useful for spinning up a sane skeleton you then edit.
inputs:
  - name: scope
    description: Optional path to scope the inference to (e.g., a sub-package directory). Defaults to the project root.
required_tools: [bash, read, edit]
---

# Readme Bootstrap Skill

## Goal

Draft an initial README from project structure without overwriting an existing
README.

## Workflow

1. Resolve scope and inspect only top-level project evidence first:
   manifest files, package metadata, entrypoints, docs, examples, tests, and CI.
2. If a README already exists, write `README.draft.md` unless the user
   explicitly asks to edit the existing README.
3. Infer purpose cautiously from real metadata: package description, module
   names, CLI help, comments, tests, or examples. If purpose is unclear, state
   that and keep the README generic.
4. Include sections that match the project:
   - Overview;
   - Requirements;
   - Installation;
   - Usage;
   - Development;
   - Testing;
   - Configuration or Environment, only if detected;
   - License, only if a license file exists.
5. Verify commands before including their output when safe. If not run, mark
   commands as unverified.
6. Keep placeholders out of the final draft unless the user asked for a template.

## Output Format

```markdown
### README draft
- wrote: `README.draft.md`
- inferred entrypoint: `bin/mycli`
- unverified commands: `npm publish`

### Verification
- `npm test`: not run: no dependencies installed
```

## Guardrails

- Do not overwrite an existing README unless explicitly asked.
- Do not invent install commands, environment variables, screenshots, badges, or
  support channels.
- Do not document future behavior that is not present in the repository.
