#!/bin/bash
# mac-maintenance.sh を launchd に登録する（何度実行してもよい）
#   毎月 1 日 10:00   monthly（決めごとの掃除）
#   毎日 9:30         check（空きが閾値を切ったら通知して点検を起動）
# スリープ中で時刻を過ぎた分は、起きたときに launchd が 1 回だけ実行する。
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$DIR/mac-maintenance.sh"
AGENTS="$HOME/Library/LaunchAgents"
mkdir -p "$AGENTS" "$HOME/Library/Logs/mac-maintenance"
chmod +x "$SCRIPT"

write_plist() { # label mode calendar-dict
  local label="$1" mode="$2" cal="$3" path="$AGENTS/$1.plist"
  cat >"$path" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$label</string>
  <key>ProgramArguments</key>
  <array><string>/bin/bash</string><string>$SCRIPT</string><string>$mode</string></array>
  <key>StartCalendarInterval</key>
  $cal
  <key>StandardOutPath</key><string>$HOME/Library/Logs/mac-maintenance/launchd.log</string>
  <key>StandardErrorPath</key><string>$HOME/Library/Logs/mac-maintenance/launchd.log</string>
</dict>
</plist>
EOF
  launchctl bootout "gui/$(id -u)" "$path" >/dev/null 2>&1 || true
  launchctl bootstrap "gui/$(id -u)" "$path"
  echo "登録した: $label"
}

write_plist local.mac-maintenance.monthly monthly '<dict><key>Day</key><integer>1</integer><key>Hour</key><integer>10</integer><key>Minute</key><integer>0</integer></dict>'
write_plist local.mac-maintenance.check check '<dict><key>Hour</key><integer>9</integer><key>Minute</key><integer>30</integer></dict>'
