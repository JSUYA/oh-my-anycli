---
name: flutter-tizen-build-package
description: Use this skill when building flutter-tizen TPK packages, diagnosing flutter-tizen build tpk failures, or validating profile-specific outputs and build logs.
---

# Flutter Tizen Build and Package

Use this workflow for `flutter-tizen build tpk`, profile-specific packaging, build output validation, and build log diagnosis.

## First checks

- Identify the project root from `pubspec.yaml` and the `tizen/` directory.
- Prefer project scripts, CI commands, or documented commands before running raw build commands.
- Run dependency resolution before builds only when needed or documented.
- Do not clean build outputs unless the user asks or the project script already does so.
- Do not change signing profiles or certificates unless the user explicitly asks.

## Build workflow

1. Inspect `pubspec.yaml`, `tizen/`, and existing build scripts.
2. Confirm tool readiness with `flutter-tizen --version` or `flutter-tizen doctor` when needed.
3. Run the smallest relevant build command for the target profile.
4. Capture full error output for failed builds.
5. Validate generated `.tpk` artifacts by timestamp, size, and output path.

## Common commands

```bash
flutter-tizen pub get
```

```bash
flutter-tizen build tpk
```

```bash
flutter-tizen build tpk --debug
```

```bash
flutter-tizen build tpk --profile
```

```bash
flutter-tizen build tpk --release
```

## Log diagnosis checklist

- Missing or invalid Tizen signing profile.
- Missing `tizen/` platform files or invalid Tizen manifest/config.
- Flutter dependency or generated plugin registrant failure.
- Native Tizen plugin build failure.
- Target profile, SDK version, or architecture mismatch.
- Asset, icon, label, or privilege validation failure.

## Output validation

- Confirm `.tpk` exists under the expected build output directory.
- Check artifact timestamp and size.
- Prefer non-destructive archive inspection for package contents.
- Do not unpack, rewrite, or resign packages unless required for diagnosis.
