#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Restart Stream Deck
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖
# @raycast.description Force-quits and relaunches Stream Deck

# Documentation:
# @raycast.author dai0916
# @raycast.authorURL https://raycast.com/dai0916

killall "Stream Deck" 2>/dev/null
sleep 1
open -a "/Applications/Elgato Stream Deck.app"

# Wait for the app to actually appear, then send Cmd+W to close its window
# (mirrors what manually works reliably; hiding it via "visible" did not).
for i in $(seq 1 25); do
  RUNNING=$(osascript -e 'tell application "System Events" to (name of processes) contains "Stream Deck"' 2>/dev/null)
  if [[ "$RUNNING" == "true" ]]; then
    sleep 1
    osascript -e '
      tell application "System Events"
        set frontmost of process "Stream Deck" to true
        keystroke "w" using command down
      end tell
    ' 2>/dev/null
    break
  fi
  sleep 0.2
done
