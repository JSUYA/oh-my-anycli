---
name: tizen-api-modernize
description: Detects deprecated Tizen native API usage in the touched files and reports the recommended replacement, required headers, and migration notes from a curated table embedded in this skill (no external network calls).
version: 1.0.0
when_to_use: User invokes "/tizen-api-modernize", asks to "find deprecated Tizen APIs", or wants a migration plan before bumping the package's api-version.
inputs:
  - name: target
    description: Optional path. Defaults to the C/C++ files changed on the current branch.
  - name: target_api
    description: Tizen API version to target (e.g., 7.0, 8.0). Defaults to the value in tizen-manifest.xml api-version attribute.
required_tools: [bash, read]
---

# Tizen API Modernize Skill

## Goal

Scan touched Tizen native source files for use of APIs that are deprecated as of the project's target Tizen API version. For each finding, report the deprecated function, the recommended replacement, the required header(s), and migration notes (signature changes, error-handling differences). The skill never edits source automatically; it produces a per-file migration plan.

## Inputs

- `target`: file/directory; default is changed `.c`/`.cpp`/`.h`/`.hpp` files on the branch.
- `target_api`: explicit override (e.g., `8.0`); otherwise the value from `<manifest api-version="...">`.

## Steps

1. Resolve target Tizen API version.
   ```bash
   grep -nE 'api-version' tizen-manifest.xml | head -1
   ```
   Default to `7.0` if no manifest exists. Findings are filtered to APIs deprecated at or before this version.

2. Resolve target files.
   ```bash
   git diff --name-only --diff-filter=ACMRT \
     $(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main) \
     -- '*.c' '*.cpp' '*.cc' '*.h' '*.hpp'
   ```

3. For each row in the curated deprecation table below, grep the changed files for the deprecated symbol and emit a finding.
   ```bash
   grep -nE '\b<deprecated_symbol>\s*\(' <files>
   ```

4. Emit per-file findings with: deprecated symbol → replacement, header changes, signature/semantic notes, deprecation version.

## Curated deprecation table

The table below is a curated subset of common Tizen native API deprecations. Symbols not in this table are not flagged by this skill; the user can add entries by editing this file. **Do not fetch updated tables from the internet at runtime.**

### Network: Wi-Fi (deprecated since 3.0; superseded by Wi-Fi Manager)

| Deprecated | Replacement | Header change |
|------------|-------------|---------------|
| `wifi_initialize()` | `wifi_manager_initialize()` | `<wifi.h>` → `<wifi-manager.h>` |
| `wifi_deinitialize()` | `wifi_manager_deinitialize()` | same |
| `wifi_activate()` | `wifi_manager_activate()` | same |
| `wifi_deactivate()` | `wifi_manager_deactivate()` | same |
| `wifi_connect()` | `wifi_manager_connect()` | same |
| `wifi_disconnect()` | `wifi_manager_disconnect()` | same |
| `wifi_is_activated()` | `wifi_manager_is_activated()` | same |
| `wifi_get_connection_state()` | `wifi_manager_get_connection_state()` | same |
| `wifi_foreach_found_aps()` | `wifi_manager_foreach_found_ap()` | same; callback enum types renamed `wifi_*_e` → `wifi_manager_*_e` |
| `wifi_scan()` | `wifi_manager_scan()` | same |

Migration notes: function pointer typedefs are renamed (`wifi_connection_state_changed_cb` → `wifi_manager_connection_state_changed_cb`); error codes (`WIFI_ERROR_*`) become `WIFI_MANAGER_ERROR_*`; both APIs share `tizen_error_e` base codes for `INVALID_PARAMETER`, `OUT_OF_MEMORY`, `PERMISSION_DENIED`.

### Multimedia: StreamRecorder (deprecated since 7.0)

| Deprecated | Replacement | Header change |
|------------|-------------|---------------|
| `streamrecorder_create()` | `recorder_create_videorecorder()` (capture from camera source) or use `media-stream-recorder` for raw stream input | `<streamrecorder.h>` → `<recorder.h>` |
| `streamrecorder_destroy()` | `recorder_destroy()` | same |
| `streamrecorder_prepare()` | `recorder_prepare()` | same |
| `streamrecorder_start()` | `recorder_start()` | same |
| `streamrecorder_pause()` | `recorder_pause()` | same |
| `streamrecorder_commit()` | `recorder_commit()` | same |
| `streamrecorder_cancel()` | `recorder_cancel()` | same |
| `streamrecorder_set_filename()` | `recorder_set_filename()` | same |
| `streamrecorder_set_audio_encoder()` | `recorder_set_audio_encoder()` | same |
| `streamrecorder_set_video_encoder()` | `recorder_set_video_encoder()` | same |

Migration notes: stream input via `streamrecorder_push_buffer` has no direct equivalent in `recorder`; for synthetic stream input, evaluate `media-pipeline` or `gstreamer` directly. Error type `streamrecorder_error_e` becomes `recorder_error_e`.

### Messaging: MMS (deprecated since 8.0)

| Deprecated | Replacement | Header change |
|------------|-------------|---------------|
| `messages_mms_set_subject()` | (no replacement; MMS support removed) | — |
| `messages_mms_get_subject()` | (no replacement) | — |
| `messages_mms_add_attachment()` | (no replacement) | — |
| `messages_mms_remove_all_attachments()` | (no replacement) | — |

Migration notes: MMS as a category is deprecated. Apps relying on MMS should migrate to network-based messaging (RCS, app-specific protocols). The `messages_*` APIs for SMS remain supported.

### Messaging: WAP Push (deprecated since 8.0)

| Deprecated | Replacement | Header change |
|------------|-------------|---------------|
| `messages_push_register()` | (no replacement; legacy WAP) | — |
| `messages_push_deregister()` | (no replacement) | — |
| `messages_push_re_register()` | (no replacement) | — |

Migration notes: WAP Push is obsolete; for app-level push, use `push-service` (`<push-service.h>`).

### Application: legacy app framework (deprecated since 2.4)

| Deprecated | Replacement | Header change |
|------------|-------------|---------------|
| `appcore_efl_main()` | `ui_app_main()` | `<appcore-efl.h>` → `<app.h>` |
| `service_create()` | `app_control_create()` | `<service.h>` → `<app_control.h>` |
| `service_send_launch_request()` | `app_control_send_launch_request()` | same |
| `service_set_app_id()` | `app_control_set_app_id()` | same |
| `service_set_operation()` | `app_control_set_operation()` | same |
| `service_add_extra_data()` | `app_control_add_extra_data()` | same |
| `service_destroy()` | `app_control_destroy()` | same |

Migration notes: the `service_h` handle becomes `app_control_h`; error codes `SERVICE_ERROR_*` become `APP_CONTROL_ERROR_*`. The `service` namespace also covered service-application lifecycle, which is now in `<service_app.h>` for the service-application companion.

### Bundle / IPC

| Deprecated | Replacement | Header change |
|------------|-------------|---------------|
| `bundle_dup()` (where the dup ownership semantics were ambiguous; legacy 2.x form) | `bundle_create()` + `bundle_iterate()` to copy entries explicitly, or `bundle_encode()` + `bundle_decode()` for serialization round-trip | `<bundle.h>` (no header change) |

Migration notes: prefer explicit decode/encode for cross-process bundle transfer; in-process duplication is rarely needed in current code.

### Storage

| Deprecated | Replacement | Header change |
|------------|-------------|---------------|
| `storage_get_root_directory()` (where used to derive media paths) | `storage_get_directory(storage_id, STORAGE_DIRECTORY_*, &path)` for typed sub-directories | `<storage.h>` (no header change) |
| Direct hardcoded paths under `/opt/usr/media/` | use `storage_get_directory(0, STORAGE_DIRECTORY_IMAGES, ...)` etc. | same |

Migration notes: hardcoded paths break on devices that mount media to different locations (SD card, external storage); always resolve via the storage API.

### Connectivity: legacy NFC

| Deprecated | Replacement | Header change |
|------------|-------------|---------------|
| `nfc_p2p_send()` (Tizen 4.0 deprecation track) | NFC SNEP/HCE APIs in `<nfc.h>` (`nfc_snep_*`, `nfc_hce_*`) | same |

Migration notes: P2P NFC was deprecated as the underlying Android Beam-style protocol was retired across the ecosystem.

### Telephony

| Deprecated | Replacement | Header change |
|------------|-------------|---------------|
| `tel_init()` (libtapi-style) | `telephony_init(&handle_list)` | `<tapi.h>` → `<telephony.h>` |
| `tel_get_call_status()` | `telephony_call_get_status(handle, &status)` | same |

Migration notes: the new telephony API uses an opaque handle list with per-SIM handles for dual-SIM devices; legacy single-handle code must select an explicit SIM index.

### Sensor

| Deprecated | Replacement | Header change |
|------------|-------------|---------------|
| `sensor_create()` (Tizen 2.x form) | `sensor_get_default_sensor()` + `sensor_create_listener()` | `<sensor.h>` (no header change) |
| `sensor_start()` | `sensor_listener_start()` | same |

Migration notes: the listener/sensor split lets multiple listeners share a sensor handle; check listener attributes (`SENSOR_OPTION_*`) to control wake/lock behavior.

### Player / MediaContent

| Deprecated | Replacement | Header change |
|------------|-------------|---------------|
| `player_set_video_stream_callback()` (legacy raw-frame path) | `player_set_media_packet_video_frame_decoded_cb()` | `<player.h>` (no header change) |
| `media_info_get_thumbnail_path()` synchronous form on slow storage | `thumbnail_util_extract()` (async) | add `<thumbnail_util.h>` |

Migration notes: synchronous thumbnail extraction has been deprecated due to UI-thread-blocking behavior; async API requires running an `Ecore_Main_Loop` (Wayland/EFL apps) or equivalent event loop.

### .NET (Tizen.NET / Xamarin.Forms / MAUI namespaces)

| Deprecated | Replacement |
|------------|-------------|
| `Tizen.Network.WiFi.WiFiManager` legacy event names (e.g., `Activated` event spelled with the older form) | current event names per Tizen.NET 7.0+ docs (`StateChanged`, `ConnectionStateChanged`) |
| `Tizen.Applications.Application` static singleton on multi-window TVs | per-window `CoreUIApplication` extension |
| `Xamarin.Forms.Platform.Tizen` initialization | `Microsoft.Maui.Controls.Compatibility.Platform.Tizen` (MAUI migration; .NET 6+) |

Migration notes: .NET Tizen API parity tracks the native API; check the Tizen.NET assembly version (`Tizen.NET` 7.0.x for API 7, 8.0.x for API 8) before swapping types.

## Output format

```markdown
### tizen-api-modernize report

target_api: 8.0 (from tizen-manifest.xml)
Files scanned: 7

#### src/network/wifi.c (3 findings)
- L42 wifi_initialize() → wifi_manager_initialize()
       header: replace `<wifi.h>` with `<wifi-manager.h>`
       error codes: WIFI_ERROR_* → WIFI_MANAGER_ERROR_*
       deprecated since: 3.0
- L88 wifi_connect(ap, callback, user_data) → wifi_manager_connect(handle, ap, callback, user_data)
       signature: now requires a manager handle from wifi_manager_initialize
- L155 wifi_foreach_found_aps() → wifi_manager_foreach_found_ap()
       callback typedef renamed: wifi_found_ap_cb → wifi_manager_found_ap_cb

#### src/recorder/stream.c (2 findings)
- L33 streamrecorder_create() → recorder_create_videorecorder() OR keep streamrecorder for stream-input use case (no direct replacement); evaluate media-pipeline alternatives
       header: replace `<streamrecorder.h>` with `<recorder.h>`
       deprecated since: 7.0
- L77 streamrecorder_set_filename() → recorder_set_filename()

#### src/messaging/sms.c (1 finding)
- L60 messages_mms_set_subject() → no replacement (MMS deprecated 8.0); evaluate alternative messaging channel
```

## Anti-patterns

- Do not auto-rewrite source files. Tizen API migrations frequently change error semantics, parameter ordering, and lifetime ownership; a textual rename will compile but may misbehave at runtime.
- Do not pull deprecation lists from the internet at runtime. The list embedded above is the source of truth for this skill; users edit this file to add entries.
- Do not flag a deprecated API as HIGH if its replacement is itself in deprecation track for the project's target API version (e.g., do not migrate to a 7.0 replacement when targeting 8.0 if the replacement was deprecated again at 8.0).
- Do not assume the replacement function takes the same arguments. Always check the new signature; many "managers" require an explicit handle.
- Do not strip the deprecated header include without first verifying that no other deprecated symbol from that header is still used.
- Do not change function pointer typedefs without updating every callback registration; the type system catches some but not all cases.
- Do not migrate `messages_mms_*` to `messages_*` (SMS) silently — they have different protocol semantics and the user-facing meaning of the operation changes.
- Do not flag `service_*` APIs as deprecated if the project explicitly targets Tizen API 2.4 (legitimately uses the legacy framework); check `api-version` first.
- Do not propose pulling in `<gstreamer.h>` as a "modern" replacement for `streamrecorder` without confirming the project ships the GStreamer plugin set; not all profiles include it.
- Do not migrate a `tapi` call to `telephony` without confirming dual-SIM-aware handle selection logic; the new API requires explicit SIM index.
- Do not assume Tizen.NET's deprecation track matches native one-for-one; the .NET binding may keep an old name for source compatibility while the underlying native call is replaced.
- Do not edit `tizen-manifest.xml` to bump `api-version` as part of "modernizing" — the manifest version determines minimum-supported devices and is a release-management decision.
- Do not flag `bundle_dup()` if the project relies on the duplicate's reference-counting semantics; some legacy code patterns depend on this.
- Do not propose async migrations (`thumbnail_util_extract`) without verifying the calling context has an event loop; sync calls can be the right choice in worker threads.
- Do not assume the table above is exhaustive. If the project uses an API not listed here, the skill simply emits no finding for it; the user can add an entry to this file.
