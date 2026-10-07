#!/bin/bash
# Claude Code / Codex のグローバル設定を配置する（何度実行してもよい）
#   - エージェント・フック・スキル・AGENTS.md はシンボリックリンク（dotfiles を直せば反映される）
#   - ~/.claude/settings.json と ~/.codex/config.toml・hooks.json は Orca やアプリが書き換えるのでリンクしない。
#     ひな形の内容を足し込むだけで、Orca が書いたフックなど既存の内容は残す
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
STAMP="$(date +%Y%m%d%H%M%S).$$"  # 同じ秒に 2 回実行しても退避が上書きされないよう PID を付ける

command -v jq >/dev/null || { echo "jq が必要です（brew install jq）" >&2; exit 1; }

# 既存の実体ファイルは .bak-<日時> に退避してからリンクする
link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "$dst.bak-$STAMP"
    echo "  退避: $dst -> $dst.bak-$STAMP"
  fi
  ln -sfn "$src" "$dst"
}

# 退避（$1.bak-${STAMP}）を入力に、jq の結果を一時ファイルへ出し、正しい JSON のオブジェクトのときだけ置き換える
# （出力先を直接書くと、失敗したときに空や途中の設定が残る）
merge_json() {
  local dst="$1"; shift
  local tmp; tmp=$(mktemp "$dst.tmp.XXXXXX")
  jq -e 'type == "object"' "$dst.bak-$STAMP" >/dev/null 2>&1 \
    || { rm -f "$tmp"; echo "  $dst が JSON のオブジェクトとして読めないので変更しません" >&2; exit 1; }
  if jq "$@" "$dst.bak-$STAMP" > "$tmp" && jq -e 'type == "object"' "$tmp" >/dev/null 2>&1; then
    mv "$tmp" "$dst"
  else
    rm -f "$tmp"; echo "  $dst を更新できませんでした（元のまま）" >&2; exit 1
  fi
}

# 足し込みで中身が変わったときだけ退避を残す
report() {
  if cmp -s "$1" "$1.bak-$STAMP"; then rm "$1.bak-$STAMP"; echo "  変更なし: $1"
  else echo "  更新: $1（元の内容は $1.bak-${STAMP}）"; fi
}

echo "==> Claude Code"
C="$DOTFILES_DIR/.claude"
link "$C/statusline.sh" ~/.claude/statusline.sh
link "$C/hooks/japanese-guard.py" ~/.claude/hooks/japanese-guard.py
for f in "$C"/agents/*.md; do link "$f" ~/.claude/agents/"$(basename "$f")"; done
for f in "$C"/commands/*.md; do link "$f" ~/.claude/commands/"$(basename "$f")"; done
for d in "$C"/skills/*/; do link "${d%/}" ~/.claude/skills/"$(basename "$d")"; done

# settings.json：ひな形のキーで上書きし、hooks はイベントごとに足りないものだけ足す
settings=~/.claude/settings.json
# 以前の setup はこのファイルを dotfiles へのリンクにしていた。リンクのままだと書き込みが dotfiles に入るので実体に戻す
if [ -L "$settings" ]; then
  if [ -e "$settings" ]; then cp "$settings" "$settings.tmp"; rm "$settings"; mv "$settings.tmp" "$settings"; else rm "$settings"; fi
fi
[ -f "$settings" ] || echo '{}' > "$settings"
cp "$settings" "$settings.bak-$STAMP"
merge_json "$settings" --slurpfile base "$C/settings.base.json" '
  ($base[0]) as $b
  | (. * ($b | del(.hooks)))
  | .hooks = (reduce ($b.hooks // {} | to_entries[]) as $e (.hooks // {};
      .[$e.key] = ((.[$e.key] // []) as $cur
        | $cur + [$e.value[] | select(. as $g | $cur | index($g) | not)])))
'
report "$settings"

if ! command -v claude >/dev/null; then
  echo "  Claude Code をインストールします"
  curl -fsSL https://claude.ai/install.sh | bash
fi

echo "==> Claude Code / Codex 共通のスキル"
for d in "$DOTFILES_DIR"/agent-skills/*/; do
  link "${d%/}" ~/.claude/skills/"$(basename "$d")"
  link "${d%/}" ~/.codex/skills/"$(basename "$d")"
done

echo "==> Codex"
X="$DOTFILES_DIR/.codex"
link "$X/AGENTS.md" ~/.codex/AGENTS.md
link "$X/hooks/japanese-guard.py" ~/.codex/hooks/japanese-guard.py
for f in "$X"/agents/*.toml; do link "$f" ~/.codex/agents/"$(basename "$f")"; done
for d in "$X"/skills/*/; do link "${d%/}" ~/.codex/skills/"$(basename "$d")"; done

config=~/.codex/config.toml
if [ -f "$config" ]; then
  echo "  $config は既にあるので変更しません。必要な節は $X/config.base.toml から手で写してください"
else
  sed "s|__HOME__|$HOME|g" "$X/config.base.toml" > "$config"
  echo "  作成: $config"
fi

# hooks.json：Stop に japanese-guard が無ければ足す（Codex は ~ を展開しないので絶対パスにする）
hooks=~/.codex/hooks.json
[ -f "$hooks" ] || echo '{"hooks":{}}' > "$hooks"
cp "$hooks" "$hooks.bak-$STAMP"
merge_json "$hooks" --arg cmd "$HOME/.codex/hooks/japanese-guard.py" '
  if [.hooks.Stop[]?.hooks[]?.command] | index($cmd) then .
  else .hooks.Stop = ((.hooks.Stop // []) + [{hooks: [{type: "command", command: $cmd, timeout: 10}]}])
  end
'
report "$hooks"

echo "==> 完了。続けて手でやること："
echo "  1. claude を起動して /login、codex login"
echo "  2. Claude Code で /codex:setup を実行し、Codex との連携を確かめる"
echo "  3. Codex を初めて起動したら、japanese-guard のフックを信頼する"
echo "  4. Orca を起動し、Claude と Codex を Orca から一度起動する（Orca が自分のフックを書き込む）"
