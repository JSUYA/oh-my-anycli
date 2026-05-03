---
name: flutter-tizen-setup
description: Use this skill when checking Flutter SDK, flutter-tizen extension, Tizen Studio CLI, and sdb environment readiness for flutter-tizen projects.
---

# Flutter Tizen Setup

Use this workflow when preparing or diagnosing a `flutter-tizen` development environment, including Flutter SDK, flutter-tizen extension, Tizen Studio CLI, and `sdb` setup.

## First checks

- Identify project type from files such as `pubspec.yaml`, `tizen/`, `.metadata`, `analysis_options.yaml`, or existing scripts.
- Prefer repository scripts and documented setup commands before inventing new commands.
- Check installed tools before suggesting installation.
- Do not modify SDK paths, shell profiles, or global configuration unless the user explicitly asks.
- Do not log or expose certificate passwords, tokens, or private keys.

## Environment checks

```bash
flutter --version
```

```bash
flutter-tizen --version
```

```bash
flutter-tizen doctor
```

```bash
tizen version
```

```bash
sdb version
```

## Setup diagnosis checklist

- Flutter SDK is installed and on `PATH`.
- flutter-tizen extension is installed and on `PATH`.
- Tizen Studio CLI tools are installed and on `PATH`.
- `sdb` is available and can list devices or emulators.
- The selected Flutter channel and Dart SDK are compatible with the project.
- `pubspec.yaml` dependencies are resolved with `flutter-tizen pub get` or project scripts.
- Tizen SDK profile and platform versions match the target device.

## Safe remediation order

1. Read project setup documentation and scripts.
2. Run version and doctor commands.
3. Inspect `pubspec.yaml` and `tizen/` configuration.
4. Report missing tools or path issues clearly.
5. Ask before installing SDKs, changing shell profiles, or modifying global config.
