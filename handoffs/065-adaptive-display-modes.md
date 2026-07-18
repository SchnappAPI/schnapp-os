# 065 - Adaptive display management for the headless MacBook (2026-07-18)

## What changed
Owner-directed machine change (files in `~/bin` + LaunchAgents, not repo-tracked; canonical
fact: vault memory `headless-macbook-external-monitors` - superseded in place).

The fixed always-desk-layout self-healer became a mode-aware system:
- `display-profile-watcher.py` (rewritten): tails the Jump Desktop log + system log (CRD),
  classifies each Jump session phone vs laptop by probing 10s for the client-created
  "Jump Desktop" virtual display (host cannot identify the device otherwise - settled in the
  June chats), writes `~/.display-profile-state`, runs the matching profile script.
  Session tracking is an authoritative boot-time-filtered rescan of unmatched auth/close
  pairs (the old incremental counter leaked a phantom connection on 2026-07-16 and could
  never fire the disconnect profile again).
- `reconnect-external-displays.sh` (rewritten): enforces the ACTIVE mode's layout every 60s,
  no-op when healthy; never enforces desk layout while a Jump session is open; 3-strike
  backoff (then every 10th tick) when macOS/Jump reasserts topology mid-session.
- Profiles: phone = Acer portrait sole; laptop = Jump virtual display sole (falls back to
  phone if the client did not set Virtual Displays = 1); desktop (CRD) = RVD 1920x1200;
  normal = LG main + Acer 270 + RVD off. `~/.jump-connect-mode`: `auto` | `a` | `b` override.
- Stale-ID class fixed across all profile scripts (drifting BD UUIDs -> `-namelike` + the two
  EDID-stable displayplacer ids); brightness state moved out of `/tmp`.

## Verified
- Both session detectors (awk + python) agree against the live log, boot-filter drops the
  2026-06-01 orphan auth. shellcheck + py_compile clean. Watcher restarted INTO a live phone
  session -> correctly went hands-off (`manual`, no churn). Self-healer loaded and enforcing.

## Open / next transition validates
- Connect-time profile application is live-fire untested (the running phone session predates
  the system; mid-session enforcement could not drop the LG because Jump reasserts streamed
  displays - that is the backoff's job). The next disconnect should restore the desk layout;
  the next phone connect should land Acer-sole. Check `~/Library/Logs/display-profile-watcher.log`.
- Laptop mode needs the one-time client-side setting Virtual Displays = 1 on the Windows Jump
  client (iOS has no such option, so phone auto-classification is unaffected).
- Rollback: `cp ~/bin/backup-2026-07-18/* ~/bin/ && launchctl kickstart -k gui/501/com.schnapp.displayprofilewatcher && launchctl kickstart -k gui/501/com.schnapp.reconnect-displays`

## Catch-up note
Commits since handoff 063 are logged line-by-line in PROGRESS.md (render-health self-heal,
schnapp.bet failover decision, APPFOLIO_API closure, transcript cloud-sync = handoff 064).
