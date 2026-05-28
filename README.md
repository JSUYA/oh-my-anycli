# Oh-My-AnyCLI

Reusable skills, slash commands, subagents, and plugins for multiple AI agent CLIs — pure markdown + bash, no runtime.

## What It Provides

- **38 skills** for review, testing, docs, DevOps, DB, API, security, sandboxed browser testing, and language-specific workflows (C/C++, Rust, C#, Tizen).
- **39 slash commands** that route common tasks to those skills.
- **12 subagents** pinned to `model: cline/default` for OpenCode-AnyCLI compatibility.
- **`omac` CLI** for target-aware listing, searching, selected install/remove, updating, and diagnosing the collection.
- **Plugin slot** for team- or project-specific extensions, including native opencode payloads such as the bundled MIT-licensed `caveman` plugin.

## Install

```bash
git clone https://github.com/JSUYA/oh-my-anycli.git ~/.oh-my-anycli
~/.oh-my-anycli/install.sh --no-symlink
~/.oh-my-anycli/omac skill list
~/.oh-my-anycli/omac skill install code-review --target claude
```

`install.sh` is kept as a legacy OpenCode bulk installer. Prefer `omac skill install` and `omac plugin install` for selected installs.

## Commands

| Command | Purpose |
| --- | --- |
| `omac list [-v]` | List universal skill/plugin status across Claude, Codex, Cline, and OpenCode targets. |
| `omac search <keyword>` | Search frontmatter metadata. |
| `omac info <name>` | Show one artifact's frontmatter. |
| `omac skill list [--target universal\|claude\|codex\|cline\|opencode] [--global\|--local]` | List skills for one target or the universal matrix. |
| `omac skill install <name\|all> [--target universal\|claude\|codex\|cline\|opencode]` | Install selected skill(s). |
| `omac skill remove <name> [--target universal\|claude\|codex\|cline\|opencode]` | Remove managed selected skill installs. |
| `omac plugin list [--target universal\|claude\|codex\|cline\|opencode]` | List plugin status for one target or the universal matrix. |
| `omac plugin add <git-url>` | Add an external plugin to the local registry. |
| `omac plugin install <name\|all> [--target universal\|claude\|codex\|cline\|opencode]` | Install selected plugin(s). |
| `omac plugin remove <name> [--target universal\|claude\|codex\|cline\|opencode]` | Remove managed plugin artifacts but keep the registry copy. |
| `omac plugin delete <name>` | Delete a plugin from the local registry. |
| `omac update [--prune]` | Pull latest and reapply to your opencode config. |
| `omac doctor` | Check installation status. |
| `~/.oh-my-anycli/uninstall.sh` | Remove manifested files (keeps your own additions). |

### Command Details

Target option:

- `--target universal` is the default view. It shows Claude, Codex, Cline, and OpenCode status side by side.
- `--target claude`, `--target codex`, `--target cline`, and `--target opencode` limit a command to one agent target.
- For install/remove commands, `--target universal` applies to all supported targets.
- `--global` uses the user's agent config roots. This is the default.
- `--local` uses project-local roots: `.claude`, `.codex`, `.cline`, and `.opencode`.
- Cline skills install to `~/.cline/skills` globally or `.cline/skills` locally; enable Skills in the Cline VS Code extension settings.

Status values:

- `active`: installed by `omac` and identical to the registry source.
- `modified`: installed by `omac`, but the target file was edited after install.
- `present`: a matching file exists, but `omac` does not own it.
- `missing`: no matching target artifact exists.

Skill commands:

- `omac skill list`: Shows every registry skill and whether it is installed for Claude, Codex, Cline, and OpenCode. Use `--target claude`, `--target codex`, `--target cline`, or `--target opencode` to see one target only.
- `omac skill status <name>`: Shows one skill's status and destination path per target.
- `omac skill install <name>`: Copies one skill from `skills/<name>/SKILL.md` into the selected target. It refuses to overwrite unmanaged files unless `--force` is used.
- `omac skill install all`: Installs every registry skill into the selected target.
- `omac skill remove <name>`: Removes only files that `omac` owns through its selected-install manifest. Unmanaged user files are left in place.

Plugin commands:

- `omac plugin list`: Shows every registry plugin and whether its managed artifacts are installed for each target.
- `omac plugin add <git-url>`: Clones the plugin into `plugins/<name>/` only. It updates the local registry, but does not install or activate the plugin in any agent.
- `omac plugin install <name>`: Installs the selected plugin's supported artifacts into the selected target. OpenCode native payloads under `opencode/` are copied and JS plugin files are registered in `opencode.json`.
- `omac plugin install all`: Installs every registry plugin into the selected target.
- `omac plugin remove <name>`: Removes the plugin artifacts that `omac` installed for the selected target, but keeps `plugins/<name>/` in the registry.
- `omac plugin delete <name>`: Deletes the plugin's registry checkout from `plugins/<name>/`. It does not replace `plugin remove`; remove installed artifacts first when needed.

Compatibility alias:

- `omac skills` is accepted as an alias for `omac skill`.

Examples:

```bash
omac skill list
omac skills --target universal list --global
omac skill --target claude
omac skill install code-review --target claude
omac skill install code-review --target cline
omac skill install all --target opencode
omac skill remove code-review --target claude

omac plugin add https://github.com/acme/my-omac-plugin.git
omac plugin list
omac plugin install my-omac-plugin --target opencode
omac plugin remove my-omac-plugin --target opencode
omac plugin delete my-omac-plugin
```

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
- `tizen-sdb-helper` — picks safe `sdb` commands for Tizen device operations

**Workflow & meta**
- `branch-prep` — rebase, lint, test, push only after explicit confirmation
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

## Plugins

Plugins package shareable skills, commands, and agents outside the core collection. Use `omac plugin add <git-url>` to install one, `omac plugin remove <name>` to remove it.

**Bundled**
- `caveman` — native opencode caveman mode (commands, skills, AGENTS.md ruleset); MIT-licensed payload from [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman)

**Layout**

```text
my-plugin/
├── plugin.json          # required: name, version, description
├── skills/<name>/SKILL.md
├── commands/<name>.md
├── agents/<name>.md     # must declare model: cline/default
└── opencode/            # optional: native opencode payload, copied unprefixed
    ├── plugins/
    ├── commands/
    ├── skills/
    ├── agents/
    └── AGENTS.append.md # managed block in target AGENTS.md
```

Core artifacts install with a `<plugin>__` prefix (`skills/<plugin>__<skill>/SKILL.md`, etc.) to avoid collisions. Files under `opencode/` are copied verbatim without a prefix. See [docs/plugin-authoring.md](docs/plugin-authoring.md) for the full contract.

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

Additional attribution: [skill_prompt.md](skill_prompt.md) adapts a public
Codex skill-authoring prompt shared by reach_vb at
https://x.com/reach_vb/status/2058538305872949490.
