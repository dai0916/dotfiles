# Orca の Setup などは bash -lc で動くので、zsh と同じ PATH にする（中身は .zprofile と同じ）
eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(/opt/homebrew/bin/mise activate bash --shims)"
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
