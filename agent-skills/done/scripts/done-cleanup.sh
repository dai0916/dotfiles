#!/usr/bin/env bash
# 出荷済みのワークツリーを片付ける（done スキルの 5 の最後に 1 回だけ実行する）。
#   1. 作業ツリーがきれいで、HEAD が出荷済み（lib.sh の check_shipped）なのを確かめ直す
#   2. リモートのブランチが残っていれば、その先端が HEAD か origin/<base> に入っているときだけ、
#      確かめた先端から動いていないことを条件に（--force-with-lease）消す
#   3. ローカルのブランチを消し、Orca のワークツリーを消す（このセッションのターミナルも閉じる）
# 使い方: done-cleanup.sh [--base <リリース先>] [--no-orca（Orca の外で作ったワークツリー。最後の削除だけ行わない）]
# 1 行目に cleanup_status=<done|error>、以降に内訳。常に exit 0。
set -uo pipefail
. "$(cd "$(dirname "$0")" && pwd)/lib.sh"
STATUS_KEY=cleanup_status

base=''; orca=1
while [ $# -gt 0 ]; do
  case "$1" in
    --base) [ $# -ge 2 ] || die '--base に値が無い'; base="$2"; shift 2 ;;
    --no-orca) orca=0; shift ;;
    *) die "unknown option: $1" ;;
  esac
done
for c in gh jq git; do command -v "$c" >/dev/null 2>&1 || die "$c が見つからない"; done
[ "$orca" -eq 0 ] || command -v orca >/dev/null 2>&1 || die 'orca が見つからない（Orca の外のワークツリーなら --no-orca）'

status=$(git status --porcelain) || die '作業ツリーの状態を確かめられない（片付けない）'
[ -z "$status" ] || die '未コミットの変更がある（片付けない）'
B=$(git branch --show-current)
[ -n "$B" ] || die 'ブランチが無い（detached）'
[ "$(git rev-parse --path-format=absolute --git-dir)" != "$(git rev-parse --path-format=absolute --git-common-dir)" ] \
  || die 'PJ の本体（メインのワークツリー）では片付けない'
resolve_base "$base"
[ "$B" != "$base" ] || die "リリース先のブランチ（${base}）は消さない"

check_shipped
[ -n "$shipped_via" ] || die "HEAD が出荷されていない（origin/$base にも、マージされた PR にも無い）"

# リモートのブランチ（rebase 前のコピーなど）
remote=$(git ls-remote origin "refs/heads/$B" 2>/dev/null) || die 'origin のブランチを調べられない'
tip=$(cut -f1 <<<"$remote")
if [ -n "$tip" ]; then
  git fetch -q origin "$tip" 2>/dev/null || die "origin/$B の先端（${tip}）を取得できない"
  # 先端が HEAD そのもの・origin/<base> に入っている・rebase 前のコピーで変更がすべて origin/<base> にある（git cherry に + が無い）のどれか
  if [ "$tip" != "$(git rev-parse HEAD)" ] && ! git merge-base --is-ancestor "$tip" "origin/$base"; then
    # git cherry はマージコミットを見ないので、取り込まれていないマージコミットがあれば止める
    merges=$(git rev-list --merges "origin/$base..$tip" 2>/dev/null) || die "origin/$B を origin/$base と比べられない"
    [ -z "$merges" ] || die "origin/$B に origin/$base へ入っていないマージコミットがある。消さずに止める"
    cherry=$(git cherry "origin/$base" "$tip" 2>/dev/null) || die "origin/$B を origin/$base と比べられない"
    ! grep -q '^+' <<<"$cherry" || die "origin/$B に出荷されていないコミットがある（${tip}）。消さずに止める"
  fi
  git push -q origin --delete --force-with-lease="refs/heads/$B:$tip" "$B" 2>/dev/null \
    || die "origin/$B を消せない（確かめたあとに更新された可能性がある）"
  note "deleted_remote=$B"
fi

top=$(git rev-parse --show-toplevel)
git switch -q --detach || die 'detached に切り替えられない'
git branch -D -q "$B" || die "ローカルのブランチ $B を消せない"
note "deleted_local=$B"
if [ "$orca" -eq 0 ]; then
  echo 'cleanup_status=done'; printf '%s' "$INFO"
  echo "最後に本体で: git -C <本体のパス> worktree remove $top"
elif orca worktree rm --worktree active --json >/dev/null 2>&1; then
  # 成功するとこのターミナルも閉じるので、ここは表示されないことがある（報告は先に済ませておく）
  echo 'cleanup_status=done'; printf '%s' "$INFO"
else
  # ブランチは消してあるので再実行では戻せない。残ったワークツリーを明示する
  echo 'cleanup_status=partial'; printf '%s' "$INFO"
  echo "Orca のワークツリーを消せなかった（${top}）。Orca から消すか、本体で git worktree remove する"
fi
exit 0
