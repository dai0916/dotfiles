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

echo "==> Done! Restart your terminal."
