---
name: flutter-tizen-plugin-porting
description: Use this skill when porting Android or iOS Flutter plugins to flutter-tizen, reviewing MethodChannel, EventChannel, FFI, native Tizen API mapping, or plugin registration structure.
---

# Flutter Tizen Plugin Porting

Use this workflow when adapting an existing Flutter plugin for Tizen or reviewing a flutter-tizen plugin implementation.

## First checks

- Identify plugin type from `pubspec.yaml`, `platforms`, `android/`, `ios/`, `linux/`, and `tizen/` directories.
- Inspect existing Android/iOS channel names, method names, event streams, codecs, and error contracts before changing Tizen code.
- Prefer the plugin's existing public Dart API; do not introduce breaking API changes unless requested.
- Check whether Tizen support should use MethodChannel, EventChannel, FFI, or a pure Dart fallback.
- Do not add broad privileges or native permissions without matching Tizen API usage.

## Porting workflow

1. Map the Dart API to existing platform implementations.
2. Identify native APIs used by Android/iOS and find Tizen equivalents or unsupported gaps.
3. Create or review `tizen/` plugin files, registration, CMake, and manifest/config entries.
4. Preserve channel names, argument shapes, return types, and error codes where possible.
5. Add feature detection or clear unsupported errors for APIs unavailable on Tizen.
6. Validate with analyzer, unit tests, and the smallest feasible device or emulator smoke test.

## Review checklist

- `pubspec.yaml` declares the Tizen plugin platform correctly.
- Tizen plugin registration matches flutter-tizen conventions.
- MethodChannel and EventChannel names are identical to the Dart side.
- Native result/error handling is deterministic and does not hang pending calls.
- Threading and lifecycle behavior are safe for app suspend, resume, and dispose.
- CMake or native build configuration uses project-local sources and expected Tizen SDK paths.
- Required Tizen privileges and features are minimal and documented.
- Unsupported APIs fail explicitly rather than silently returning incorrect values.

## Diagnosis checklist

- `MissingPluginException` from registration or channel name mismatch.
- Native build failure from CMake, include path, library, or SDK profile mismatch.
- Runtime failure from missing privilege, unsupported device API, or unavailable service.
- Event stream leak from not unregistering listeners.
- Crash from invalid argument conversion or native pointer lifecycle.

## Safe changes

- Keep Dart API compatibility first.
- Add Tizen-specific implementation files under `tizen/` only when possible.
- Prefer small platform guards over broad refactors.
- Redact device identifiers and avoid logging user data from native APIs.
