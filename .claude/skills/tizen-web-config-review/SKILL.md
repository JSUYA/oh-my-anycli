---
name: tizen-web-config-review
description: Use this skill when reviewing Tizen Web app config.xml, privileges, features, content security policy, TV settings, or launch configuration.
---

# Tizen Web Config Review

Use this workflow for Tizen Web app `config.xml` review, especially privileges, features, CSP, icons, content entry, TV profile settings, and store readiness issues.

## Review scope

- `config.xml`
- Web entry files such as `index.html`
- `tizen-manifest.xml` or generated metadata when present
- Existing build scripts that transform or generate config files

## Review checklist

- `widget` id, version, viewmodes, and namespace are valid.
- `content src` points to an existing entry file.
- App name, labels, descriptions, and icons are present for required locales.
- Icon paths exist and match expected sizes for the target profile.
- `tizen:application` id, package, required_version, and launch mode are appropriate.
- `tizen:profile` matches the target such as `tv`, `mobile`, or `wearable`.
- `tizen:privilege` entries are minimal and justified.
- `feature` entries match actual APIs and target devices.
- `access` origins are as narrow as possible.
- CSP is present when needed and avoids unnecessary wildcards.
- TV-specific metadata, background support, and remote-control expectations are documented.

## Security guidance

- Do not add broad privileges to silence errors.
- Do not add `*` access or permissive CSP unless the user explicitly accepts the risk.
- Prefer least-privilege changes tied to the APIs used in code.
- Check source usage before adding a privilege or feature.

## Diagnosis approach

1. Read `config.xml` and relevant source files.
2. Search for Tizen API usage such as `tizen.`, `webapis.`, network, filesystem, media, billing, or TV input APIs.
3. Map API usage to required privileges/features.
4. Recommend minimal config changes with file references.
5. Validate XML structure after edits when possible.
