#!/bin/bash
# macOS のシステム設定（何度実行してもよい）。Dock・Finder・スクロールなどの値は旧機（2026-10）の実際の設定に合わせた
set -euo pipefail

# Dock: 自動で隠す・拡大しない
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 112
defaults write com.apple.dock magnification -bool false

# Finder: パスバーとステータスバーを表示・カラム表示・拡張子を常に表示・新規ウインドウは「最近の項目」
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"
defaults write com.apple.finder NewWindowTarget -string "PfAF"
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# スクロール: ナチュラルスクロールをオフ
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# トラックパッド: タップでクリック
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# 壁紙クリックでデスクトップを表示しない（ステージマネージャ使用時のみ表示）
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false

# ネットワークドライブと USB に .DS_Store を作らない
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
echo "  一部の設定（スクロール方向・トラックパッド）はログアウト後に反映されます"
