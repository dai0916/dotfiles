#!/bin/bash
set -euo pipefail

echo "==> Installing Homebrew (if needed)..."
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "==> Installing Homebrew packages..."
brew install \
  delta \
  direnv \
  eza \
  bat \
  fd \
  ffmpeg \
  fnm \
  fzf \
  gh \
  go \
  imagemagick \
  jq \
  keeper-commander \
  lazygit \
  node@22 \
  pnpm \
  ripgrep \
  safe-rm \
  starship \
  supabase/tap/supabase \
  tree \
  unar \
  uv \
  wget \
  zoxide

echo "==> Installing Homebrew casks..."
brew install --cask \
  aqua-voice \
  arc \
  cleanshot \
  cmux \
  font-0xproto-nerd-font \
  font-blex-mono-nerd-font \
  font-cica \
  font-firgenerd \
  font-hackgen-nerd \
  font-jetbrains-mono-nerd-font \
  font-line-seed-jp \
  font-moralerspace \
  font-plemol-jp-nf \
  font-sf-mono-for-powerline \
  font-source-han-code-jp \
  font-udev-gothic-nf \
  gcloud-cli \
  ghostty \
  google-japanese-ime \
  karabiner-elements \
  keepingyouawake \
  logitech-g-hub \
  smoothcsv \
  warp \
  xmind

echo "==> Linking dotfiles..."
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

ln -sf "$DOTFILES_DIR/.vimrc" ~/.vimrc
ln -sf "$DOTFILES_DIR/.zshrc" ~/.zshrc
ln -sf "$DOTFILES_DIR/.zprofile" ~/.zprofile
ln -sf "$DOTFILES_DIR/.zimrc" ~/.zimrc

mkdir -p ~/.config
ln -sf "$DOTFILES_DIR/.config/starship.toml" ~/.config/starship.toml

# git global ignore
mkdir -p ~/.config/git
ln -sf "$DOTFILES_DIR/.config/git/ignore" ~/.config/git/ignore

# Claude Code settings
mkdir -p ~/.claude
ln -sf "$DOTFILES_DIR/.claude/settings.json" ~/.claude/settings.json
ln -sf "$DOTFILES_DIR/.claude/statusline-command.sh" ~/.claude/statusline-command.sh

# Ghostty config
if [ -d "$DOTFILES_DIR/.config/ghostty" ]; then
  mkdir -p ~/.config/ghostty
  ln -sf "$DOTFILES_DIR/.config/ghostty/config" ~/.config/ghostty/config
fi

# Karabiner config
if [ -d "$DOTFILES_DIR/.config/karabiner" ]; then
  mkdir -p ~/.config/karabiner
  ln -sf "$DOTFILES_DIR/.config/karabiner/karabiner.json" ~/.config/karabiner/karabiner.json
fi

# BetterTouchTool preset
if [ -d "$DOTFILES_DIR/.config/bettertouchtool" ]; then
  mkdir -p ~/.config/bettertouchtool
  ln -sf "$DOTFILES_DIR/.config/bettertouchtool/Default.bttpreset" ~/.config/bettertouchtool/Default.bttpreset
fi

echo "==> Installing Zim framework..."
if [[ ! -d ~/.zim ]]; then
  curl -fsSL --create-dirs -o ~/.zim/zimfw.zsh \
    https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  zsh -c 'source ~/.zim/zimfw.zsh init && zimfw install'
fi

echo "==> Installing Node.js via fnm..."
eval "$(fnm env)"
fnm install 22
fnm default 22

echo "==> Configuring macOS system settings..."
# Dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock tilesize -int 88
# Finder
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
# Keyboard repeat
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
# Trackpad: tap to click
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
# Apply Dock changes
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true

echo "==> Done! Restart your terminal."
echo ""
echo "==> 手動で必要な設定:"
echo "  1. git user 設定:"
echo "       git config --global user.name '名前'"
echo "       git config --global user.email 'メールアドレス'"
echo "  2. GitHub 認証: gh auth login"
echo "  3. gcloud 認証: gcloud auth login"
echo "  4. SSH 鍵: ssh-keygen -t ed25519 -C 'your@email.com'"
echo "  5. Karabiner / BetterTouchTool: システム設定でアクセシビリティを許可"
