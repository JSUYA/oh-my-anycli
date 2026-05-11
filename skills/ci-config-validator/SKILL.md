---
name: ci-config-validator
description: Validates a CI configuration file (GitHub Actions, GitLab CI, Jenkins, CircleCI) for matrix completeness, secret-handling patterns, pinned third-party action versions, timeout settings, and concurrency cancellation. Local file only — no API calls.
version: 1.0.0
when_to_use: User asks "/ci-config", "review my workflow", or has just modified `.github/workflows/*.yml`, `.gitlab-ci.yml`, `Jenkinsfile`, or `.circleci/config.yml`. Useful before pushing CI changes that could leak secrets or run forever.
inputs:
  - name: ci_path
    description: Optional explicit path to a CI config file. If omitted, the skill auto-detects the first existing CI config in the repository.
required_tools: [bash, read, grep]
---

# Ci Config Validator Skill

## Goal

Review local CI configuration for reliability, least privilege, and secret
safety. This skill is read-only and produces prioritized findings.

## Boundary

Use this skill for CI orchestration files. Use `shell-script-review` for
standalone scripts called by CI, and `dockerfile-review` for container build
definitions referenced by CI. This skill may flag risky embedded shell snippets,
but it should not become a full shell or Dockerfile audit.

## Workflow

1. Resolve CI files from the user's path or auto-detect:
   `.github/workflows/*.yml`, `.github/workflows/*.yaml`, `.gitlab-ci.yml`,
   `Jenkinsfile`, `.circleci/config.yml`, `azure-pipelines.yml`.
2. Read each file end-to-end. For YAML files, use existing formatters or
   parsers if available; otherwise use grep plus line-level inspection.
3. Apply the checklist:
   - triggers: no untrusted PR code running with secrets (`pull_request_target`,
     broad manual inputs, unguarded fork workflows);
   - permissions: GitHub Actions workflow-level `permissions:` minimized;
   - third-party actions/images pinned tightly enough for the project's policy;
   - secret handling: no echoing secrets, no secrets in cache keys, no untrusted
     shell interpolation;
   - concurrency: long-running branch workflows cancel stale runs when safe;
   - timeouts: expensive jobs have explicit bounds;
   - cache keys: lockfile hash used, not only branch or commit SHA;
   - matrix: all intended OS/language versions included and failures not
     silently ignored;
   - artifacts: retention and contents are intentional.
4. For shell snippets embedded in CI, review quoting and `set -e` behavior only
   in the snippet's local context.
5. Rank findings as HIGH (secret/code execution risk), MEDIUM (flaky, slow, or
   privilege issue), LOW (maintainability).

## Output Format

```markdown
### CI config review
Files reviewed: <n>

#### HIGH
- `.github/workflows/ci.yml:12`: `pull_request_target` runs checkout of PR code
  with repository secrets available.
  fix: use `pull_request`, or avoid checking out PR code in the privileged job.

#### MEDIUM
- `.github/workflows/ci.yml:44`: cache key omits `package-lock.json`;
  dependency changes can reuse stale cache.

#### Verification
- local syntax check or reason it was not available
```

## Guardrails

- Do not fetch action metadata or vulnerability data from the network.
- Do not rewrite CI files from this skill; report the smallest patch instead.
- Do not require SHA pinning if the repository's neighboring workflows clearly
  use tag pinning, but flag floating `main`, `master`, or `latest` as risky.
- Do not invent line numbers or CI provider semantics.
