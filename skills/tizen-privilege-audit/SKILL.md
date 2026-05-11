---
name: tizen-privilege-audit
description: Cross-checks declared privileges in tizen-manifest.xml against actual API calls in source using an embedded mapping table, surfacing UNUSED-PRIVILEGE (declared but unused) and MISSING-PRIVILEGE (API used without declaration) findings.
version: 1.0.0
when_to_use: User invokes "/tizen-privilege", asks to "audit Tizen privileges", or wants to verify the manifest matches actual API usage before a release.
inputs:
  - name: target
    description: Optional path. Defaults to the project root, scanning C/C++/C# source under it and the manifest at the root.
required_tools: [bash, read]
---

# Tizen Privilege Audit Skill

## Goal

Compare the privileges declared in `tizen-manifest.xml` against API calls actually present in source. Report two findings per pair:
- **UNUSED-PRIVILEGE**: declared but no source call needs it (security-review opportunity; runtime impact: none, but reduces user trust prompts).
- **MISSING-PRIVILEGE**: API used but the privilege is not declared (runtime impact: API call returns `*_ERROR_PERMISSION_DENIED` / `ENOACCESS`, often only on devices with strict policies).

The skill never edits the manifest; it produces a report. Privilege removal in particular is reserved for explicit user decision (libraries and reflection paths can require privileges invisibly).

## Boundary

Use this skill only for privilege-to-source usage matching. Use
`tizen-manifest-review` for package/profile/application/category metadata and
`tizen-api-modernize` for deprecated API replacement plans.

## Inputs

- `target`: project root (default).

## Steps

1. Locate the manifest.
   ```bash
   find . -maxdepth 4 -name 'tizen-manifest.xml' -not -path '*/.build*/*'
   ```

2. Extract declared privileges.
   ```bash
   grep -oE '<privilege>[^<]+</privilege>' tizen-manifest.xml \
     | sed -e 's/<privilege>//' -e 's/<\/privilege>//' \
     | sort -u
   ```

3. Walk source files (`.c`, `.cpp`, `.cs`, `.h`, `.hpp`) under the project. Skip generated, third-party, and build dirs.
   ```bash
   find . -type f \( -name '*.c' -o -name '*.cpp' -o -name '*.cs' -o -name '*.h' -o -name '*.hpp' \) \
     -not -path '*/build/*' -not -path '*/Debug/*' -not -path '*/Release/*' \
     -not -path '*/obj/*' -not -path '*/bin/*' -not -path '*/third_party/*'
   ```

4. For each row in the mapping table below, grep all source files for the listed API patterns. If any source file matches a pattern, the corresponding privilege is "used".

5. Compute set differences:
   - declared ∩ used → OK
   - declared ∖ used → UNUSED-PRIVILEGE (report; do not remove)
   - used ∖ declared → MISSING-PRIVILEGE (report; recommend adding)

6. Emit a per-privilege report with the matching source lines (file:line) for any "used" finding.

## Curated privilege ↔ API mapping

The table below is the source of truth for this skill. **Do not fetch updated mappings from the internet at runtime.** Edit this file to extend coverage.

Pattern syntax: `pattern` is a basic-regex grep pattern matched against source. Multiple patterns are OR'd. Header includes (`<header.h>`) are matched as `#include\s+[<"]header.h[>"]`.

### Network

| Privilege URI | API patterns |
|---------------|--------------|
| `http://tizen.org/privilege/internet` | `<curl/curl.h>`, `<curl.h>`, `\bcurl_easy_(init\|setopt\|perform\|cleanup)\b`, `<sys/socket.h>`, `\bsocket\s*\(`, `\bconnect\s*\(.*AF_(INET\|INET6)`, `<net/http.h>`, `\bhttp_(transaction\|client)_`, `Tizen\.Network\.Connection`, `HttpClient`, `WebClient` |
| `http://tizen.org/privilege/network.get` | `<network/connection.h>`, `\bconnection_create\b`, `\bconnection_get_(type\|profile_iterator\|state)\b`, `Tizen\.Network\.Connection\.ConnectionManager` |
| `http://tizen.org/privilege/network.set` | `\bwifi_manager_(activate\|deactivate\|connect\|disconnect)\b`, `\bconnection_set_default_cellular_service_profile\b` |
| `http://tizen.org/privilege/network.profile` | `\bconnection_(add\|remove\|update)_profile\b` |
| `http://tizen.org/privilege/bluetooth` | `<bluetooth.h>`, `\bbt_(initialize\|deinitialize\|adapter_\|gatt_\|socket_\|opp_\|hid_\|audio_)`, `Tizen\.Network\.Bluetooth` |
| `http://tizen.org/privilege/nfc` | `<nfc.h>`, `\bnfc_(manager_initialize\|tag_\|p2p_\|snep_\|hce_)`, `Tizen\.Network\.Nfc` |
| `http://tizen.org/privilege/push` | `<push-service.h>`, `\bpush_service_(connect\|disconnect\|register\|deregister)\b`, `Tizen\.Messaging\.Push` |

### Location and sensors

| Privilege URI | API patterns |
|---------------|--------------|
| `http://tizen.org/privilege/location` | `<locations.h>`, `\blocation_manager_(create\|start\|get_position\|get_location\|destroy)\b`, `Tizen\.Location\.Locator` |
| `http://tizen.org/privilege/location.coarse` | `\blocation_manager_(create\|start)\s*\([^)]*LOCATIONS_METHOD_(WPS\|HYBRID)`, `LocationType\.Hybrid`, `LocationType\.Wps` |
| `http://tizen.org/privilege/healthinfo` | `\bsensor_get_default_sensor\s*\([^)]*SENSOR_(HRM\|HRM_LED_GREEN\|HRM_LED_IR\|HRM_LED_RED\|EXERCISE\|PEDOMETER\|SLEEP_MONITOR\|HUMAN_PEDOMETER\|HUMAN_SLEEP_MONITOR\|STRESS_MONITOR)`, `Tizen\.Sensor\.HeartRateMonitor`, `Tizen\.Sensor\.Pedometer`, `Tizen\.Sensor\.SleepMonitor` |

### Hardware

| Privilege URI | API patterns |
|---------------|--------------|
| `http://tizen.org/privilege/camera` | `<camera.h>`, `\bcamera_(create\|start_preview\|start_capture\|destroy)\b`, `Tizen\.Multimedia\.Camera` |
| `http://tizen.org/privilege/recorder` | `<recorder.h>`, `\brecorder_(create_(audiorecorder\|videorecorder)\|prepare\|start\|commit)\b`, `Tizen\.Multimedia\.AudioRecorder`, `Tizen\.Multimedia\.VideoRecorder` |
| `http://tizen.org/privilege/display` | `\bdevice_display_(get_brightness\|set_brightness\|set_state)\b`, `Tizen\.System\.Display` |
| `http://tizen.org/privilege/power` | `\bdevice_power_(request_lock\|release_lock\|reboot)\b`, `Tizen\.System\.Power` |
| `http://tizen.org/privilege/haptic` | `\bdevice_haptic_(open\|vibrate\|stop\|close)\b`, `Tizen\.System\.Haptic` |
| `http://tizen.org/privilege/led` | `\bdevice_flash_(set_brightness\|get_brightness\|get_max_brightness)\b`, `\bdevice_led_(play_custom\|stop_custom)\b` |

### Messaging and telephony

| Privilege URI | API patterns |
|---------------|--------------|
| `http://tizen.org/privilege/message.read` | `<messages.h>`, `\bmessages_search_message\b`, `\bmessages_foreach_message\b` |
| `http://tizen.org/privilege/message.write` | `\bmessages_create_message\b`, `\bmessages_send_message\b`, `\bmessages_add_address\b` |
| `http://tizen.org/privilege/telephony` | `<telephony.h>`, `\btelephony_(init\|sim_\|network_\|call_get_status)`, `Tizen\.Telephony` |
| `http://tizen.org/privilege/call` | `<app_control.h>` together with `app_control_set_operation\s*\([^)]*APP_CONTROL_OPERATION_CALL`, `Tizen\.Applications\.AppControlOperations\.Call` |

### Personal data

| Privilege URI | API patterns |
|---------------|--------------|
| `http://tizen.org/privilege/calendar.read` | `<calendar2.h>`, `\bcalendar_(connect\|db_get_record\|db_get_all_records)\b`, `Tizen\.Pims\.Calendar.*Reader` |
| `http://tizen.org/privilege/calendar.write` | `\bcalendar_db_(insert_record\|update_record\|delete_record)\b`, `Tizen\.Pims\.Calendar.*Manager\.(Insert\|Update\|Delete)` |
| `http://tizen.org/privilege/contact.read` | `<contacts.h>`, `\bcontacts_(connect\|db_get_record\|db_get_all_records)\b`, `Tizen\.Pims\.Contacts.*Reader` |
| `http://tizen.org/privilege/contact.write` | `\bcontacts_db_(insert_record\|update_record\|delete_record)\b`, `Tizen\.Pims\.Contacts.*Manager\.(Insert\|Update\|Delete)` |
| `http://tizen.org/privilege/callhistory.read` | `\bcontacts_db_get_records_with_query\s*\([^)]*_contacts_phone_log` |
| `http://tizen.org/privilege/callhistory.write` | `\bcontacts_db_(update\|delete)_record\s*\([^)]*phone_log` |
| `http://tizen.org/privilege/account.read` | `<account.h>`, `\baccount_(connect\|query_account_)\b`, `Tizen\.Account\.AccountManager\.Get` |
| `http://tizen.org/privilege/account.write` | `\baccount_(insert_to_db\|update_to_db_by_id\|delete_from_db_by_id)\b`, `Tizen\.Account\.AccountManager\.(Add\|Update\|Delete)` |

### Storage

| Privilege URI | API patterns |
|---------------|--------------|
| `http://tizen.org/privilege/mediastorage` | `\bstorage_get_directory\s*\([^)]*STORAGE_DIRECTORY_(IMAGES\|SOUNDS\|VIDEOS\|CAMERA\|DOWNLOADS\|MUSIC)`, paths starting with `/opt/usr/media/` or `/opt/usr/home/owner/media/` |
| `http://tizen.org/privilege/externalstorage` | `\bstorage_foreach_device_supported\b` together with `STORAGE_TYPE_EXTERNAL`, paths under `/opt/storage/sdcard/` or `/opt/media/SDCardA1/` |
| `http://tizen.org/privilege/externalstorage.appdata` | app data writes under external storage paths returned by `storage_get_directory` for external storage |

### System and apps

| Privilege URI | API patterns |
|---------------|--------------|
| `http://tizen.org/privilege/alarm.get` | `\balarm_get_(scheduled_period\|scheduled_recurrence_week_flag\|scheduled_date)\b`, `\balarm_foreach_registered_alarm\b`, `Tizen\.Applications\.AlarmManager\.GetAllScheduledAlarms` |
| `http://tizen.org/privilege/alarm.set` | `\balarm_schedule_(after_delay\|at_date\|once_after_delay\|once_at_date)\b`, `Tizen\.Applications\.AlarmManager\.Create` |
| `http://tizen.org/privilege/notification` | `<notification.h>`, `\bnotification_(create\|post\|update\|delete)\b`, `Tizen\.Applications\.NotificationManager` |
| `http://tizen.org/privilege/packagemanager.info` | `<package_manager.h>`, `\bpackage_manager_(get_package_info\|foreach_package_info)\b`, `Tizen\.Applications\.PackageManager` |
| `http://tizen.org/privilege/appmanager.launch` | `<app_manager.h>`, `\bapp_manager_open_app\b`, `\bapp_control_send_launch_request\b` |
| `http://tizen.org/privilege/keymanager` | `<ckmc/ckmc-manager.h>`, `\bckmc_(save_(key\|cert\|data\|pkcs12)\|get_(key\|cert\|data\|pkcs12)\|remove_alias)\b` |
| `http://tizen.org/privilege/window.priority.set` | `\befl_util_set_notification_window_level\b`, `Tizen\.NUI\.Window\.WindowType` set to `Notification` |
| `http://tizen.org/privilege/datasharing` | `<data_control.h>`, `\bdata_control_(provider_create\|consumer_create)\b` |

## Output format

```markdown
### tizen-privilege-audit report

Manifest: tizen-manifest.xml (12 privileges declared)
Source files scanned: 47

Declared (12):
  http://tizen.org/privilege/internet
  http://tizen.org/privilege/location
  http://tizen.org/privilege/network.get
  http://tizen.org/privilege/bluetooth
  http://tizen.org/privilege/camera
  http://tizen.org/privilege/notification
  http://tizen.org/privilege/calendar.read
  http://tizen.org/privilege/calendar.write
  http://tizen.org/privilege/healthinfo
  http://tizen.org/privilege/mediastorage
  http://tizen.org/privilege/alarm.set
  http://tizen.org/privilege/keymanager

OK (8 — declared and used):
  internet            ← src/net/api.c:42, src/net/api.c:88, src/net/auth.c:14
  location            ← src/loc/track.c:33
  bluetooth           ← src/bt/scan.c:17, src/bt/scan.c:55
  notification        ← src/ui/notify.c:91
  calendar.read       ← src/cal/sync.c:22
  mediastorage        ← src/storage/save.c:60
  alarm.set           ← src/alarm/sched.c:44
  keymanager          ← src/sec/keys.c:18, src/sec/keys.c:103

UNUSED-PRIVILEGE (4 — declared but no matching source call found):
  network.get         no `connection_create` / `<network/connection.h>` usage detected
  camera              no `camera_*` / `<camera.h>` usage detected
  calendar.write      no `calendar_db_(insert|update|delete)_record` detected (only read)
  healthinfo          no HRM/Pedometer/Sleep sensor usage detected
  Note: do not remove without checking dynamically-loaded plugins, .NET reflection paths,
        and bundled libraries that may use these privileges internally.

MISSING-PRIVILEGE (2 — used in source but not declared):
  http://tizen.org/privilege/recorder
       src/audio/capture.c:14  recorder_create_audiorecorder(...)
       src/audio/capture.c:42  recorder_start(...)
  http://tizen.org/privilege/appmanager.launch
       src/launch/start.c:30   app_control_send_launch_request(...)
       Add to <privileges> in tizen-manifest.xml.
```

## Anti-patterns

- Do not auto-edit `tizen-manifest.xml` to remove unused privileges. Plugins, reflection-based callers, and conditional code paths can require privileges that simple grep does not see. Removing causes runtime `*_ERROR_PERMISSION_DENIED` failures that are hard to diagnose.
- Do not auto-add missing privileges either. Adding a privacy-related privilege (location, camera, healthinfo, contacts, etc.) changes the user-facing consent prompt; the team should accept that change deliberately.
- Do not mark a privilege as UNUSED if the project includes a third-party `.so` or `.dll` whose call sites are not in the source tree; this skill cannot inspect compiled libraries.
- Do not mark a privilege as UNUSED if the project includes Tizen.NET assemblies (.NET) whose calls go through reflection or dependency-injected services. Confirm with the owner before recommending removal.
- Do not flag `internet` as missing if the only network code is HTTPS via a third-party HTTP wrapper that compiles against `<curl/curl.h>` indirectly; ensure the grep covers the actual call.
- Do not flag privacy-related privileges as removable on the grounds that "the test harness mocked it"; the production binary makes the real call.
- Do not assume the embedded mapping is complete; users add entries by editing this file. If the project uses an API not in the table, the audit silently produces no finding for it.
- Do not fetch privilege ↔ API mappings from the internet at runtime; the table here is the only source of truth.
- Do not flag `partner/...` or `platform/...` privileges as suspect — they require specific signing certificates but are not necessarily wrong.
- Do not collapse `calendar.read` and `calendar.write` findings into one — they are independent privileges with independent consent prompts.
- Do not flag a privilege as MISSING based on a comment or string literal that mentions an API; require an actual function call match.
- Do not include build-system files (`build.gradle`, `CMakeLists.txt`, `Makefile`) in the source scan; they may reference API names in comments without invoking them.
- Do not silently merge multi-line API calls across files; each match should be reported with its file:line for the user to verify.
- Do not propose privilege changes during a code review pass; emit findings only and let the user act on them.
- Do not assume a missing-privilege finding is the only fix needed; some APIs additionally require a `<feature>` declaration in the manifest for device-store filtering.
