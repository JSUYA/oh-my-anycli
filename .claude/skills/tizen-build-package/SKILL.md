---
name: tizen-build-package
description: Use this skill when building or packaging Tizen projects, diagnosing tizen build/package failures, or validating .wgt/.tpk outputs and build logs.
---

# Tizen Build and Package

Use this workflow for Tizen Web, Native, or .NET app build/package tasks involving `tizen build`, `tizen package`, `.wgt`, `.tpk`, or build log diagnosis.

## First checks

- Identify the project type from files such as `config.xml`, `.project`, `.tproject`, `manifest.xml`, `.csproj`, `package.json`, `CMakeLists.txt`, or existing scripts.
- Prefer repository scripts and documented commands before inventing new commands.
- Verify the Tizen CLI is available with `tizen version` or `tizen help`.
- Do not install or modify SDK components unless the user explicitly asks.
- Do not delete build outputs unless the user asks or the project script already does so.

## Build workflow

1. Inspect project configuration and existing build scripts.
2. Run the smallest relevant build command from the project root or documented workspace directory.
3. Capture full error output for failed builds.
4. Check profile, platform version, architecture, certificate, and dependency mismatch before changing files.
5. Confirm generated artifacts with `find` for `.wgt`, `.tpk`, `.rpm`, or project-specific output paths.

## Common commands

```bash
tizen build-web
```

```bash
tizen build-native
```

```bash
tizen build-dotnet
```

```bash
tizen package -t wgt -s <profile-name>
```

```bash
tizen package -t tpk -s <profile-name>
```

## Log diagnosis checklist

- Missing or invalid signing profile.
- Unsupported target profile, platform version, or architecture.
- Invalid `config.xml` or `manifest.xml` schema.
- Missing privileges, features, icons, labels, or entry points.
- Build tool path or SDK environment mismatch.
- Web app dependency failures from `npm`, bundlers, or generated assets.

## Output validation

- Verify the expected `.wgt` or `.tpk` exists.
- Check artifact timestamp and size.
- Prefer non-destructive archive inspection commands, such as `unzip -l`, for `.wgt` content checks.
- Do not unpack or rewrite packages unless needed for diagnosis.
