#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Restart Logi Options+
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🖱️
# @raycast.description Restarts the Logi Options+ device manager

# Documentation:
# @raycast.author dai0916
# @raycast.authorURL https://raycast.com/dai0916

launchctl kickstart -k "gui/$(id -u)/com.logi.cp-dev-mgr"
