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

xml() { local s="$1"; s="${s//&/&amp;}"; s="${s//</&lt;}"; s="${s//>/&gt;}"; printf '%s' "$s"; }

write_plist() { # label mode calendar-dict
  local label="$1" mode="$2" cal="$3" path="$AGENTS/$1.plist"
  local script_x log_x
  script_x=$(xml "$SCRIPT")
  log_x=$(xml "$HOME/Library/Logs/mac-maintenance/launchd.log")
  cat >"$path" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>${label}</string>
  <key>ProgramArguments</key>
  <array><string>/bin/bash</string><string>${script_x}</string><string>${mode}</string></array>
  <key>StartCalendarInterval</key>
  $cal
  <key>StandardOutPath</key><string>${log_x}</string>
  <key>StandardErrorPath</key><string>${log_x}</string>
</dict>
</plist>
EOF
  echo "書いた: ${path}"
}

load_plist() { # label（GUI のログインセッションが無いときは失敗するので、次のログイン後に install.sh を実行し直す）
  local path="$AGENTS/$1.plist"
  launchctl bootout "gui/$(id -u)" "$path" >/dev/null 2>&1 || true
  if launchctl bootstrap "gui/$(id -u)" "$path"; then echo "登録した: $1"; else echo "登録できなかった: $1（ログインしてから ./maintenance/install.sh を実行し直す）" >&2; return 1; fi
}

write_plist local.mac-maintenance.monthly monthly '<dict><key>Day</key><integer>1</integer><key>Hour</key><integer>10</integer><key>Minute</key><integer>0</integer></dict>'
write_plist local.mac-maintenance.check check '<dict><key>Hour</key><integer>9</integer><key>Minute</key><integer>30</integer></dict>'

# 両方を書いてから登録する（片方の登録に失敗しても、もう片方を残す）
rc=0
load_plist local.mac-maintenance.monthly || rc=1
load_plist local.mac-maintenance.check || rc=1
exit "$rc"
