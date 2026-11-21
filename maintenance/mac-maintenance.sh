#!/bin/bash
# この Mac のディスクの定期メンテナンス（launchd から呼ぶ。install.sh が登録する）
#
#   mac-maintenance.sh monthly   決めごとの掃除（brew・pnpm・uv・OrbStack）。毎月 1 日
#   mac-maintenance.sh check     空きが閾値を切ったら通知し、Orca の点検（mgpj の disk-check）を起動する。毎日
#
# 決めごとの元は mac-migration の README「256GB で運用するための決めごと」。
# 何を消してよいか迷うもの（ワークツリーの残り・古い node_modules など）はここでは消さない。
# それは Orca の点検（mgpj の disk-check スキル）が調べ、ユーザーの承認を取ってから消す。
# ログ: ~/Library/Logs/mac-maintenance/maintenance.log
set -u
PATH="/Applications/Orca.app/Contents/Resources/bin:/opt/homebrew/bin:$HOME/.local/bin:$HOME/.local/share/mise/shims:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
LOG_DIR="$HOME/Library/Logs/mac-maintenance"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/maintenance.log"
THRESHOLD_GB="${MAC_MAINT_THRESHOLD_GB:-30}"
AUTOMATION_NAME="${MAC_MAINT_AUTOMATION:-mgpj ディスク点検}"

log() { printf '%s %s\n' "$(date '+%F %T')" "$*" >>"$LOG"; }
free_gb() { df -g /System/Volumes/Data 2>/dev/null | awk 'NR == 2 { print $4 }'; }
notify() { osascript -e "display notification \"$1\" with title \"Mac のディスク\"" >/dev/null 2>&1 || true; }
run() {
  log "実行: $*"
  "$@" >>"$LOG" 2>&1 || log "失敗（exit $?）: $*"
}

monthly() {
  local before after
  before=$(free_gb)
  if command -v brew >/dev/null 2>&1; then run brew cleanup; fi
  if command -v pnpm >/dev/null 2>&1; then run pnpm store prune; fi
  if command -v uv >/dev/null 2>&1; then run uv cache prune; fi
  # OrbStack が動いているときだけ（止まっているのに起こさない）
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then run docker system prune -f; fi
  after=$(free_gb)
  log "月次の掃除が終わった: 空き ${before:-?}GB → ${after:-?}GB"
}

check() {
  local free today stamp id
  free=$(free_gb)
  if [ -z "$free" ]; then
    log "点検: 空きが取れなかった"
    return 0
  fi
  if [ "$free" -ge "$THRESHOLD_GB" ]; then
    log "点検: 空き ${free}GB（閾値 ${THRESHOLD_GB}GB 以上）"
    return 0
  fi
  # 起動は 1 日 1 回まで（空きが少ないあいだ毎日起こさないように、同じ日の 2 回目は飛ばす）
  today=$(date +%F)
  stamp="$LOG_DIR/last-trigger"
  if [ "$(cat "$stamp" 2>/dev/null)" = "$today" ]; then
    log "点検: 空き ${free}GB。今日はもう起動した"
    return 0
  fi
  echo "$today" >"$stamp"
  notify "空きが ${free}GB です（閾値 ${THRESHOLD_GB}GB）。Claude が原因を調べます"
  if ! command -v orca >/dev/null 2>&1; then
    log "点検: 空き ${free}GB。orca が無いので通知だけ"
    return 0
  fi
  id=$(orca automations list --json 2>/dev/null |
    jq -r --arg n "$AUTOMATION_NAME" '(.result.automations // .result // [])[]? | select(.name == $n) | .id' | head -n 1)
  if [ -z "$id" ]; then
    log "点検: 空き ${free}GB。オートメーション「$AUTOMATION_NAME」が無いので通知だけ"
    return 0
  fi
  run orca automations run "$id"
  log "点検: 空き ${free}GB。オートメーション「$AUTOMATION_NAME」（$id）を起動した"
}

case "${1:-}" in
  monthly) monthly ;;
  check) check ;;
  *) echo "使い方: $0 monthly|check" >&2; exit 1 ;;
esac
