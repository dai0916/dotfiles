# 共通（個人用・仕事用の両方に入れる）。bootstrap.sh から brew bundle される
# 方針: 毎日使うものだけ。たまに使うものは、必要になったときに brew install する
# jq と sqlite3 は macOS 標準のものを使う。node / pnpm は mise、python は uv で入れる

# --- CLI ---
brew "gh"
brew "ripgrep"
brew "mise"
brew "uv"
brew "direnv"
brew "eza"
brew "starship"
brew "imagemagick"
brew "unar"
brew "mas"

# --- アプリ ---
cask "google-chrome"
cask "cmux"                # ターミナル。Ghostty の設定（~/.config/ghostty/config）を読む
cask "claude"              # デスクトップ版。Claude Code CLI は agent-harness の setup-agents.sh がネイティブインストーラで入れる
cask "chatgpt"
cask "codex"               # Codex CLI。npm 版とは同時に入れない
cask "1password"
cask "1password-cli"
cask "raycast"
cask "karabiner-elements"
cask "google-japanese-ime"   # 入力ソースへの追加は手作業（README の手作業の手順）
cask "orbstack"            # Docker 互換。使うときだけ起動する

# Orca（AI エージェントのワークツリー管理）。公式の orca は別のアプリなので tap から入れる。
# サードパーティ tap なので、bootstrap.sh が brew trust してからこの Brewfile を流す
tap "stablyai/orca"
cask "stablyai/orca/orca"

# --- フォント（cmux / Ghostty の設定で使っている2つ） ---
cask "font-jetbrains-mono-nerd-font"
cask "font-line-seed-jp"
