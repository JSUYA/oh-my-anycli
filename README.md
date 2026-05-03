# oh-my-anycli

oh-my-anycli adds reusable skills, slash commands, subagents, and plugins to opencode-anycli.

## Inspirations & how this project deviates from them

The directory layout (markdown skills + slash commands + sub-agent files) was
**inspired by** the MIT-licensed projects below. **No source text or code from
any of them was copied** — only the structural pattern, which is not a
copyrightable expression.

| Inspiration | License | What we took | What we deliberately changed |
|---|---|---|---|
| [`oh-my-zsh`](https://github.com/ohmyzsh/ohmyzsh) | MIT | The "git clone + ./install.sh + custom plugin slot + update via git pull" lifecycle | Targets opencode/cline instead of zsh |
| [`alvinunreal/oh-my-opencode-slim`](https://github.com/alvinunreal/oh-my-opencode-slim) | MIT | The `.opencode/skills/<name>/SKILL.md` + `.opencode/command/<name>.md` frontmatter pattern | TypeScript/Bun plugin -> pure markdown + bash (no runtime); single config file -> manifest-based install with `custom/` safe zone; embedded MCP / multiplexer / interview server features omitted to keep this project focused |

**Specific design choices:**

- **Pure markdown + bash, no TypeScript runtime** — zero build step, runs with
  `bash` and standard Unix tools
- **No bundled MCP servers** — web-search, Context7, grep.app, `mcp.exa.ai`,
  Divoom Bluetooth, and browser interview servers are out of scope for this
  collection
- **All sub-agents pinned to `model: cline/default`** — enforced by
  `tests/lint-agents.sh` and `install.sh`, because opencode-anycli exposes
  exactly one model id
- **Functional agent names** (`code-reviewer`, `dba`, `release-manager`)
  instead of literary character names — easier for new contributors to read
- **`omac plugin add <git-url>`** allows third-party plugins from any git host;
  upstream forks typically only accept PRs to a single monorepo
- **Coding-language-specific skills** added: C/C++ (`cpp-modernize`,
  `cpp-static-analysis`, `cmake-review`), Rust (`rust-clippy-triage`,
  `rust-unsafe-review`, `rust-idiom-modernize`), C#/.NET (`csharp-nullable-migrate`,
  `csharp-async-modernize`, `csharp-analyzer-fix`), Tizen (`tizen-manifest-review`,
  `tizen-api-modernize`, `tizen-privilege-audit`)

## What It Provides

- 36 skills for review, testing, documentation, DevOps, database, API, security, language-specific coding workflows (C/C++, Rust, C#, Tizen), and behavioral guidelines (Karpathy guidelines).
- 37 slash commands that route common tasks to those skills.
- 10 subagents pinned to `model: cline/default` for opencode-anycli compatibility.
- A Bash `omac` helper for listing, searching, installing, updating, and diagnosing the collection.
- A plugin slot for team- or project-specific extensions.

## Coding Advantages Over Plain cline CLI

oh-my-anycli does not change the model that cline uses. It improves coding outcomes by turning common development tasks into reusable workflows with explicit checks.

- **Feature work becomes more disciplined.** Skills can steer the agent to read existing patterns first, make scoped changes, and report verification instead of producing an isolated patch.
- **Runtime fixes become more evidence-based.** Debugging-oriented workflows encourage reproduction, stack-trace reading, dependency checks, ranked root-cause hypotheses, and minimal fixes.
- **Reviews become more consistent.** `/review` and the code-reviewer agent focus on correctness, regressions, missing tests, security issues, and file-level evidence.
- **Tests are less likely to be skipped.** `/test`, test-writing skills, and coverage workflows make it natural to add or run relevant tests after code changes.
- **Specialized domains get targeted criteria.** Security, database, Dockerfile, CI, release, API, and documentation tasks each get their own checklist instead of relying on a generic prompt.
- **Project standards are reusable.** The same commands, skills, and subagents can be versioned, reviewed, installed, updated, and extended through plugins.

Plain cline CLI is still the simpler choice for very small one-off edits. oh-my-anycli pays off when implementation, debugging, review, and verification need to happen as one repeatable development loop.

## Install

```bash
git clone https://github.com/JSUYA/oh-my-anycli.git ~/.oh-my-anycli
~/.oh-my-anycli/install.sh
omac doctor
```

opencode-anycli should be installed first so the target config directory exists.

## Uninstall

```bash
~/.oh-my-anycli/uninstall.sh                       # remove omac symlink + manifested files
~/.oh-my-anycli/uninstall.sh --remove-install-dir  # also delete ~/.oh-my-anycli itself
~/.oh-my-anycli/uninstall.sh --yes                 # skip confirmation prompts
```

The uninstaller is **manifest-based**: it only removes files that `install.sh`
recorded in `<target>/.oh-my-anycli/manifest.txt`. Skills/commands/agents you
authored yourself in the same directory are left intact.

## Common Commands

| Command | Purpose |
| --- | --- |
| `omac list [-v]` | List installed skills, commands, agents, and plugins. |
| `omac search <keyword>` | Search frontmatter metadata. |
| `omac info <name>` | Show one artifact's frontmatter. |
| `omac plugin add <git-url>` | Add an external plugin. |
| `omac update` | Pull and reapply the collection. |
| `omac doctor` | Check installation status. |

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
