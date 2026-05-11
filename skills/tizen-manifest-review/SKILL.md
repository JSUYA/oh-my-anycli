---
name: tizen-manifest-review
description: Reviews tizen-manifest.xml for API version vs target profile, required vs optional features, package id format, ui-application vs service-application choice, and category/metadata correctness, refusing privilege removal without auditing actual API usage.
version: 1.0.0
when_to_use: User invokes "/tizen-manifest", asks to "review the Tizen manifest", or wants a sanity check before signing/packaging a TPK/WGT.
inputs:
  - name: target
    description: Optional path to tizen-manifest.xml or a project directory containing one. Defaults to the manifest at the project root.
required_tools: [bash, read]
---

# Tizen Manifest Review Skill

## Goal

Read `tizen-manifest.xml` and report findings against a checklist covering: API/profile compatibility, application type choice, package identifier format, privileges sanity, features/categories/metadata, and signing prerequisites. The skill never edits the manifest; it only reports.

## Boundary

Use this skill for manifest structure and metadata correctness. Use
`tizen-privilege-audit` to compare declared privileges against source API usage,
and `tizen-api-modernize` to find deprecated native APIs. This skill may point
to those follow-up checks but should not remove privileges or scan all source
APIs itself.

## Inputs

- `target`: a path to `tizen-manifest.xml` or a directory containing one.

## Steps

1. Locate the manifest.
   ```bash
   find . -maxdepth 4 -name 'tizen-manifest.xml' -not -path '*/.build*/*' -not -path '*/Debug/*' -not -path '*/Release/*'
   ```

2. Parse the manifest with simple grep + read (do not require xmllint).
   ```bash
   grep -nE '<manifest|<ui-application|<service-application|<widget-application|<watch-application|<privilege|<feature|<metadata|<category|<icon|<label|<background-category|<account|<datacontrol|<provides-appdefined-privilege|<trust-anchor|<profile' tizen-manifest.xml
   ```

3. Run the checklist. Each finding gets a severity (HIGH / MEDIUM / LOW), file:line, and rationale.

   ### A. Root attributes (HIGH)
   The `<manifest>` element should declare:
   - `xmlns="http://tizen.org/ns/packages"` — required.
   - `api-version="x.y"` — minimum platform API the package targets. Common values: `4.0`, `5.5`, `6.0`, `7.0`, `8.0`. Pick the lowest that supports every API the app uses; higher values exclude older devices.
   - `package="<vendor>.<appname>"` — reverse-DNS-like; lowercase letters, digits, dots; must match the signing certificate's package id field.
   - `version="x.y.z"` — semver-ish; bumped on every release.
   - `install-location="auto"` (or `internal-only` / `prefer-external` for content-heavy apps).

   Profile-specific:
   - Wearable apps and apps targeting watch/wearable should declare `<profile name="wearable"/>` (or `mobile`, `tv`, `iot-headed`, `iot-headless`).
   - For a multi-profile package, declare each profile separately or use a build-time switch in the project.

   ### B. Application element choice (HIGH)
   Exactly one application element is the primary entry; multiple may coexist:
   - `<ui-application>` for foreground apps with a window.
   - `<service-application>` for background services without UI (long-running, started by other apps or system events).
   - `<widget-application>` for widgets shown on the home screen.
   - `<watch-application>` for watch faces.

   Required attributes on the application element:
   - `appid="<vendor>.<appname>.<component>"` — must start with the package id; uppercase letters allowed in the component segment.
   - `exec="<binary-name>"` — for native, the ELF binary; for .NET (Tizen.NET), the assembly DLL name without extension.
   - `type="capp" | "dotnet" | "webapp"` — must match the actual project type. `capp` is native; `dotnet` is .NET / Tizen.NET; `webapp` is HTML5/WAT.
   - `multiple="false"` (default) or `"true"` if multiple instances are allowed.
   - `nodisplay="false"` for ui-applications that show a launcher icon.
   - `taskmanage="true"` for ui-applications that appear in the recent-apps list.

   Common findings:
   - `appid` does not start with the `package` value (HIGH).
   - `exec` references a binary that does not exist at expected paths (`bin/<exec>` for native, `bin/<exec>.dll` for dotnet).
   - `type="capp"` on a project that builds with `dotnet build` (HIGH — runtime failure).

   ### C. Privileges (HIGH for missing, MEDIUM for unused)
   Privileges live inside `<privileges>`:
   ```xml
   <privileges>
     <privilege>http://tizen.org/privilege/internet</privilege>
     <privilege>http://tizen.org/privilege/location</privilege>
   </privileges>
   ```
   - Format: full URI, no trailing slash, lowercase.
   - Privacy-related privileges (location, camera, recorder, contact.read/write, calendar.read/write, message.read/write, callhistory.read/write, mediastorage, externalstorage, healthinfo, account.read/write) require user opt-in at runtime.
   - Partner / platform privileges (e.g., `partner/...`) require corresponding signing certificate level; will fail at install if signed only with public certs.

   This skill's policy: **never recommend removing a privilege**. Apparent unused privileges may be required by libraries, by future code paths, or by reflection-based .NET APIs. Removal causes runtime `ENOACCESS` / `PRIVILEGE_DENIED` failures that are hard to diagnose. Cross-checking belongs in the `tizen-privilege-audit` skill, which reports findings rather than auto-removes.

   ### D. Features (MEDIUM)
   Features inside `<feature name="...">true|false</feature>` declare device hardware/capability requirements. Device store filters apps by features; declaring more than the app actually needs reduces the install base unnecessarily.
   Common features: `http://tizen.org/feature/network.internet`, `http://tizen.org/feature/network.bluetooth`, `http://tizen.org/feature/sensor.accelerometer`, `http://tizen.org/feature/sensor.gyroscope`, `http://tizen.org/feature/camera`, `http://tizen.org/feature/location`, `http://tizen.org/feature/screen.shape.circle`, `http://tizen.org/feature/screen.size.normal.360.360`.
   - Each feature with value `true` is a hard requirement.
   - Features should mirror privileges where applicable (e.g., declaring privilege `internet` should usually be paired with feature `network.internet`, unless internet is purely optional).

   ### E. Categories (MEDIUM)
   `<category name="..."/>` inside the application element. Examples:
   - `http://tizen.org/category/wearable_clock` — required for watch faces.
   - `http://tizen.org/category/ime` — for input method editors.
   - `http://tizen.org/category/homeapp` — home screen apps.
   - `http://tizen.org/category/lockapp` — lock-screen apps.
   - `http://tizen.org/category/widget_size/2x2` (and `1x1`, `2x1`, `4x1`, `4x2`) — for widget applications.
   - Wearable watch face missing `wearable_clock` will install but not show in the watch face picker (HIGH).

   ### F. Metadata (LOW)
   `<metadata key="..." value="..."/>` for app-specific flags read at runtime via `app_get_metadata` (or `Application.Current.Properties` in .NET). Common keys are vendor-prefixed URIs (e.g., `<vendor-domain>/<app>/metadata/<key>`).
   Findings: keys missing the URI scheme; duplicate keys.

   ### G. Icons and labels (LOW)
   - `<icon>app.png</icon>` — file under `shared/res/` (or platform-default path).
   - `<label>App Name</label>` — locale variants via `<label xml:lang="ko-kr">Localized App Name</label>`.

   ### H. Account, data control, app-defined privileges (MEDIUM)
   - `<account>...</account>` requires the `account.read` / `account.write` privileges and registers the app as an account provider.
   - `<datacontrol>...</datacontrol>` registers a data-control provider URI; mismatched provider IDs cause silent failures.
   - `<provides-appdefined-privilege>...</provides-appdefined-privilege>` — app-defined privileges (Tizen 5.5+); paired with the consumer's `<privilege>` of the same URI.

   ### I. Background categories (MEDIUM)
   For service-applications and ui-applications that need background execution:
   ```xml
   <background-category value="media"/>
   <background-category value="location"/>
   ```
   Without a background category, the app will be suspended quickly when not in the foreground (Tizen 4.0+ background policy). Categories include: `media`, `download`, `background-network`, `location`, `iot-communication`, `sensor`, `system`.

4. Cross-cutting checks:
   - `api-version` lower than the highest API used by the app: detect `tizen.h`, `dotnet` SDK level, or web `tizen` namespace usage and flag mismatches.
   - Wearable manifest missing `screen.shape.circle` feature on a circle-only watch face design (HIGH).
   - `nodisplay="true"` on a ui-application that has no launcher → confirm intent.

## Output format

```markdown
### tizen-manifest-review report

Manifest: tizen-manifest.xml
api-version: 6.0 / package: org.example.foo / type: dotnet / profile: wearable

Findings (8):
- HIGH  L4   `package="org.example.Foo"` contains uppercase; must be all-lowercase
- HIGH  L18  `appid="org.example.Foo.MainApp"` does not start with `package` value `org.example.foo`
- MEDIUM L23 application element uses `type="capp"` but project builds via `dotnet`; expected `type="dotnet"`
- MEDIUM L31 privilege `http://tizen.org/privilege/healthinfo` declared but no <feature name="...health..."> declared; check device coverage
- MEDIUM L42 background execution required (uses LocationManager) but no <background-category value="location"/> present
- LOW   L55 metadata key `appConfigPath` missing URI scheme prefix
- LOW   L60 <icon>icon.png</icon> referenced but file not found at shared/res/icon.png
- HIGH  L70 wearable watch app missing <category name="http://tizen.org/category/wearable_clock"/>
```

## Anti-patterns

- Do not remove privileges from the manifest. This skill is read-only on privileges; cross-checking against API usage is the job of the `tizen-privilege-audit` skill.
- Do not bump `api-version` to silence build warnings; that excludes older devices and may fail certification for the original target list.
- Do not invent privilege URIs (e.g., `http://tizen.org/privilege/somename`); only the documented set is valid.
- Do not recommend `<install-location>prefer-external</install-location>` for apps that read tightly-coupled assets; SD card removal would crash the app.
- Do not add `nodisplay="true"` to a ui-application "to hide it from the launcher" without explaining that it remains in the recent-apps list and may still show on system dialogs.
- Do not change `multiple="false"` to `"true"` without confirming the app is multi-instance-safe (singletons, file locks, named ports).
- Do not recommend collapsing duplicate `<label>` entries; they may legitimately differ by `xml:lang` locale.
- Do not add features unless the app actually requires them; over-declaration reduces device coverage.
- Do not remove a `<background-category>` because the app "no longer needs background"; the category gate is enforced at install, not at runtime, and removing it requires a coordinated app-side change.
- Do not assume `xmlns` can be omitted; the manifest schema validator rejects manifests without the namespace.
- Do not propose adding partner-level privileges (e.g., `partner/sso`); the package will fail to install with public-level signing certificates.
- Do not flag a missing `<icon>` as HIGH if the project uses the platform's default icon mechanism (rare but legitimate for some service apps).
- Do not validate the manifest against an upstream XSD downloaded from the internet; rely on the local SDK's schema or the documented rules.
- Do not recommend `xml:space="preserve"` on labels; the manifest tooling normalizes whitespace anyway.
- Do not edit the `<author>` field automatically; that is a signing-related identity and must match the certificate.
