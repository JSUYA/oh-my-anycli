# Oh-My-AnyCLI

Oh-My-AnyCLI adds reusable skills, slash commands, subagents, and plugins to OpenCode-AnyCLI.

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
  `tests/lint-agents.sh` and `install.sh`, because OpenCode-AnyCLI exposes
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

- 39 skills for review, testing, documentation, DevOps, database, API, security, sandboxed browser testing, language-specific coding workflows (C/C++, Rust, C#, Tizen), and behavioral guidelines (Karpathy guidelines).
- 40 slash commands that route common tasks to those skills.
- 12 agents pinned to `model: cline/default` for OpenCode-AnyCLI compatibility: 11 strict subagents plus `orchestrator` exposed with `mode: all` so it can be selected as a coordinator. Two were adapted from `alvinunreal/oh-my-opencode-slim` (MIT): `orchestrator`, `oracle`.
- A Bash `omac` helper for listing, searching, installing, updating, and diagnosing the collection.
- A plugin slot for team- or project-specific extensions, including native
  opencode plugin payloads such as the bundled MIT-licensed `caveman` plugin.

## Coding Advantages Over Plain cline CLI

Oh-My-AnyCLI does not change the model that cline uses. It improves coding outcomes by turning common development tasks into reusable workflows with explicit checks.

- **Feature work becomes more disciplined.** Skills can steer the agent to read existing patterns first, make scoped changes, and report verification instead of producing an isolated patch.
- **Runtime fixes become more evidence-based.** Debugging-oriented workflows encourage reproduction, stack-trace reading, dependency checks, ranked root-cause hypotheses, and minimal fixes.
- **Reviews become more consistent.** `/review` and the code-reviewer agent focus on correctness, regressions, missing tests, security issues, and file-level evidence.
- **Tests are less likely to be skipped.** `/test`, test-writing skills, and coverage workflows make it natural to add or run relevant tests after code changes.
- **Specialized domains get targeted criteria.** Security, database, Dockerfile, CI, release, API, and documentation tasks each get their own checklist instead of relying on a generic prompt.
- **Project standards are reusable.** The same commands, skills, and subagents can be versioned, reviewed, installed, updated, and extended through plugins.

Plain cline CLI is still the simpler choice for very small one-off edits. Oh-My-AnyCLI pays off when implementation, debugging, review, and verification need to happen as one repeatable development loop.

## Install

```bash
git clone https://github.com/JSUYA/oh-my-anycli.git ~/.oh-my-anycli
~/.oh-my-anycli/install.sh
omac doctor
```

OpenCode-AnyCLI should be installed first so the target config directory exists.

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
| `omac update` | `git pull --ff-only` + reapply (mirrors `opencode-anycli --update`). |
| `omac doctor` | Check installation status. |

## Update

To pull the latest skills/commands/agents from this repo and reapply them
to your `~/.config/opencode-anycli/opencode/` directory:

```bash
omac update              # auto-stash dirty tree → git pull --ff-only → reapply → pop
omac update --prune      # also remove artifacts that no longer exist upstream
omac update --no-stash   # skip auto-stash; abort if working tree is dirty
```

If `~/.oh-my-anycli` has uncommitted changes (tracked or untracked), `omac
update` will `git stash --include-untracked` them before pulling and
restore them after a successful reapply. If pull/install fails, the stash
is still popped so your tree is left as you had it. If the pop itself
conflicts, the stash is kept in `git stash list` for manual resolution.

To update the parent `opencode-anycli` wrapper (binary, provider, default
config), use its own update command:

```bash
opencode-anycli --update          # git pull + ./install.sh inside opencode-anycli's checkout
```

## Interactive Subprocesses (sudo, ssh-add, ...)

OpenCode-AnyCLI keeps the cline subprocess's stdin connected to your
terminal by default. If `sudo apt install ...` (or any other privileged
command) still fails inside an agent run because the inner bash tool
doesn't forward stdin, restart the session with the single-flag escape
hatch:

```bash
opencode-anycli --allow-dangerously-skip-permissions
opencode-anycli --dangerously-skip-permissions      # alias
OPENCODE_ANYCLI_DANGEROUS=1 opencode-anycli         # env-var equivalent
```

The wrapper re-execs itself under `sudo -E` (one password prompt up
front), so the inner cline + bash subprocesses run as root and can
install packages, start daemons, run Docker, or any other privileged
operation without ever hitting another prompt. **Nothing is written to
`/etc/sudoers.d/`** and there is no persistent privilege change.

The flag also implies `--auto-approve`, so opencode's per-tool
permission prompts are silenced for the same session.

Trade-off: files created during the session will be root-owned. The
flag is named `dangerously` for a reason — only opt in when you trust
the agent's full action set and ideally run inside a disposable VM /
container / fresh checkout.

To opt out of the TTY default (CI / piped input):

```bash
opencode-anycli --no-tty
# or
export OPENCODE_ANYCLI_TTY=0
```

## Auto-approve (Yolo Mode)

OpenCode-AnyCLI prompts for approval on file edits, bash commands, web
fetches, and other gated tools. To silence those prompts for an unattended
session, relaunch OpenCode-AnyCLI with the auto-approve flag:

```bash
opencode-anycli --auto-approve     # also accepts --yolo, -y
# or persistent:
export OPENCODE_ANYCLI_AUTO_APPROVE=1
```

This is a **session-scoped** decision: opencode loads its permission
config once at start and does not watch it for changes. There is no
slash command or env var that flips auto-approve in the middle of a
running session.

The slash command `/auto-approve` (and the `auto-approve` skill it
invokes) is provided **only to give that exact answer to the user** when
they ask "how do I turn off these prompts?". It does not — and cannot —
silently mutate the live session. See `skills/auto-approve/SKILL.md` for
the full explanation, including the two-layer permission model
(opencode outer vs cline inner) and the safety guidance.

The cline subprocess that OpenCode-AnyCLI spawns is already invoked with
`--yolo` by the provider, so the inner cline layer never asked for
approval to begin with — `--auto-approve` only affects the outer
opencode layer.

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
