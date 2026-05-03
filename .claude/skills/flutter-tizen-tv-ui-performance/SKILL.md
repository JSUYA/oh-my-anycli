---
name: flutter-tizen-tv-ui-performance
description: Use this skill when reviewing flutter-tizen TV UI behavior, remote key handling, focus navigation, resolution scaling, rendering performance, frame pacing, or device-specific TV issues.
---

# Flutter Tizen TV UI Performance

Use this workflow for flutter-tizen TV apps where remote input, focus traversal, large-screen layout, rendering performance, startup, or device-specific behavior matters.

## First checks

- Identify target profile and device class from `tizen/`, project docs, and build scripts.
- Confirm whether the issue is layout, focus, remote input, rendering performance, startup, memory, or device-only behavior.
- Prefer existing test pages, debug overlays, and project profiling scripts before adding new tooling.
- Do not install profiling tools, change device settings, or collect broad logs unless needed and approved.
- Avoid testing TV-specific remote behavior only on desktop or host browsers.

## TV UI checklist

- Focusable widgets have deterministic initial focus and traversal order.
- Remote keys such as arrows, Enter, Back, Play/Pause, and color keys are handled intentionally.
- Back navigation behavior matches TV expectations and does not trap the user.
- Overscan, safe area, and large-screen spacing are considered.
- Text remains readable at target resolutions and viewing distance.
- Loading, empty, error, and offline states are navigable by remote.
- Animations do not break focus visibility or cause accidental repeated input.

## Performance checklist

- Startup path avoids unnecessary synchronous work before first frame.
- Image assets are sized appropriately for TV resolutions.
- Large lists use lazy rendering and stable keys.
- Rebuild scope is limited for focus movement and frequent remote input.
- Expensive effects, shaders, opacity layers, and clips are measured on target hardware.
- Logs distinguish Flutter framework, engine, plugin, and Tizen platform errors.
- Performance conclusions are based on target device or emulator data, not host assumptions.

## Useful commands

```bash
flutter-tizen run -d <device-id> --profile
```

```bash
sdb -s <serial> dlog
```

```bash
sdb -s <serial> dlog | grep -i '<package-id-or-flutter-tag>'
```

## Diagnosis workflow

1. Reproduce on the intended TV, emulator, or closest available profile.
2. Capture exact device model/profile, build mode, and route or screen.
3. Separate input/focus bugs from frame rendering or native platform issues.
4. Inspect Flutter widget rebuild hotspots and asset usage before native changes.
5. Validate fixes with remote-only navigation and a profile-mode smoke test.
