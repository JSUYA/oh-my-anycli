---
name: log-level-auditor
description: Finds inappropriate logging in source code — `console.log` in production JS, `print()` in non-test Python, `fmt.Println` in non-main Go, `dbg!` in Rust, `puts` in Ruby app code. Distinguishes test files (allowed) and suggests replacement with the project's logger if one is detected.
version: 1.0.0
when_to_use: User asks "/log-audit", "any console.log left", "what print statements still in the codebase". Useful before a release or after picking up an unfamiliar repository where prior debugging code may have leaked.
inputs:
  - name: target
    description: Optional file or directory to scope the scan to. Defaults to the project root.
required_tools: [bash, read, grep]
---

# Log Level Auditor Skill

## Goal

Find debug or inappropriate logging statements and recommend fixes that match
the project's logging conventions.

## Workflow

1. Resolve scope from the user or default to source directories. Skip generated,
   vendor, build output, and lockfiles.
2. Detect the project logger by grepping for imports/usages such as `logger`,
   `log`, `winston`, `pino`, `tracing`, `logrus`, `zap`, `ILogger`, or language
   standard logging packages.
3. Search for suspicious logging:
   - JavaScript/TypeScript: `console.log`, `console.debug`, `debugger`;
   - Python: `print(` outside scripts/tests;
   - Go: `fmt.Println`, `log.Println` in libraries;
   - Rust: `dbg!`, `println!` in non-CLI code;
   - Ruby: `puts`, `p`;
   - C/C++: `printf`, `std::cout` in library/runtime code.
4. Classify:
   - HIGH: logs secrets, tokens, passwords, PII, request bodies, or credentials;
   - MEDIUM: debug logs in production path or noisy loops;
   - LOW: style mismatch where project logger is available.
5. Recommend removal or replacement with the detected logger and an appropriate
   level (`debug`, `info`, `warn`, `error`).

## Output Format

```markdown
### Log audit

#### HIGH
- `src/auth.ts:42`: logs `Authorization` header.
  fix: remove the value or log only request id.

#### MEDIUM
- `src/worker.ts:88`: `console.log` inside hot loop; use `logger.debug` behind
  existing sampling or remove.
```

## Guardrails

- Do not flag CLI output, tests, examples, or one-off scripts as production
  logging unless the project treats them as production code.
- Do not remove logs automatically.
- Do not recommend a new logging library when one already exists.
