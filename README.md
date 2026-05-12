# Oh-My-AnyCLI

Reusable skills, slash commands, and subagents for OpenCode-AnyCLI — pure markdown + bash, no runtime.

## What It Provides

- **39 skills** for review, testing, docs, DevOps, DB, API, security, sandboxed browser testing, and language-specific workflows (C/C++, Rust, C#, Tizen).
- **40 slash commands** that route common tasks to those skills.
- **12 subagents** pinned to `model: cline/default` for OpenCode-AnyCLI compatibility.
- **`omac` CLI** for listing, searching, installing, updating, and diagnosing the collection.
- **Plugin slot** for team- or project-specific extensions.

## Install

```bash
git clone https://github.com/JSUYA/oh-my-anycli.git ~/.oh-my-anycli
~/.oh-my-anycli/install.sh
omac doctor
```

## Commands

| Command | Purpose |
| --- | --- |
| `omac list [-v]` | List installed skills, commands, agents, and plugins. |
| `omac search <keyword>` | Search frontmatter metadata. |
| `omac info <name>` | Show one artifact's frontmatter. |
| `omac plugin add <git-url>` | Add an external plugin. |
| `omac update [--prune]` | Pull latest and reapply to your opencode config. |
| `omac doctor` | Check installation status. |
| `~/.oh-my-anycli/uninstall.sh` | Remove manifested files (keeps your own additions). |

## Skills

**Review & quality**
- `code-review` — surfaces correctness, security, perf, and test-coverage issues on the current branch
- `refactor-helper` — small, targeted refactors only (extract / rename / simplify)
- `dead-code-finder` — unused exports, imports, unreachable code
- `lint-fix` — runs the project's configured linter and proposes fixes
- `log-level-auditor` — finds inappropriate `console.log` / `print` / etc. in production paths
- `todo-harvester` — categorizes TODO/FIXME/HACK by severity and age

**Testing**
- `unit-test-writer` — generates unit tests in the project's existing framework
- `integration-test-writer` — tests that exercise real DB/API/message-bus dependencies
- `test-coverage-reporter` — runs the project's coverage tool and highlights gaps
- `sandboxed-browser-testing` — Playwright/Puppeteer only inside Docker, never on host

**Docs & git**
- `explain-code` — summary / walkthrough / deep-dive on a function, file, or module
- `readme-bootstrap` — generates an initial README from project structure
- `pr-description-writer` — PR description from commits since base
- `git-commit-helper` — conventional commit message from staged changes

**Diagnosis & security**
- `error-diagnose` — ranked root-cause hypotheses with falsifiable experiments
- `security-scan` — local sweep for secrets, unsafe patterns, risky deps

**Database & API**
- `migration-writer` — forward + reverse migration in the detected framework
- `sql-explain-reader` — interprets EXPLAIN / EXPLAIN ANALYZE in plain English
- `api-changelog` — diffs two OpenAPI/GraphQL specs into a breaking-change report
- `openapi-validator` — local consistency check for OpenAPI / Swagger specs

**DevOps & shell**
- `dockerfile-review` — image hygiene, layer cache, secret leaks, USER, healthcheck
- `ci-config-validator` — matrix, secrets, pinned action versions, timeouts
- `shell-script-review` — `set -euo pipefail`, quoting, eval/source, temp-file races

**C / C++**
- `cpp-modernize` — pre-C++11 to C++17/20 idioms with per-hunk risk classification
- `cpp-static-analysis` — clang-tidy / cppcheck triage with per-file approval
- `cmake-review` — modern targets, glob risks, policies, install rules

**Rust**
- `rust-clippy-triage` — pedantic clippy with grouped findings, opt-in `--fix`
- `rust-idiom-modernize` — older patterns to current idioms without new deps
- `rust-unsafe-review` — audits every `unsafe` block against a soundness checklist

**C# / .NET**
- `csharp-analyzer-fix` — `dotnet format` + Roslyn analyzer triage
- `csharp-async-modernize` — sync-over-async to async/await with CancellationToken
- `csharp-nullable-migrate` — enables nullable refs and triages CS86xx warnings

**Tizen**
- `tizen-api-modernize` — deprecated native API → recommended replacement
- `tizen-manifest-review` — manifest API/profile/feature/category review
- `tizen-privilege-audit` — declared privileges vs actual API usage

**Workflow & meta**
- `branch-prep` — rebase, lint, test, push only after explicit confirmation
- `auto-approve` — explains opencode-anycli auto-approve and how to enable it
- `sudo-helper` — three workarounds for sudo inside an opencode-anycli session
- `karpathy-guidelines` — behavioral guidelines: think before coding, surgical changes

## Agents

All agents are pinned to `model: cline/default`.

- `architect` — read-only architecture surveyor; maps boundaries and layering violations
- `code-reviewer` — branch-diff review focused on correctness, security, missing tests
- `dba` — migrations, EXPLAIN plans, indexes; classifies migration risk
- `debugger` — root-cause investigation with ranked hypotheses and one-line fixes
- `devops-engineer` — Dockerfile / CI workflow / shell-script specialist
- `doc-explainer` — read-only code walker at the depth you ask for
- `doc-writer` — READMEs, runbooks, architecture pages in the project's existing tone
- `oracle` — strategic technical questions and high-stakes design calls (read-only)
- `orchestrator` — plans and routes multi-step tasks across the other agents
- `release-manager` — branch prep, PR descriptions, changelog seeds, weekly reports
- `security-auditor` — local-only sweep for secrets, unsafe patterns, risky deps
- `test-writer` — unit and integration tests in the project's existing framework

## Documentation

- [Installation](docs/installation.md)
- [Skill authoring](docs/skill-authoring.md)
- [Command authoring](docs/command-authoring.md)
- [Agent authoring](docs/agent-authoring.md)
- [Plugin authoring](docs/plugin-authoring.md)
- [Team deployment](docs/team-deployment.md)
- [Update flow](docs/update-flow.md)
- [Architecture](docs/architecture.md)
- [Troubleshooting](docs/troubleshooting.md)

## License

MIT. See [LICENSE](LICENSE).
