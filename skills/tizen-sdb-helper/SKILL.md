---
name: tizen-sdb-helper
description: Picks the right sdb command for a specific user request on a Tizen device — install, launch, kill, log capture, push, pull, screenshot, shell, port forward, root toggle, reboot, screen state — with multi-device disambiguation, command-line preview, and confirmation gates on destructive actions. Intent-first lookup; named recipes available for explicitly-requested multi-step chains.
version: 1.0.0
when_to_use: User asks for one sdb action ("install this tpk", "tail the logs", "screenshot the TV", "push this file", "open a shell", "forward port 9229", "reboot the device"), or invokes a named recipe like "install-and-launch", "install-launch-and-log", "reinstall-and-launch", or "kill-and-relaunch". Picks the correct sdb invocation for the attached Tizen device with profile-specific fallbacks.
inputs:
  - name: request
    description: The user's actual ask, in natural language. Drives intent matching against the command table.
  - name: serial
    description: Optional sdb device serial. Defaults to the only attached device, or prompts when more than one is connected.
required_tools: [bash, read]
---

# Tizen sdb Helper Skill

## Goal

Given a single request, return the correct `sdb` command for the attached Tizen device. Match the request against the intent table, pick the variant that fits the device profile (mobile / wearable / TV / IoT) and platform version, preview the command, and apply the confirmation rule for that intent. Do not run a multi-step workflow when the user only asked for one thing.

## Boundary

In scope: every action that goes through the `sdb` binary.
Out of scope:

- Signing or packaging the artifact — use `tizen-signing-profile`, `flutter-tizen-signing`, or `tizen-build-package`.
- Manifest review — use `tizen-manifest-review`.
- Privilege audit — use `tizen-privilege-audit`.
- Deprecated API replacement — use `tizen-api-modernize`.

## Inputs

- `request`: the user's ask.
- `serial`: optional sdb device serial.

## Resolution rules (applied to every request)

1. **sdb available.** `command -v sdb`. If missing, tell the user to source the Tizen Studio profile. Do not install Tizen Studio.
2. **Daemon running.** If `sdb devices` errors, run `sdb start-server` once. Do not run `sdb kill-server` to "reset" the daemon — that drops every parallel session.
3. **Pick target device.**
   - 0 devices → stop. Suggest attaching a device or `tizen emulator launch`.
   - 1 device → use it.
   - 2+ devices → list them and ask. Do not auto-pick.
   - `offline` / `unauthorized` → stop until the user fixes developer mode, the on-device key prompt, or the cable.
   - Parse by matching the `device` / `offline` / `unauthorized` state column. Do not trust `awk '{print $1}'`; the first row is a header and columns shift across platforms.
4. **Bind the serial.** Once chosen, every command in the same session uses `-s "$SDB_SERIAL"`. A second device plugging in mid-session will not steal the target.
5. **Preview before run.** Print the full command line, the artifact basename (if any), and the resolved device name + serial. If the intent is in the gated set below, wait for confirmation.

## Intent → command table

The skill matches the user's request against the **Intent** column and emits the **Command** column. Variants are listed when one device profile or platform version needs a different invocation.

### Discovery

| Intent | Command | Notes |
|---|---|---|
| List attached devices | `sdb devices` | Default. |
| Detailed device info | `sdb -s "$S" capability` | Profile, platform version, arch, sdk version. |
| Connect over network | `sdb connect <ip>:<port>` | TV / emulator over TCP. Port often `26101`. |
| Disconnect network device | `sdb disconnect <ip>:<port>` | Prefer this over `kill-server`. |

### Package lifecycle

| Intent | Command | Notes |
|---|---|---|
| Install TPK / WGT | `sdb -s "$S" install "$ARTIFACT"` | Gated. Parse trailing `install completed.` / `failed[<code>]`. |
| Uninstall by package id | `sdb -s "$S" uninstall "$PKGID"` | Gated. Package id, not app id. |
| List installed packages | `sdb -s "$S" shell pkgcmd -l` | Read-only. |
| Show package info | `sdb -s "$S" shell pkginfo --pkg "$PKGID"` | Read-only. |

If install fails with `WGT_CRT_ERR` / `SIG_CRT_ERR` / `CERTIFICATE_VERIFICATION_FAILED`, surface the error verbatim and hand off to the signing skills. Do not retry.

### Launch / kill

| Intent | Command | Notes |
|---|---|---|
| Launch app (standard) | `sdb -s "$S" shell app_launcher -s "$APPID"` | Mobile, wearable, modern TV. |
| Launch app (legacy TV) | `sdb -s "$S" shell 0 was_execute "$APPID"` | Fallback when `app_launcher` returns `not found`. |
| Kill app | `sdb -s "$S" shell app_launcher -k "$APPID"` | Gated when `$APPID` does not match the just-installed package. |
| List running apps | `sdb -s "$S" shell app_launcher -r` | Read-only. Output format varies by profile. |
| Resolve appid from TPK | unzip `tizen-manifest.xml`, read `<ui-application appid="...">` | Or ask the user. |

### Logs

| Intent | Command | Notes |
|---|---|---|
| Stream filtered log | `sdb -s "$S" dlog -v threadtime "$APPID":V "*:S"` | Preferred. Filter syntax fails on some older platforms. |
| Stream filtered log (fallback) | `sdb -s "$S" dlog -v threadtime` then pipe to `grep --line-buffered -F "$APPID"` | When the device rejects the `tag:V *:S` form. |
| Stream all logs | `sdb -s "$S" dlog -v threadtime` | Noisy; only when the user wants the full firehose. |
| Clear log buffer | `sdb -s "$S" dlog -c` | Gated. Destructive on shared devices. |
| Save logs to a file | stream → host-side redirect to `~/tizen-logs/<appid>-<ts>.log` | Ask before redirecting. Never write into the project tree without asking — multi-MB logs sneak into commits. |

### File transfer

| Intent | Command | Notes |
|---|---|---|
| Push to scratch (`/tmp/`, `/opt/usr/home/owner/share/tmp/`) | `sdb -s "$S" push "$LOCAL" "$REMOTE"` | One confirmation. |
| Push into `/opt/usr/apps/<pkg>/` | `sdb -s "$S" push ...` | Gated. Mention the package id in the confirmation prompt; this breaks the package signature. |
| Push into `/etc/` / `/usr/` / `/opt/etc/` | refuse | Recommend re-signing the package instead. |
| Pull a file | `sdb -s "$S" pull "$REMOTE" "$LOCAL"` | Warn before overwriting an existing local file. |
| Pull a directory | `sdb -s "$S" pull "$REMOTE_DIR" "$LOCAL_DIR"` | Reject `sdb pull /` or any near-root path. |

### Screenshot

| Intent | Command | Notes |
|---|---|---|
| Screenshot (standard) | `sdb -s "$S" shell screencapture /tmp/sshot.png` → `pull` → `shell rm /tmp/sshot.png` | Confirm before the `rm`. |
| Screenshot (fallback) | `sdb -s "$S" shell capture_screen` | When `screencapture` is missing. Some IoT images have neither — say so rather than guess. |
| Screen record | not via sdb on most profiles | Recommend the on-device recorder; sdb-side recording is not standardized. |

### Shell exec

| Intent | Command | Notes |
|---|---|---|
| One-shot shell command | `sdb -s "$S" shell "$CMD"` | Gate if `$CMD` matches: `rm `, `dd `, `mkfs`, `fsck`, `reboot`, `shutdown`, `factoryreset`, `chmod -R`, `chown -R`, `mv /`, or any redirection into `/etc/`, `/usr/`, `/opt/etc/`. |
| Interactive shell | `sdb -s "$S" shell` | Print which user the shell runs as (`whoami`) first — engineering builds land in `root`, retail in `app`. |
| Check shell user | `sdb -s "$S" shell whoami` | Read-only. |
| Toggle root shell on engineering builds | `sdb -s "$S" root on` | Gated. Do not call to "fix permissions"; fails silently on retail builds and confuses later sessions. |

### Port forward

| Intent | Command | Notes |
|---|---|---|
| Add forward | `sdb -s "$S" forward tcp:<host_port> tcp:<device_port>` | Recommend `<host_port>` ≥ 8000. Do not silently `sudo`. |
| List forwards | `sdb -s "$S" forward --list` | Read-only. |
| Remove forward | `sdb -s "$S" forward --remove tcp:<host_port>` | Or `--remove-all`; the latter is gated. |

### Device power / state

| Intent | Command | Notes |
|---|---|---|
| Reboot device | `sdb -s "$S" shell reboot` | Gated. Requires explicit user request. On retail showroom TVs this is irreversible mistake territory. |
| Shutdown device | `sdb -s "$S" shell shutdown -P now` | Gated. Same as above. |
| Factory reset | `sdb -s "$S" shell factoryreset` | Gated. Refuse without explicit, named confirmation. |
| Wake screen | `sdb -s "$S" shell echo on > /sys/class/graphics/fb0/blank` | Path varies per platform; prefer remote-key emulation when available. |
| Send key event | `sdb -s "$S" shell sendkey <KEYNAME>` | TV remote keys, e.g. `KEY_POWER`, `KEY_HOME`. Read-only-ish but `KEY_POWER` is gated. |

## Recipes (named multi-intent chains)

Recipes exist only for explicit user requests. Trigger a recipe when the user invokes the recipe name (e.g. "run /install-and-launch") or uses natural language that unambiguously names every step ("설치하고 실행한 다음 로그 보여줘"). Otherwise default to a single intent. Do not chain commands because they "usually go together".

Every step inside a recipe still applies its own confirmation gate from the intent table.

| Recipe | Steps | Notes |
|---|---|---|
| `install-and-launch` | install → resolve appid → launch | Stop on install failure. Do not retry. |
| `install-launch-and-log` | install → launch → stream filtered dlog | Log stream foregrounds; Ctrl-C ends the recipe. No auto-kill on exit. |
| `reinstall-and-launch` | uninstall (if package present) → install → launch | Skip uninstall when `pkginfo --pkg "$PKGID"` reports not installed. Both uninstall and install are gated. |
| `kill-and-relaunch` | kill → launch | Same appid. Kill gate applies only when appid was not just installed. |

Recipes that are tempting but not provided (and why):

- `install → launch → log → kill on exit` — auto-kill at session end surprises users still inspecting state. Use `install-launch-and-log` then run the kill intent manually.
- `pull-everything` — `sdb pull /` mishandles dev-special files; refused outright in the file-transfer table.
- `clear-log + launch` — clearing logs is destructive on shared devices; require it as a separate explicit step.

Do not invent new recipes ad-hoc. If the user asks for a chain not in this table, run the intents one at a time and confirm each, or ask whether to add the recipe to the skill.

## Selection algorithm

For each request:

1. Check whether the request matches a recipe name or unambiguously names every step of a listed recipe. If yes, treat it as a recipe (multi-step plan, gates per step).
2. Otherwise resolve the intent against the table.
3. If multiple variants exist, pick by:
   - **device profile** (read from `sdb capability` — `profile_name=mobile|wearable|tv|iot-headed|iot-headless`).
   - **platform version** (`platform_version` from the same capability dump).
   - **fallback chain order** as written above. Try the preferred variant first; only fall back when the device returns `not found` / `unknown command`.
4. Show the resolved command, device, and any inferred values (appid, package id, artifact path). For a recipe, show every step at once.
5. If the intent (or recipe step) is gated, wait for confirmation. Otherwise, run.
6. Report the output verbatim. Do not paraphrase sdb errors — surface the original code (`WGT_CRT_ERR`, `*_ERROR_PERMISSION_DENIED`, etc.) so the user can search for it.

## Confirmation gates (summary)

Gate before running:

- Install, uninstall.
- Kill an appid that is not the just-installed package.
- `dlog -c`.
- Push into `/opt/usr/apps/<pkg>/`.
- Push under `/etc/`, `/usr/`, `/opt/etc/` → refuse, do not gate.
- `shell` commands containing `rm `, `dd `, `mkfs`, `fsck`, `reboot`, `shutdown`, `factoryreset`, `chmod -R`, `chown -R`, `mv /`, or redirection into system paths.
- `root on`.
- `forward --remove-all`.
- `reboot`, `shutdown`, `factoryreset`, `sendkey KEY_POWER`.

## Output format

Per request, emit:

```markdown
### tizen-sdb-helper

Request:  install the tpk and launch it
Matched intents:  install → launch
Device:   0123456789ABCDEF  tv-samsung  (profile=tv, platform=7.0)

Plan:
  1. sdb -s 0123... install Output/Release/org.example.foo-1.0.4.tpk    [gated]
  2. sdb -s 0123... shell app_launcher -s org.example.foo

Awaiting confirmation: step 1.
```

For a single-intent request the plan is one line.

## Anti-patterns

- Do not run a full install → launch → log → kill workflow when the user asked for one of those steps. Match the intent and stop. Run a recipe only when the user named it or unambiguously named every step.
- Do not invent new recipes. If the user asks for a chain not in the recipe table, fall back to single-intent confirmations.
- Do not call `sdb kill-server` to "reset" the connection. Use `sdb disconnect` / `sdb connect` for networked devices, or have the user replug USB.
- Do not omit `-s "$SDB_SERIAL"` once a device has been chosen.
- Do not auto-pick the newest `.tpk` / `.wgt` when more than one is present; Debug, Release, and per-profile variants confuse easily.
- Do not retry a failed install in a loop. Install failures are almost always signing, privilege, or schema problems.
- Do not call `sdb root on` to "fix permissions" unless the user asked. It fails silently on retail builds.
- Do not push into `/opt/usr/apps/<pkg>/` to patch an installed package; the signature no longer matches.
- Do not run `sdb shell rm -rf` on a path proposed by the model; require the user to type the path.
- Do not redirect dlog into the project tree without asking — multi-megabyte logs sneak into commits.
- Do not interpret dlog output as JSON; it is line-oriented and varies per platform.
- Do not assume `app_launcher -s` exists on every profile; older TV and wearable images use `0 was_execute`. Fall back instead of failing.
- Do not call `factoryreset`, `reboot`, `shutdown`, or `sendkey KEY_POWER` without explicit user request and confirmation.
- Do not call `sdb forward tcp:<low_port>` (< 1024) and silently invoke `sudo`; suggest a high port.
- Do not poll `sdb capability` / `sdb get-state` in a tight loop; sleep between probes and bail after a fixed timeout.
- Do not run `sdb pull /` or any near-root mirror; sdb mishandles dev-special files and host disk fills.
- Do not assume the host sdb version matches the device daemon; protocol mismatches surface as "device offline" with no other clue — recommend updating Tizen Studio.
- Do not parse `sdb devices` by column position. Match on the state column.
- Do not paraphrase sdb error codes; surface them verbatim so the user can search.
- Do not chain multiple intents because they "usually go together"; emit only the commands the user asked for.
