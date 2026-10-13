#!/bin/bash
# 新しい Mac のセットアップの入口（何度実行してもよい）
#   ./bootstrap.sh personal   個人用
#   ./bootstrap.sh work       仕事用
# 流れ: Xcode CLT → Homebrew → brew bundle（共通 + 用途別）→ リンク → mise / uv → Claude Code / Codex → macOS 設定
set -euo pipefail

PROFILE="${1:-}"
case "$PROFILE" in
  personal|work) ;;
  *) echo "使い方: $0 personal|work" >&2; exit 1 ;;
esac
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES_DIR"

echo "==> Xcode Command Line Tools"
if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install
  echo "インストールのダイアログが閉じたら、もう一度 $0 $PROFILE を実行してください"
  exit 1
fi

echo "==> Homebrew"
if [ ! -x /opt/homebrew/bin/brew ]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

# サードパーティ tap は信頼登録しないと読み込まれない（Homebrew 6.0 以降）
brew tap stablyai/orca
brew trust --cask stablyai/orca/orca

echo "==> brew bundle（Brewfile + Brewfile.$PROFILE）"
# 1つ失敗しても残りは入れ、最後にまとめて報告する
failed=()
brew bundle --file=Brewfile || failed+=("Brewfile")
brew bundle --file="Brewfile.$PROFILE" || failed+=("Brewfile.$PROFILE")

echo "==> dotfiles のリンク"
./link.sh

echo "==> mise（node / pnpm）と uv（python）"
mise install
uv python install --default   # ~/.local/bin に python3 を置く（macOS 標準の 3.9 より優先される）

echo "==> Claude Code / Codex の設定"
./setup-agents.sh

echo "==> macOS の設定"
./macos.sh

echo ""
if [ ${#failed[@]} -gt 0 ]; then
  echo "!! 一部インストールに失敗しました: ${failed[*]}"
  echo "   brew bundle check --file=<ファイル> --verbose で足りないものを確認してください"
  echo "   （mas は App Store にサインインしていないと失敗します）"
  echo ""
fi
echo "==> 完了。ターミナルを開き直してから、手でやること:"
echo "  1. gh auth login（アカウントごとに繰り返す）→ gh auth setup-git"
echo "  2. claude を起動して /login、codex login"
echo "  3. 1Password にサインインし、op signin"
echo "  4. Karabiner-Elements・Raycast などに、システム設定でアクセシビリティを許可"
echo "  5. Raycast の Script Commands に ~/dotfiles/raycast/script-commands を登録"
echo "  6. setup-agents.sh が表示した Orca / Codex の手順"
echo "  7. システム設定 → キーボード → 入力ソースで Google 日本語入力（ひらがな・英数）を追加し、標準の日本語を外す"
