---
name: shell-script-review
description: Reviews bash/zsh scripts for safety basics — set -euo pipefail, quoted variable expansions, unsafe eval/source, missing -- before user args, race-prone temp files, and shellcheck-style issues we can grep for. Local file only.
version: 1.0.0
when_to_use: User asks "/shell-review", "review this script", or has just authored or modified a `.sh`/`.bash`/`.zsh` script. Useful before committing build/deploy scripts.
inputs:
  - name: script_path
    description: Path to the shell script to review. Required. Multiple paths may be passed space-separated.
required_tools: [bash, read, grep]
---

# Shell Script Review Skill

## Goal

Review shell scripts for safety, quoting, portability, and maintenance risks.

## Boundary

Use this skill for shell files and shell snippets when shell semantics are the
main risk. Use `ci-config-validator` for CI workflow structure and
`dockerfile-review` for Dockerfile layer/runtime concerns.

## Workflow

1. Resolve script paths from the user or changed files ending in `.sh`, `.bash`,
   or `.zsh`.
2. Identify the declared shell from the shebang. Do not apply Bash-only advice
   to a POSIX `sh` script unless you also recommend changing the shebang.
3. Run `shellcheck` if it is already installed. If not, perform manual checks.
4. Apply the checklist:
   - strict mode appropriate for the shell (`set -euo pipefail` for Bash);
   - quoted variable expansions and `"$@"`;
   - no parsing `ls`, unsafe word splitting, or glob surprises;
   - `--` before user-controlled filename arguments;
   - safe temp files (`mktemp`, traps) and cleanup;
   - no unsafe `eval`, untrusted `source`, command injection, or silent `curl |
     sh`;
   - portability issues: `readlink -f`, `sed -i`, `find -printf`, arrays, and
     Bash 4 features on macOS Bash 3.
5. Rank findings by runtime breakage/security risk first; style last.

## Output Format

```markdown
### Shell review

#### HIGH
- `install.sh:44`: unquoted `$target` can split paths with spaces.
  fix: use `"$target"`.

#### MEDIUM
- `tests/matrix.sh:80`: `declare -A` requires Bash 4; macOS ships Bash 3.
  fix: use a temp file or plain array.
```

## Guardrails

- Do not rewrite scripts from this review skill.
- Do not require Bash when the script intentionally targets POSIX `sh`.
- Do not suggest `set -e` blindly around commands where failure is intentionally
  handled.
