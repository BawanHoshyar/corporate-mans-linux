#!/bin/bash
# Self-heal AeroSpace after an auto-update.
#
# When AeroSpace updates on disk but the old process keeps running, the CLI and
# the running server disagree on SOCKET_PROTOCOL_VERSION and window tiling
# ("auto split down the middle") breaks. This detects that exact state and
# restarts AeroSpace so the running app matches the installed binary.
#
# Does nothing when AeroSpace is healthy or not running.

AEROSPACE_CLI="/opt/homebrew/bin/aerospace"

# Nothing to do if AeroSpace isn't running.
pgrep -x AeroSpace >/dev/null 2>&1 || exit 0

# Probe the server. On a version mismatch the client prints "incompatible".
out="$("$AEROSPACE_CLI" list-workspaces --focused 2>&1)"
if printf '%s' "$out" | grep -qi "incompatible"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') stale AeroSpace detected, restarting"
    osascript -e 'quit app "AeroSpace"' 2>/dev/null
    sleep 2
    if pgrep -x AeroSpace >/dev/null 2>&1; then
        killall AeroSpace 2>/dev/null
        sleep 2
    fi
    open -a AeroSpace
    echo "$(date '+%Y-%m-%d %H:%M:%S') restart issued"
fi
