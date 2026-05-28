# Changelog

All notable changes to **Oh-My-AnyCLI** are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning follows [SemVer](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `install.sh`: native opencode plugin payload support under
  `plugins/<name>/opencode/`, copied into the target config without the
  Oh-My-AnyCLI prefix.
- Bundled MIT-licensed `caveman` plugin with upstream attribution, native
  opencode plugin files, slash commands, skills, and managed AGENTS.md rules.
- `tests/e2e-plugin.sh`: coverage for native opencode plugin install, manifest
  tracking, managed AGENTS.md block installation, and prune removal.
- `lib/common.sh`: `omac_frontmatter_block_get` for extracting multi-line
  frontmatter blocks (lists / nested objects) without changing the existing
  single-line parser semantics.
- `tests/lint-plugins.sh` — validate `plugins/<name>/plugin.json` and prefixed
  artifact layout.
- `tests/unit-frontmatter.sh` — unit tests for the frontmatter parser helpers.
- `tests/e2e-install.sh` — install / reapply / prune / uninstall round-trip
  against an isolated temp directory.
- `tests/e2e-plugin.sh` — `omac plugin add` / `remove` lifecycle exercising
  `plugins/examples/hello-world`.
- `tests/e2e-omac.sh` — smoke tests for `omac list` / `search` / `info` /
  `doctor` / `version`.
- `tests/matrix-artifacts.sh` — every `commands/<name>.md` must point at a real
  `skills/<name>/SKILL.md` (or be explicitly allow-listed as CLI-only).
- `tests/run-all.sh` — single entrypoint that runs every lint + unit + e2e
  script.
- `tests/ci.yml.sample` — sample GitHub Actions workflow that wires `run-all`
  into CI.
- `omac --target cline`: selected skill installs for Cline's
  `~/.cline/skills` and project-local `.cline/skills` directories.
- `skill_prompt.md`: an adapted skill discovery and authoring prompt based on
  a public Codex prompt shared by reach_vb.

### Changed

- `install.sh`: `install_one` no longer uses `eval`-based indirect counter
  variables. Counters are now incremented at the call site based on the
  function's exit code, removing the shell-injection footgun called out in the
  prior comment block.
- `commands/*.md`: each command body now names the skill it routes to and
  carries that skill's `when_to_use` text, so the file is self-documenting
  instead of repeating a generic boilerplate.

### Fixed

- `CHANGELOG.md`: replaced placeholder template text that had been left in
  earlier releases with the actual change history.
- `plugins/examples/hello-world/skills/hello/SKILL.md`: corrected the malformed
  duplicate `description:` key inside the frontmatter so the example passes
  `lint-skills.sh`.

## [0.3.1] — 2026-05-08

### Fixed

- `skills/sudo-helper/SKILL.md` and `commands/sudo.md`: `/sudo` now points users
  at `opencode-anycli --allow-dangerously-skip-permissions` (the real flag the
  wrapper exposes) instead of the older `--setup-sudo` placeholder.

### Changed

- Documentation prose now consistently uses the **Oh-My-AnyCLI** /
  **OpenCode-AnyCLI** brand names. Internal identifiers (`omac`,
  `~/.oh-my-anycli`, `opencode-anycli`) are unchanged.
- `docs/*.md`: normalized installation, skill / command / agent / plugin
  authoring, team deployment, update flow, architecture, and troubleshooting
  guides into a single voice.

## [0.3.0] — 2026-05-04

### Added

- **Tizen workflow skills**: `tizen-manifest-review`, `tizen-api-modernize`,
  `tizen-privilege-audit`, plus matching `/tizen-manifest`, `/tizen-api-modernize`,
  `/tizen-privilege` slash commands.
- **Sandboxed browser testing**: `sandboxed-browser-testing` skill +
  `/sandbox` command. Refuses to run Playwright/Puppeteer against the host
  browser; everything goes through Docker.
- **Sudo / interactive subprocess helper**: `sudo-helper` skill + `/sudo`
  command explaining the multi-layer TTY chain and the supported escape
  hatches (`--allow-dangerously-skip-permissions`, `SUDO_ASKPASS`,
  pre-authorized cache).
- **Auto-approve guidance**: `/auto-approve` slash command + companion skill
  documenting OpenCode-AnyCLI's session-scoped permission model. The slash
  command intentionally cannot mutate a live session — it only explains how to
  relaunch.
- **Subagents**: `orchestrator` (planner / router) and `oracle` (read-only
  second opinion), adapted from `alvinunreal/oh-my-opencode-slim` (MIT) with
  multi-provider machinery and MCP dependencies stripped.
- **Coding-language-specific skills**: replaced the previous generic workflow
  skill set with C/C++ (`cpp-modernize`, `cpp-static-analysis`,
  `cmake-review`), Rust (`rust-clippy-triage`, `rust-unsafe-review`,
  `rust-idiom-modernize`), and C# (`csharp-nullable-migrate`,
  `csharp-async-modernize`, `csharp-analyzer-fix`).
- **Karpathy guidelines** skill: behavioral checklist to reduce common LLM
  coding mistakes, adapted from `forrestchang/andrej-karpathy-skills` (MIT).

### Changed

- README split off `Auto-approve (Yolo Mode)` and `Update` sections so the
  permission story and the upgrade flow are each documented exactly once.
- Docker / sudo-related guidance throughout the docs now points at
  `opencode-anycli --allow-dangerously-skip-permissions` as the canonical
  escape hatch.

## [0.2.0] — 2026-05-03

### Renamed

- Project: `oh-my-clinecli` → `oh-my-anycli`.
- CLI binary: `omc` → `omac`. The install symlink, doctor output, and
  `manifest.txt` location all moved accordingly.

### Fixed

- Removed a raw ANSI color-escape leak that surfaced when `omac list` was piped
  to a non-TTY.

## [0.1.0] — 2026-05-02 — initial release

### Added

- 14 workflow skills covering review, testing, refactor, security, dead code,
  log auditing, branch prep, PR description writing, README bootstrap, code
  explanation, and error diagnosis.
- DevOps / CI skills: `dockerfile-review`, `ci-config-validator`,
  `shell-script-review`.
- Database skills: `migration-writer`, `sql-explain-reader`.
- API / schema skills: `openapi-validator`, `api-changelog`.
- Slash commands: `/review`, `/test`, `/refactor`, `/commit`, `/omac-status`,
  `/coverage`, `/branch-prep`, `/pr-desc`, `/readme`, `/explain`,
  `/diagnose`, `/lint-fix`, `/security-scan`, `/dead-code`, `/log-audit`,
  `/todo`, `/migration`, `/sql-explain`, `/openapi`, `/api-diff`,
  `/dockerfile-review`, `/ci-config`, `/shell-review`, `/test-int`.
- Subagents pinned to `model: cline/default`: `architect`, `code-reviewer`,
  `dba`, `debugger`, `devops-engineer`, `doc-explainer`, `doc-writer`,
  `release-manager`, `security-auditor`, `test-writer`.
- `omac` Bash CLI: `help`, `version`, `list [-v]`, `search`, `info`,
  `skill list`, `command list`, `agent list`, `plugin list / add / remove`,
  `update [--prune]`, `reapply`, `doctor`.
- Lifecycle scripts: `install.sh` (idempotent + manifest-tracked),
  `update.sh` (`git pull --ff-only` + reapply), `uninstall.sh`
  (manifest-based safe removal), `doctor.sh` (installation health).
- Lint test scripts: `tests/lint-skills.sh`, `tests/lint-commands.sh`,
  `tests/lint-agents.sh`, `tests/verify-install.sh`.
- 8 documentation guides: `installation`, `skill-authoring`,
  `command-authoring`, `agent-authoring`, `plugin-authoring`,
  `team-deployment`, `update-flow`, `architecture`,
  plus `troubleshooting`.
- Plugin slot with prefixed install layout (`<plugin>__<artifact>`) and an
  `examples/hello-world` minimal plugin.

### Notes for upgraders

```bash
cd ~/.oh-my-anycli && git pull
omac reapply
```

`omac doctor` reports the new install state.
