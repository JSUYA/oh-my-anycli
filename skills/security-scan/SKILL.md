---
name: security-scan
description: Local security scan covering hardcoded secrets, unsafe code patterns, and risky dependency names using regex patterns and an optional user-maintained rule file.
version: 1.0.0
when_to_use: User asks "/security-scan", "any secrets in this repo?", or wants a quick local audit before pushing.
inputs:
  - name: target
    description: Optional path (file or directory) to scan. Defaults to the project root.
required_tools: [bash, read, grep]
---

# Security Scan Skill

## Goal

Run a local-only security sweep for hardcoded secrets, risky code patterns, and
suspicious dependency names.

## Workflow

1. Resolve scope from the user or default to the current repository. Prefer the
   staged diff or branch diff for pre-push checks.
2. Run local pattern searches only. Useful baseline patterns:
   - secrets: `AKIA[0-9A-Z]{16}`, `github_pat_`, `ghp_`, `glpat-`, private key
     headers, JWT-shaped strings, `password|secret|token|api_key` assignments;
   - unsafe execution: `eval`, `exec`, `Function(`, `child_process.exec`,
     `shell=True`, `pickle.loads`, unsafe `yaml.load`;
   - injection patterns: SQL string concatenation, shell command interpolation,
     path joins with unchecked user input;
   - weak crypto: MD5, SHA1, DES, ECB, hard-coded IVs;
   - dependency names that look misspelled or source-routed unexpectedly.
3. Classify findings:
   - HIGH: likely real secret or exploitable sink in production path;
   - MEDIUM: risky pattern needing context;
   - LOW: suspicious dependency/config or weak signal;
   - FALSE-POSITIVE: test fixture, sample token, or documented dummy value.
4. Mask secret values in output. Show enough prefix/type/path to identify the
   item without copying the full secret.
5. Recommend remediation steps but do not rotate secrets or rewrite history.

## Output Format

```markdown
### Security scan
Scope: staged diff

#### HIGH
- `.env:3`: AWS access key format match `AKIA************`.
  fix: rotate the key, remove it from history, move to a secret manager.

#### MEDIUM
- `src/report.py:42`: `subprocess.run(..., shell=True)` with user input.
  fix: pass an argument list and validate allowed commands.

#### Likely false positives
- `tests/fixtures/jwt.txt`: fixture token, not a live credential.
```

## Guardrails

- Do not upload code, lockfiles, or suspected secrets to external services.
- Do not print full secret values.
- Do not auto-edit files, rotate credentials, or rewrite Git history.
- Do not invent CVE IDs or vulnerability database results.
