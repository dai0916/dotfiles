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
5. `setup-agents.sh`: Claude Code / Codex の設定（下の「AI エージェント」を参照）
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
├── setup-agents.sh         # Claude Code / Codex の設定を配置
├── .zshrc .zprofile .zimrc .bash_profile .vimrc
├── .config/
│   ├── mise/config.toml    # グローバルの node / pnpm
│   ├── starship.toml
│   ├── ghostty/config      # cmux も読む
│   ├── karabiner/karabiner.json
│   ├── bettertouchtool/    # BetterTouchTool を手で入れた端末でだけリンク
│   └── git/ignore
├── raycast/script-commands/        # Raycast の Script Commands（Raycast にフォルダを登録して使う）
├── .claude/ .codex/ agent-skills/   # AI エージェントの設定（下を参照）
└── NOTICE                  # 第三者のソフトウェアの出典（japanese-guard）
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

Orca で issue ごとにワークツリーを開き、Claude Code と Codex を併用する環境。
`setup-agents.sh`（`bootstrap.sh` から呼ばれる。単体で何度実行してもよい）が次を行う：

- エージェント・フック・スキル・`AGENTS.md` を `~/.claude` / `~/.codex` にシンボリックリンクする（既存の実体は `.bak-<日時>` に退避）
- `~/.claude/settings.json` に `settings.base.json` を足し込む。Orca やアプリが書き込むファイルなのでリンクにはしない。既存のキーとフックは残す
- `~/.codex/config.toml` が無ければ `config.base.toml` から作る（あれば触らない）
- `~/.codex/hooks.json` の Stop に `japanese-guard.py` を足す

ここに入れているのはどの PJ でも使える設定だけ。PJ 固有のルールとフックは、各リポジトリの `.claude/settings.json` と `AGENTS.md` で配る。

### issue の流れ

1 issue = 1 ワークツリー = 1 ブランチ。

1. 着手：Orca のタスク一覧から issue のワークツリーを開く（エージェントに issue が渡される）→ 計画の承認 → 実装・検証
2. 出荷：確認 OK なら同じワークツリーで `/done`（`agent-skills/done`）。commit 前の別系統レビュー → PJ の `AGENTS.md`「出荷手順」節 → issue を close → ブランチとワークツリーを削除
   - PR のマージを他の人が行う PJ では、`/done` は PR を出して止まる。マージ後にもう一度 `/done` で close と片付け（squash マージでも出荷済みと判定する）
   - 各 PJ の `AGENTS.md` に「出荷手順」節（確認 / 出荷 / 片付け）を書いておくと、`/done` がそのとおりに進める
承認なしで進める設定（Claude の `skipDangerousModePermissionPrompt`、Codex の `approval_policy = "never"`）と Codex の memories は既定で入れていない。環境の方針に合わせて手で有効にする。

セットアップ後の手順：

1. `claude` を起動して `/login`、`codex login`
2. Claude Code で `/codex:setup` を実行し、Codex との連携を確かめる
3. Codex を初めて起動したら、`japanese-guard.py` のフックを信頼する
4. Orca でリポジトリを登録し、setup を `pnpm install` にして `wait-for-setup` を有効にする
5. Orca から Claude と Codex を一度起動する（Orca が自分のフックを settings.json / hooks.json に書き込む）

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
