# dotfiles

macOS (Apple Silicon) の開発環境を再現するための dotfiles。

## セットアップ

```bash
git clone https://github.com/dai0916/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
```

`setup.sh` が以下を自動で行う：

1. Homebrew のインストール（未導入の場合）
2. CLI ツール・GUI アプリのインストール
3. 設定ファイルのシンボリックリンク作成
4. Zim フレームワークのインストール
5. Node.js (v22) のインストール（fnm 経由）

## 構成

```
~/dotfiles/
├── .zshrc                    # シェル設定（メイン）
├── .zprofile                 # ログインシェル設定（Homebrew shellenv）
├── .zimrc                    # Zim プラグインマネージャ設定
├── .config/
│   ├── starship.toml         # Starship プロンプト設定
│   ├── ghostty/config        # Ghostty ターミナル設定
│   └── karabiner/            # Karabiner-Elements 設定
└── setup.sh                  # 環境構築スクリプト
```

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

## Ghostty ターミナル設定

- テーマ: Catppuccin Mocha
- フォント: HackGen Console NF (size 21)
- 背景透過: 30%
- タイトルバー非表示
- Ctrl+A/B/E/F/N/P を unbind（readline カーソル操作との競合回避）

## Karabiner-Elements

キーボードカスタマイズ設定。詳細は `.config/karabiner/karabiner.json` を参照。

## Starship プロンプト

Nerd Font アイコンを使用したプロンプト。表示内容：

- カレントディレクトリ（リポジトリルートから3階層）
- Git ブランチ・ステータス
- Node.js / Go / Python / Rust バージョン（プロジェクト検出時のみ）
- コマンド実行時間（3秒以上の場合）

## インストールされるフォント

| フォント | 特徴 |
|----------|------|
| Cica | 日本語対応コーディングフォント |
| HackGen Nerd | Hack + 源柔ゴシック + Nerd Font |
| FirgeNerd | Fira Code + 源真ゴシック + Nerd Font |
| Moralerspace | 等幅プログラミングフォント |
| PlemolJP NF | IBM Plex Mono + IBM Plex Sans JP + Nerd Font |
| UDEV Gothic NF | UDEV Gothic + Nerd Font |

## インストールされる GUI アプリ

<details>
<summary>一覧を表示</summary>

| アプリ | カテゴリ |
|--------|---------|
| 1Password | パスワード管理 |
| AppCleaner | アプリ削除 |
| BetterTouchTool | 入力カスタマイズ |
| Claude | AI アシスタント |
| CleanShot | スクリーンショット |
| cmux | Claude Code ターミナル |
| CotEditor | テキストエディタ |
| Cursor | AI エディタ |
| Discord | コミュニケーション |
| Ghostty | ターミナルエミュレータ |
| Google Chrome | ブラウザ |
| Google 日本語入力 | IME |
| Heptabase | ビジュアルノート |
| Karabiner-Elements | キーボードカスタマイズ |
| Notion | ドキュメント |
| Obsidian | ナレッジベース |
| Raycast | ランチャー |
| Slack | コミュニケーション |
| Visual Studio Code | エディタ |
| VLC | メディアプレイヤー |
| Warp | ターミナルエミュレータ |

</details>
