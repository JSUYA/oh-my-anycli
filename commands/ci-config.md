---
description: "Review CI configuration for common safety and reliability issues."
argument_hint: "[optional arguments]"
allowed_tools: [bash, read, grep]
routes_to_skill: ci-config-validator
---

<command-instruction>
Run the `ci-config-validator` skill workflow on the user's request.

When to use: User asks "/ci-config", "review my workflow", or has just modified `.github/workflows/*.yml`, `.gitlab-ci.yml`, `Jenkinsfile`, or `.circleci/config.yml`. Useful before pushing CI changes that could leak secrets or run forever.

Keep the task scoped to what the user asked for, preserve the project's
existing conventions, and report findings or edits with concrete file:line
references. Do not perform destructive Git, filesystem, or network
operations unless the user explicitly requested them. If the matching
skill (`ci-config-validator`) is not installed in this environment, follow the
workflow described in skills/ci-config-validator/SKILL.md.
</command-instruction>
