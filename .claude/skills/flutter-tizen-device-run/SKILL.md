---
name: flutter-tizen-device-run
description: Use this skill when running flutter-tizen apps on devices or emulators, diagnosing flutter-tizen devices, install, run, logs, TV, or emulator issues.
---

# Flutter Tizen Device Run

Use this workflow for `flutter-tizen devices`, install/run workflows, `sdb` device connection, emulator or TV execution, and runtime log diagnosis.

## First checks

- Identify whether the target is emulator, TV, wearable, or another Tizen device.
- Prefer project scripts and documented run commands before inventing commands.
- Check device connectivity before rebuilding.
- Do not reset devices, uninstall apps, or change device settings unless the user asks.
- Do not expose device identifiers unnecessarily in shared output.

## Device checks

```bash
flutter-tizen devices
```

```bash
sdb devices
```

```bash
sdb get-state
```

## Run workflow

1. Confirm device or emulator is visible.
2. Confirm the project builds for the target profile.
3. Run with the smallest relevant command.
4. Capture runtime logs when install or launch fails.
5. Diagnose connection, signing, privilege, and profile mismatches before changing code.

## Common commands

```bash
flutter-tizen run
```

```bash
flutter-tizen run -d <device-id>
```

```bash
sdb dlog
```

```bash
sdb shell 0 debug <package-id>
```

## Diagnosis checklist

- Device is authorized, online, and reachable by `sdb`.
- Target profile matches the connected device.
- Package is signed with a compatible certificate profile.
- App privileges and features match runtime requirements.
- TV remote key and focus behavior are tested on target hardware when relevant.
- Runtime logs are checked for Flutter engine, plugin, and Tizen platform errors.
