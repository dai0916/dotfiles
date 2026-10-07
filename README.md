# dotfiles

macOS (Apple Silicon) 仕事用開発環境を再現するための dotfiles。

## セットアップ

```bash
git clone https://github.com/dai0916/dotfiles.git ~/work/dotfiles
cd ~/work/dotfiles
./setup-work.sh
```

`setup-work.sh` が以下を自動で行う：

1. Homebrew のインストール（未導入の場合）
2. CLI ツールのインストール
3. GUI アプリのインストール
4. 設定ファイルのシンボリックリンク作成
5. Zim フレームワークのインストール
6. Node.js (v22) のインストール（fnm 経由）
7. macOS システム設定（Dock・Finder・キーボード・トラックパッド）

## セットアップ後の手動手順

スクリプトでは自動化できない設定を手動で行う。

### 1. git ユーザー設定

```bash
git config --global user.name "名前"
git config --global user.email "メールアドレス"
```

### 2. GitHub 認証

```bash
gh auth login
```

複数アカウントを使う場合は繰り返す。

### 3. gcloud 認証

```bash
gcloud auth login
gcloud config set project <PROJECT_ID>
```

### 4. SSH 鍵の生成

```bash
ssh-keygen -t ed25519 -C "your@email.com"
# 公開鍵を GitHub に登録
cat ~/.ssh/id_ed25519.pub | pbcopy
```

### 5. アプリの許可設定

- **Karabiner-Elements**: システム設定 → プライバシーとセキュリティ → アクセシビリティで許可
- **BetterTouchTool**: 同上 + ライセンス認証が必要
- **Raycast**: システム設定 → プライバシーとセキュリティ → アクセシビリティで許可

## 構成

```
~/work/dotfiles/
├── .zshrc                         # シェル設定（メイン）
├── .zprofile                      # ログインシェル設定（Homebrew shellenv）
├── .zimrc                         # Zim プラグインマネージャ設定
├── .vimrc                         # Vim 設定
├── .config/
│   ├── starship.toml              # Starship プロンプト設定
│   ├── ghostty/config             # Ghostty ターミナル設定
│   ├── karabiner/karabiner.json   # Karabiner-Elements 設定
│   ├── bettertouchtool/           # BetterTouchTool プリセット
│   └── git/ignore                 # グローバル .gitignore
├── .claude/                       # Claude Code（~/.claude へ配置）
│   ├── settings.base.json         # settings.json に足し込むひな形
│   ├── statusline.sh              # ステータスライン
│   ├── agents/                    # サブエージェント（investigator / routine）
│   ├── hooks/japanese-guard.py    # 英語の回答を日本語で書き直させる Stop フック
│   ├── commands/gh.md             # /gh（GitHub Issue 操作）
│   └── skills/ui-review/          # Playwright で UI をレビューするスキル
├── .codex/                        # Codex（~/.codex へ配置）
│   ├── AGENTS.md                  # グローバル指示（モデルの使い分け・クロスレビュー）
│   ├── config.base.toml           # config.toml のひな形（無いときだけ書き出す）
│   ├── agents/                    # サブエージェント
│   ├── hooks/japanese-guard.py    # Claude 版と同じフックの Codex 版
│   └── skills/search-router/      # Web 検索の手段を選ぶスキル
├── agent-skills/done/             # /done（Claude Code と Codex の両方に配置）
├── setup-agents.sh                # Claude Code / Codex の設定を配置（setup-work.sh から呼ぶ）
├── NOTICE                         # 第三者のソフトウェアの出典（japanese-guard）
├── setup-work.sh                  # 仕事用環境構築スクリプト
└── setup.sh                       # 個人用環境構築スクリプト
```

## AI エージェント（Claude Code / Codex / Orca）

Orca で issue ごとにワークツリーを開き、Claude Code と Codex を併用する環境。
`setup-agents.sh`（`setup-work.sh` から呼ばれる。単体で何度実行してもよい）が次を行う：

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

## 自動設定される macOS システム設定

| 設定 | 値 |
|------|-----|
| Dock 自動非表示 | 有効 |
| Dock サイズ | 88px |
| Dock 拡大 | 有効 |
| Finder パスバー | 表示 |
| Finder ステータスバー | 表示 |
| Finder デフォルトビュー | リスト表示 |
| キーリピート速度 | 2（最速に近い） |
| キーリピート開始までの時間 | 15 |
| トラックパッド タップでクリック | 有効 |

## 再現できないもの（手動対応）

| 項目 | 理由 |
|------|------|
| SSH 鍵 | セキュリティ上 dotfiles に含めない |
| gh / gcloud 認証トークン | 同上 |
| Raycast 設定・拡張機能 | `~/.config/raycast/` は dotfiles 未管理 |
| Arc / Warp の設定 | サインインで同期される |
| cmux 設定 | `~/.config/cmux/` は dotfiles 未管理 |
| BetterTouchTool 本体 | cask 未管理のため別途インストールが必要（プリセットは dotfiles で管理） |

## シェル環境

**Zsh + Zim Framework + Starship**

| レイヤー | 役割 | 担当 |
|----------|------|------|
| プラグイン管理 | Zsh プラグインのインストール・読み込み | [Zim](https://zimfw.sh/) |
| プロンプト | Git 状態・言語バージョン・実行時間の表示 | [Starship](https://starship.rs/) |
| 自動補完サジェスト | 履歴ベースのコマンド候補表示 | zsh-autosuggestions (Zim 経由) |
| シンタックスハイライト | コマンドの色分け表示 | zsh-syntax-highlighting (Zim 経由) |
| 履歴検索 | 部分一致で履歴を上下キー検索 | zsh-history-substring-search (Zim 経由) |

## CLI ツール

### macOS デフォルトコマンドの代替

| デフォルト | 代替 | エイリアス | 特徴 |
|-----------|------|-----------|------|
| `ls` | [eza](https://github.com/eza-community/eza) | `ls`, `ll`, `lt` | アイコン・Git status・ツリー表示 |
| `cat` | [bat](https://github.com/sharkdp/bat) | `cat` | シンタックスハイライト・行番号 |
| `cd` | [zoxide](https://github.com/ajeetdsouza/zoxide) | `z` | 頻繁に行くディレクトリを学習して高速ジャンプ |
| `grep` | [ripgrep](https://github.com/BurntSushi/ripgrep) | `rg` | .gitignore 自動尊重・高速 |
| `find` | [fd](https://github.com/sharkdp/fd) | `fd` | 直感的な構文・高速 |

### 開発ツール

| ツール | 用途 |
|--------|------|
| [fzf](https://github.com/junegunn/fzf) | ファジーファインダー（`Ctrl+R`: 履歴, `Ctrl+T`: ファイル） |
| [fnm](https://github.com/Schniz/fnm) | Node.js バージョン管理（`.node-version` 自動検出） |
| [uv](https://github.com/astral-sh/uv) | Python パッケージ・バージョン管理 |
| [direnv](https://direnv.net/) | ディレクトリ別の環境変数自動切替 |
| [gh](https://cli.github.com/) | GitHub CLI |
| [pnpm](https://pnpm.io/) | Node.js パッケージマネージャ |
| [supabase](https://supabase.com/docs/guides/cli) | Supabase CLI |
| [ffmpeg](https://ffmpeg.org/) | 動画・音声処理 |
| [keeper-commander](https://github.com/Keeper-Security/Commander) | Keeper パスワードマネージャー CLI |
| [safe-rm](https://github.com/kaelzhang/shell-safe-rm) | 安全な rm |

## Ghostty ターミナル設定

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

## インストールされるフォント

| フォント | 特徴 |
|----------|------|
| JetBrains Mono Nerd Font | メインフォント（英数字） |
| LINE Seed JP | 日本語フォント |
| 0xProto Nerd Font | プログラミング向けフォント |
| BlexMono Nerd Font | IBM Plex Mono ベース |
| Cica | 日本語対応コーディングフォント |
| HackGen Nerd | Hack + 源柔ゴシック + Nerd Font |
| FirgeNerd | Fira Code + 源真ゴシック + Nerd Font |
| Moralerspace | 等幅プログラミングフォント |
| PlemolJP NF | IBM Plex Mono + IBM Plex Sans JP + Nerd Font |
| UDEV Gothic NF | UDEV Gothic + Nerd Font |
| SF Mono for Powerline | Apple SF Mono の Powerline 版 |
| Source Han Code JP | 源ノ等幅 |

## インストールされる GUI アプリ

<details>
<summary>一覧を表示</summary>

| アプリ | カテゴリ |
|--------|---------|
| Arc | ブラウザ |
| Aqua Voice | 音声入力 |
| CleanShot | スクリーンショット |
| cmux | Claude Code ターミナル |
| Ghostty | ターミナルエミュレータ |
| Google 日本語入力 | IME |
| Google Cloud CLI | Google Cloud SDK |
| Karabiner-Elements | キーボードカスタマイズ |
| KeepingYouAwake | スリープ防止 |
| Logitech G HUB | Logicool デバイス設定 |
| SmoothCSV | CSV エディタ |
| Warp | AI ターミナル |
| XMind | マインドマップ |

※ BetterTouchTool は別途インストールが必要。プリセット（`.config/bettertouchtool/Default.bttpreset`）は dotfiles で管理。

</details>
