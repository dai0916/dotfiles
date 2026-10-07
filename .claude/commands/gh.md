# GitHub Issue 管理

引数に応じて Issue 操作を実行する。

引数: `$ARGUMENTS`

---

## サブコマンド判定

`$ARGUMENTS` の内容に応じて以下を実行する:

### 引数なし or `list` → Issue 一覧

```bash
gh issue list --limit 20
```

### `new` → 新規 Issue 作成

ユーザーに以下を順番に質問する:

1. **タイトル**（必須）
2. **カテゴリ**（feature / bug / refactor / docs）
3. **内容**（必須 — 何をするか）
4. **受け入れ条件**（任意 — 空なら省略）
5. **関連 docs**（任意 — 空なら省略）

すべて揃ったら Issue を作成:

```bash
gh issue create \
  --title "タイトル" \
  --label "カテゴリ" \
  --body "$(cat <<'EOF'
## カテゴリ
feature

## 内容
（ユーザーの回答）

## 受け入れ条件
（ユーザーの回答 or なし）

## 関連 docs
（ユーザーの回答 or なし）
EOF
)"
```

作成後、Issue 番号と URL を表示する。

### 数字 → Issue 詳細表示

```bash
gh issue view $ARGUMENTS
```

### `close <番号>` → Issue クローズ

```bash
gh issue close <番号>
```
