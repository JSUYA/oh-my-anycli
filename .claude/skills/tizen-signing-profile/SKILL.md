---
name: tizen-signing-profile
description: Use this skill when diagnosing Tizen certificate, author/distributor profile, signing, or security profile failures.
---

# Tizen Signing Profile

Use this workflow for Tizen certificate, signing profile, author certificate, distributor certificate, and package signing failures.

## Safety rules

- Never print, copy, commit, or expose certificate passwords, private keys, `.p12` secrets, or credential files.
- Do not create, overwrite, or remove certificates unless the user explicitly asks.
- Mask sensitive paths and profile names if output may include secrets.
- Prefer read-only inspection commands first.

## First checks

- Verify Tizen CLI availability with `tizen version` or `tizen help`.
- Inspect project package type: `.wgt` usually uses web signing, `.tpk` uses native/.NET signing.
- Check whether the command specifies `-s <profile-name>` or relies on a default profile.
- Look for signing-related errors in full build/package logs before changing configuration.

## Useful commands

```bash
tizen security-profiles list
```

```bash
tizen certificate --help
```

```bash
tizen package --help
```

## Diagnosis checklist

- Requested signing profile does not exist.
- Author certificate is missing, expired, revoked, or password-protected incorrectly.
- Distributor certificate does not match target device, emulator, or store requirements.
- Profile path differs between shell, IDE, CI, and SDK installation.
- Package command omits `-s <profile-name>` when no default profile is configured.
- Device install fails because distributor certificate does not allow the target device DUID.

## Fix approach

1. Identify the failing profile name and package type.
2. Confirm profile existence using read-only listing.
3. Compare CLI command, IDE profile selection, and CI environment variables.
4. Recommend exact next command only after the expected profile is known.
5. If certificate creation is required, ask for confirmation before running any generating command.
