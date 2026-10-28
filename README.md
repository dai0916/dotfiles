# dotfiles

macOS（Apple Silicon）の開発環境を、どの端末でも同じように再現するための dotfiles。個人用と仕事用の両方を扱う。

公開リポジトリなので、置くのは一般的なインストール・設定の情報だけ。シークレットや個人 PJ 固有の設定は入れない。

## 方針

- **最小構成**: 毎日使うものだけを入れる。たまに使うものは、必要になったときに `brew install` / `uvx` / `pnpm dlx` で入れる
- **PJ の CLI は PJ に置く**: supabase・vercel・playwright・wrangler などは、各リポジトリの devDependencies に入れる（グローバルには入れない）
- **ランタイムは mise と uv**: node / pnpm は mise、python は uv で管理する。brew の node・fnm は使わない

## セットアップ

```bash
xcode-select --install                                   # ダイアログが閉じるまで待つ
git clone https://github.com/dai0916/dotfiles.git ~/dotfiles
~/dotfiles/bootstrap.sh personal                         # 仕事用の端末なら work
```

`bootstrap.sh` は何度実行してもよい。次の順に進む：

1. Homebrew を入れる（未導入の場合）
2. `Brewfile`（共通）と `Brewfile.personal` / `Brewfile.work` を `brew bundle` する。1つ失敗しても残りは入れて、最後にまとめて報告する
3. `link.sh`: 設定ファイルをホームにシンボリックリンクする（既存の実体は `.bak-<日時>` に退避）
4. `mise install`（node 24 LTS / pnpm）と `uv python install --default`（python3）
5. AI エージェントの設定（ハーネス用のリポジトリが手元にあれば、その `setup-agents.sh`。下の「AI エージェント」を参照）
6. `macos.sh`: Dock・Finder・スクロールなどの設定

App Store のアプリ（`mas`）は、先に App Store にサインインしておかないと失敗する。

### セットアップ後に手でやること

```bash
gh auth login        # アカウントごとに繰り返す
gh auth setup-git    # git の HTTPS 認証を gh に任せる（SSH 鍵は作らない）
op signin            # 1Password CLI
```

- Karabiner-Elements・Raycast・Mos などに、システム設定 → プライバシーとセキュリティ → アクセシビリティで許可を出す
- Raycast の Settings → Extensions → Script Commands → Add Directories で `~/dotfiles/raycast/script-commands` を登録する
- システム設定 → キーボード → 入力ソースで Google 日本語入力（ひらがな・英数）を追加し、標準の日本語を外す
- 仕事用: `gcloud auth login`

## 構成

```
~/dotfiles/
├── bootstrap.sh            # 入口（personal | work）
├── Brewfile                # 共通
├── Brewfile.personal       # 個人用の追加分
├── Brewfile.work           # 仕事用の追加分
├── link.sh                 # シンボリックリンク
├── macos.sh                # macOS のシステム設定
├── .zshrc .zprofile .zimrc .bash_profile .vimrc
├── .config/
│   ├── mise/config.toml    # グローバルの node / pnpm
│   ├── starship.toml
│   ├── ghostty/config      # cmux も読む
│   ├── karabiner/karabiner.json
│   ├── bettertouchtool/    # BetterTouchTool を手で入れた端末でだけリンク
│   └── git/ignore
└── raycast/script-commands/        # Raycast の Script Commands（Raycast にフォルダを登録して使う）
```

## シェル

Zsh + [Zim](https://zimfw.sh/)（autosuggestions / syntax-highlighting / history-substring-search）+ [Starship](https://starship.rs/)。

| ファイル | 読まれる場面 | 中身 |
|---|---|---|
| `.zprofile` | ログインシェル（ターミナル・GUI アプリ・エージェント） | Homebrew、mise の shims、`~/.local/bin` と `~/go/bin` |
| `.bash_profile` | Orca の Setup など `bash -lc` | `.zprofile` と同じ |
| `.zshrc` | 対話シェル | Zim、`mise activate`、direnv、eza の alias、Starship |

エージェントや Orca が起動する非対話シェルでも、PJ の `mise.toml` / `.node-version` に従った node が使われる。

## AI エージェント（Claude Code / Codex / Orca）

Claude Code と Codex の全体ルール・スキル・フック（ハーネス）は、別の非公開リポジトリ `agent-harness` で管理している。dotfiles には端末の設定だけを置く。

`bootstrap.sh` は `${AGENT_HARNESS_DIR:-~/work/projects/agent-harness}` に `setup-agents.sh` があれば実行する。無ければ飛ばすので、`gh auth login` の後に clone してから実行する：

```bash
gh repo clone <owner>/agent-harness ~/work/projects/agent-harness
~/work/projects/agent-harness/setup-agents.sh
```

その後の手順は `agent-harness` の README に従う。

## ターミナル設定（cmux / Ghostty 共通の `~/.config/ghostty/config`）

- テーマ: Catppuccin Mocha
- フォント: JetBrains Mono Nerd Font + LINE Seed JP (size 21)
- 背景透過: 50%
- タイトルバー非表示

## Karabiner-Elements

| ルール | 内容 |
|--------|------|
| Ctrl+p/n → ↑/↓ | 矢印キーをホームポジションから操作 |
| Ctrl+[W/T/C/V/X/Z/Q/R/S] → Cmd+同キー | Warp・Raycast・Ghostty・cmux 以外で有効 |
| Cmd 単押し → 英数/かなトグル | 左右どちらの Cmd でも動作 |

## Raycast Script Commands（`raycast/script-commands/`）

| スクリプト | 内容 |
|---|---|
| restart-stream-deck.sh | Stream Deck を再起動し、開いたウィンドウを閉じる |
