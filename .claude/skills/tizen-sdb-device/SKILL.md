---
name: tizen-sdb-device
description: Use this skill when working with Tizen sdb devices, install/run workflows, device connection issues, or collecting device logs.
---

# Tizen SDB Device

Use this workflow for `sdb devices`, emulator/device connection, app install, app launch, uninstall, and log collection tasks.

## Safety rules

- Do not uninstall apps, reboot devices, reset devices, or change device settings unless the user explicitly asks.
- Do not collect broad logs containing private user data unless necessary; prefer filtered logs.
- Never expose device identifiers unnecessarily in shared output.

## First checks

- Verify `sdb` exists with `sdb version` or `which sdb`.
- Check connected targets with `sdb devices`.
- If multiple devices are connected, use `-s <serial>` and ask the user which target to use if unclear.
- Confirm the package id before install/run/uninstall commands.

## Common commands

```bash
sdb devices
```

```bash
sdb -s <serial> install <package.wgt-or.tpk>
```

```bash
sdb -s <serial> shell 0 debug <package-id>
```

```bash
sdb -s <serial> dlog
```

```bash
sdb -s <serial> dlog | grep -i '<package-id-or-tag>'
```

## Connection diagnosis checklist

- Device and host are on the same network for remote targets.
- Developer mode is enabled on TV or device when required.
- Target IP and port are correct.
- `sdb kill-server` / `sdb start-server` may help stale server state, but explain before running.
- USB permissions or udev rules may be missing on Linux.
- Emulator is fully booted before install/run.

## Install/run diagnosis checklist

- Package signature matches target device or emulator.
- Package id and application id are correct.
- Target platform version supports the package profile.
- App is already installed with a conflicting version or signature.
- Required privileges or features are unsupported on the target.
