---
name: flutter-tizen-signing
description: Use this skill when connecting flutter-tizen builds to Tizen certificate profiles or diagnosing signing, author, distributor, and certificate profile errors.
---

# Flutter Tizen Signing

Use this workflow for flutter-tizen signing profile setup, Tizen certificate profile linkage, and signing failures during `.tpk` builds or installs.

## First checks

- Identify the configured signing profile from project docs, CI config, or Tizen CLI settings.
- Check whether the failure is build-time signing, package validation, or device install rejection.
- Do not print certificate passwords, private key paths, or secret environment variables.
- Do not create, delete, or overwrite certificates unless the user explicitly asks.
- Prefer Tizen Studio Certificate Manager for interactive certificate changes when appropriate.

## Signing checks

```bash
tizen security-profiles list
```

```bash
tizen security-profiles get-active
```

```bash
flutter-tizen build tpk --release
```

## Diagnosis workflow

1. Capture the exact signing error from `flutter-tizen build tpk` or install logs.
2. Confirm the active Tizen security profile.
3. Check author and distributor certificate presence without exposing secrets.
4. Verify profile compatibility with the target device and store/distribution channel.
5. Re-run packaging only after profile selection or configuration is confirmed.

## Common failure checklist

- No active security profile.
- Missing author or distributor certificate.
- Expired, revoked, or incompatible certificate.
- Wrong distributor certificate for target device.
- Password prompt or locked keychain in non-interactive build.
- CI environment missing certificate files or secure variables.
- Package install rejected because the signing profile does not match the device policy.

## Safe handling

- Redact passwords, tokens, certificate aliases tied to secrets, and private key paths in shared logs.
- Ask before changing active profiles or importing certificates.
- Prefer documenting required variables and paths over embedding secrets in scripts.
