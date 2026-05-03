# oh-my-clinecli

oh-my-clinecli adds reusable skills, slash commands, subagents, and plugins to openclineclicode.

## Inspirations & how this project deviates from them

The directory layout (markdown skills + slash commands + sub-agent files) was
**inspired by** the MIT-licensed projects below. **No source text or code from
any of them was copied** — only the structural pattern, which is not a
copyrightable expression.

| Inspiration | License | What we took | What we deliberately changed |
|---|---|---|---|
| [`oh-my-zsh`](https://github.com/ohmyzsh/ohmyzsh) | MIT | The "git clone + ./install.sh + custom plugin slot + update via git pull" lifecycle | Targets opencode/cline instead of zsh |
| [`alvinunreal/oh-my-opencode-slim`](https://github.com/alvinunreal/oh-my-opencode-slim) | MIT | The `.opencode/skills/<name>/SKILL.md` + `.opencode/command/<name>.md` frontmatter pattern | TypeScript/Bun plugin → pure markdown + bash (no runtime); single config file → manifest-based install with `custom/` safe zone; embedded MCP / multiplexer / interview server features omitted (internal-network constraint) |

**Specific intranet-driven deviations:**

- **Pure markdown + bash, no TypeScript runtime** — zero build step, runs on a
  locked-down workstation with only `bash` + standard unix tools
- **No external MCP servers** — web-search, Context7, grep.app, `mcp.exa.ai`,
  Divoom Bluetooth, browser interview servers all dropped; only intranet-safe
  artifacts ship
- **All sub-agents pinned to `model: cline/default`** — enforced by
  `tests/lint-agents.sh` and `install.sh`, because openclineclicode exposes
  exactly one model id (intranet constraint)
- **Functional agent names** (`code-reviewer`, `dba`, `release-manager`)
  instead of literary character names — easier for new contributors to read
- **`omc plugin add <git-url>`** allows third-party plugins from any git host;
  upstream forks typically only accept PRs to a single monorepo
- **Korean primary docs** for the standup/weekly/handoff workflows, since the
  target audience is Korean-speaking corporate engineering teams
- **Internal-network-specific skills** added: `internal-network-deps-audit`,
  `standup-summary`, `weekly-report`, `handoff-doc`

## What It Provides

- 27 skills for review, testing, documentation, DevOps, database, API, security, and reporting workflows.
- 31 slash commands that route common tasks to those skills.
- 10 subagents pinned to `model: cline/default` for openclineclicode compatibility.
- A Bash `omc` helper for listing, searching, installing, updating, and diagnosing the collection.
- A plugin slot for team- or project-specific extensions.

## Install

```bash
git clone https://github.com/JSUYA/oh-my-clinecli.git ~/.oh-my-clinecli
~/.oh-my-clinecli/install.sh
omc doctor
```

openclineclicode should be installed first so the target config directory exists.

## Uninstall

```bash
~/.oh-my-clinecli/uninstall.sh                       # remove omc symlink + manifested files
~/.oh-my-clinecli/uninstall.sh --remove-install-dir  # also delete ~/.oh-my-clinecli itself
~/.oh-my-clinecli/uninstall.sh --yes                 # skip confirmation prompts
```

The uninstaller is **manifest-based**: it only removes files that `install.sh`
recorded in `<target>/.oh-my-clinecli/manifest.txt`. Skills/commands/agents you
authored yourself in the same directory are left intact.

## Common Commands

| Command | Purpose |
| --- | --- |
| `omc list [-v]` | List installed skills, commands, agents, and plugins. |
| `omc search <keyword>` | Search frontmatter metadata. |
| `omc info <name>` | Show one artifact's frontmatter. |
| `omc plugin add <git-url>` | Add an external plugin. |
| `omc update` | Pull and reapply the collection. |
| `omc doctor` | Check installation status. |

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
