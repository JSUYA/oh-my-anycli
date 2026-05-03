---
name: tizen-certification-check
description: Use this skill for pre-submission Tizen certification checks covering icons, labels, privileges, background behavior, API usage, profiles, and package readiness.
---

# Tizen Certification Check

Use this workflow before Tizen store or device certification submission to review common rejection risks.

## Scope

- Package metadata and signing readiness.
- `config.xml` or `manifest.xml` correctness.
- Icon, label, localization, and version consistency.
- Privilege, feature, API, network, and background behavior.
- Device/profile compatibility.

## Checklist

- Package id, application id, version, and profile are consistent.
- App name, labels, descriptions, and localized resources are complete.
- Icons exist, are referenced correctly, and match required dimensions for target profile.
- Required privileges are declared and unnecessary privileges are removed.
- Required features match target devices and do not over-constrain compatibility.
- Network origins and CSP are not broader than required.
- Background, autostart, alarms, push, media, and sensor behavior are justified and documented.
- Tizen API usage matches declared privileges and supported platform version.
- Store-sensitive APIs such as billing, account, push, location, filesystem, and TV device APIs are reviewed carefully.
- Package builds reproducibly and signs with the intended distributor certificate.
- Install/run smoke test passes on the intended emulator or device.

## Review approach

1. Inspect metadata files and source API usage.
2. Compare declared privileges/features with actual code usage.
3. Verify referenced assets exist.
4. Build/package if requested or if required to validate readiness.
5. Report blockers, warnings, and recommended fixes separately.

## Do not

- Do not claim certification approval is guaranteed.
- Do not add privileges or features without evidence from code usage.
- Do not upload packages or submit to a store unless the user explicitly asks.
