# ログインシェル用。GUI アプリやエージェント（Claude Code / Codex / Orca）から起動されるシェルもここを読む
eval "$(/opt/homebrew/bin/brew shellenv)"
# 非対話シェルでも PJ ごとの node / pnpm が使えるよう、mise の shims を PATH に入れる（対話シェルは .zshrc の mise activate が上書きする）
eval "$(/opt/homebrew/bin/mise activate zsh --shims)"
# ~/.local/bin: Claude Code・uv の python3 など / ~/go/bin: go install で入れた自作ツール
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
