#!/bin/bash
# dotfiles をホームにシンボリックリンクする（何度実行してもよい）
# 既存の実体ファイルは .bak-<日時> に退避してからリンクする
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
STAMP="$(date +%Y%m%d%H%M%S).$$"

link() {
  local src="$DOTFILES_DIR/$1" dst="$HOME/$1"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "$dst.bak-$STAMP"
    echo "  退避: $dst -> $dst.bak-$STAMP"
  fi
  ln -sfn "$src" "$dst"
  echo "  リンク: $dst"
}

link .zshrc
link .zprofile
link .zimrc
link .bash_profile
link .vimrc
link .config/starship.toml
link .config/git/ignore
link .config/mise/config.toml
link .config/ghostty/config          # cmux もこの設定を読む
link .config/karabiner/karabiner.json
# BetterTouchTool はどの Brewfile にも入れていない。手で入れた端末でだけリンクする
if [ -d /Applications/BetterTouchTool.app ]; then
  link .config/bettertouchtool/Default.bttpreset
fi
