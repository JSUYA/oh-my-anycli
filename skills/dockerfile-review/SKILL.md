---
name: dockerfile-review
description: Reviews a Dockerfile for image base hygiene, layer cache ordering, secret leak risk, non-root USER, healthcheck, multi-stage opportunities, and the presence of .dockerignore. Refuses to touch ARGs that look like network connectivity settings.
version: 1.0.0
when_to_use: User asks "/dockerfile-review", "review this Dockerfile", or has just authored or modified a Dockerfile and wants a sanity pass before committing. Useful before a base-image bump or before publishing a new image to an internal registry.
inputs:
  - name: dockerfile_path
    description: Optional path to the Dockerfile (default "./Dockerfile"). Accepts variants such as "Dockerfile.build" or "docker/api.Dockerfile".
required_tools: [bash, read]
---

# Dockerfile Review Skill

## Goal

Review Dockerfiles for reproducibility, cache behavior, secret safety, and
runtime hygiene. This skill is read-only and reports findings only.

## Boundary

Use this skill for Dockerfile and image-build semantics. Use
`ci-config-validator` for workflow triggers, permissions, and cache wiring
around the build. Use `security-scan` for repo-wide secret sweeps beyond what is
visible in the Dockerfile.

## Workflow

1. Resolve target Dockerfiles: user path, `Dockerfile`, `*.Dockerfile`, or
   Dockerfiles changed on the branch.
2. Read `.dockerignore`, compose files, and CI build commands when present; they
   affect what the Dockerfile actually receives.
3. Walk the Dockerfile in stage order and apply:
   - base images pinned enough for the environment; avoid `latest`;
   - dependency install layers copy lockfiles before source;
   - build secrets are not passed through `ARG`, `ENV`, or committed files;
   - final image runs as non-root when the app allows it;
   - build tools do not leak into runtime stage;
   - package manager caches cleaned when they affect image size;
   - `HEALTHCHECK` exists for long-running services when the platform uses it;
   - `COPY . .` is paired with a sane `.dockerignore`;
   - ports, entrypoint, and command match the app's runtime shape.
4. Rank HIGH for credential leakage or root/runtime escape risks, MEDIUM for
   reproducibility/cache issues, LOW for maintainability.

## Output Format

```markdown
### Dockerfile review

#### HIGH
- `Dockerfile:14`: `ARG NPM_TOKEN` can be persisted in image history.
  fix: use BuildKit `--secret` and avoid writing the token into a layer.

#### MEDIUM
- `Dockerfile:8`: `COPY . .` precedes `npm ci`; every source change invalidates
  dependency cache.

#### Verification
- `docker build .` not run: Docker unavailable
```

## Guardrails

- Do not rewrite the Dockerfile from this skill.
- Do not recommend a new base image family without checking neighboring files.
- Do not remove proxy or certificate `ARG`s that may be required in enterprise
  networks; flag them and ask for confirmation.
