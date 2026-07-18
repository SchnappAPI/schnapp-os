# Caffeinate (hub availability)

**Class:** safe (auto). Read-only power assertion, no data/money/production mutation, instantly reversible.

**Why:** the Mac is the hub other devices reach over cloudflared tunnels (`mac-mcp`, `obsidian-mcp`,
`console`). If it sleeps, every off-Mac surface loses shell, SQL, console, and live data. On AC the
Mac already resists idle sleep (`pmset -c sleep 0`), but that is one setting that can drift, and it
does not cover a clamshell-on-AC edge (an external display dropping). This agent runs
`caffeinate -s` as a durable belt.

**Scope on purpose:** `-s` holds the assertion only on **AC power**, so a MacBook on battery still
sleeps normally (no battery-drain / dead-battery risk). It does NOT prevent sleep on battery, a
manual Apple-menu Sleep, or the machine being powered off. The harder, all-power override is the
owner-only `sudo pmset` fix below.

Plist: [com.schnapp.caffeinate.plist](com.schnapp.caffeinate.plist) (`__HOME__` render, same
owner-confirmed `launchctl` policy as the others).

### Install (on the Mac)

```bash
REPO=~/code/schnapp-os
mkdir -p ~/Library/Logs/schnapp-os
sed -e "s|__HOME__|$HOME|g" \
  "$REPO/scheduled-tasks/com.schnapp.caffeinate.plist" \
  > ~/Library/LaunchAgents/com.schnapp.caffeinate.plist
launchctl load ~/Library/LaunchAgents/com.schnapp.caffeinate.plist
launchctl list | grep com.schnapp.caffeinate   # verify (pid, exit 0)
pmset -g assertions | grep -i sleep             # confirm PreventUserIdleSystemSleep held
```

### Durable, all-power override (owner-only, needs sudo)

Prevents sleep even off AC and across clamshell/lid edges (`disablesleep` is Apple's server-mode
flag). Optional; only if the Mac should never sleep regardless of power source:

```bash
sudo pmset -c sleep 0 disksleep 0     # AC-only, safe: never sleep while plugged in
sudo pmset -a autorestart 1           # auto-power-on after a power loss
# harder (all power sources, e.g. a MacBook used headless off a battery-backed setup):
# sudo pmset -a disablesleep 1
pmset -g | grep -Ei "sleep|autorestart"   # verify
```

### Uninstall

```bash
launchctl unload ~/Library/LaunchAgents/com.schnapp.caffeinate.plist
rm ~/Library/LaunchAgents/com.schnapp.caffeinate.plist
```
