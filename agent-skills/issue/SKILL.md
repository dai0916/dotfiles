---
name: issue
description: GitHub Issue を読み込み、設計方針の承認 → 設計書の更新 → 実装 → テスト → ユーザー確認待ちまで進める。ユーザーが「/issue 番号」「この issue をやって」と言ったときに使う
---

# issue

引数: `$ARGUMENTS`（issue 番号）

Claude Code で、この PJ の `.claude/settings.json` の `enabledPlugins` に `lifeos-harness@lifeos` があるなら、Skill ツールで **`lifeos-harness:issue`** を引数 `$ARGUMENTS` で呼び、その手順だけに従う（以下は読まない）。

それ以外の PJ では、引数で指定された GitHub Issue を、設計書主導ワークフロー（AGENTS.md）に従って対応する。

## 手順

### Step 1: Issue 内容の取得

```bash
gh issue view $ARGUMENTS
gh issue view $ARGUMENTS --comments
```

Issue のタイトル、本文、ラベル、受け入れ条件に加え、コメントも確認する。
コメントに追加要件や方針変更がある場合はそれも考慮すること。

### Step 2: 現状把握と設計方針の策定

1. Issue に「関連 docs」の記載があればそのファイルを直接読む
2. **コードベース調査は Explore subagent に委譲する**（メインコンテキスト節約）
   - 影響範囲の洗い出し・関連ファイルの特定・既存実装パターンの調査は `Agent(subagent_type="Explore")` で並列化
   - thoroughness は Issue 規模に応じて `quick` / `medium` / `very thorough` を選ぶ
   - プロンプトは自己完結させる（Issue 本文・制約・期待する成果物を明記）
3. Explore からの報告を受けて、自分で設計方針を構築する（synthesis は委譲しない）
4. **設計方針（どの docs をどう変更するか、コードの変更箇所）をユーザーに提示して承認を得る**

> ⚠️ ユーザーの承認なしに Step 3 以降に進んではならない。

### Step 3: 設計書の更新

ユーザーの承認後:
1. 関連する `docs/` ファイルを更新する
2. 設計変更が大きい場合は差分をユーザーに見せて再確認する

### Step 4: コードの実装

設計書に基づいてコードを実装する。AGENTS.md と `.claude/rules/` の注意点に従う。

### Step 5: テスト

AGENTS.md の完了条件（型チェック・lint・テスト）を満たすまで検証する。UI を変えたら Playwright で動作を確かめる（PJ の `.claude/rules/` に手順があればそれに従う）。
手動確認が必要な点が残れば、ユーザーに報告する。

### Step 6: ユーザー確認待ち

テスト完了後、ユーザーに手動確認を依頼する。
ユーザーが確認を終えたら `/done $ARGUMENTS` でクロージングする。
