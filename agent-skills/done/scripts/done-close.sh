#!/usr/bin/env bash
# 出荷したあとの issue の締め（done スキルの 4 を 1 回で行う）。
#   1. 出荷済みか確かめる（lib.sh の check_shipped）。未出荷なら何もしないで止める
#   2. issue が Epic（子 issue を持つ）で、開いている子が残っていれば閉じずに止める
#   3. issue がまだ開いていれば「<コミット or PR> で出荷」とコメントして閉じる
#   4. 親の Epic があれば、残りの子のうち着手できるものを一覧にする（ワークツリーは開かない）
# 使い方: done-close.sh <issue> [--base <リリース先。省略時はリポジトリの既定ブランチ>]
# 1 行目に close_status=<closed|already_closed|not_shipped|epic_open|error>、以降に内訳。常に exit 0（判断は呼び出し側）。
set -uo pipefail
. "$(cd "$(dirname "$0")" && pwd)/lib.sh"
STATUS_KEY=close_status

issue="${1:-}"; [ $# -gt 0 ] && shift
base=''
while [ $# -gt 0 ]; do
  case "$1" in
    --base) [ $# -ge 2 ] || die '--base に値が無い'; base="$2"; shift 2 ;;
    *) die "unknown option: $1" ;;
  esac
done
case "$issue" in ''|*[!0-9]*) die 'usage: done-close.sh <issue> [--base <branch>]' ;; esac
for c in gh jq git; do command -v "$c" >/dev/null 2>&1 || die "$c が見つからない"; done
repo=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null) || die 'GitHub のリポジトリが分からない'
resolve_base "$base"

check_shipped
if [ -z "$shipped_via" ]; then
  echo 'close_status=not_shipped'
  echo "HEAD（$(git rev-parse --short HEAD)）が origin/$base に入っておらず、この HEAD のまま $base にマージされた PR も無い"
  exit 0
fi

# 子 issue の一覧（取得に失敗したら「子が無い」と読み違えない）
sub_issues() {
  local raw
  raw=$(gh api "repos/$repo/issues/$1/sub_issues" --paginate 2>/dev/null) || return 1
  jq -s 'if all(.[]; type == "array") then add // [] else error("not array") end' <<<"$raw" 2>/dev/null
}

subs=$(sub_issues "$issue") || die "#$issue の子 issue を取得できない"
open_children=$(jq -r '[.[] | select(.state == "open") | "#\(.number)"] | join(" ")' <<<"$subs")
if [ -n "$open_children" ]; then
  echo 'close_status=epic_open'
  echo "#$issue は Epic で、開いている子が残っている: $open_children"
  exit 0
fi

state=$(gh issue view "$issue" --json state -q .state 2>/dev/null) || die "issue #$issue が読めない"
if [ "$state" = OPEN ]; then
  gh issue close "$issue" --comment "$shipped_via で出荷" >/dev/null 2>&1 || die "issue #$issue を閉じられない"
  echo 'close_status=closed'
else
  echo 'close_status=already_closed'
fi
echo "shipped=$shipped_via"

# 親の Epic。親が無いときは 404。それ以外の失敗（認証・上限・障害）は「親なし」と区別して伝える
if ! parent=$(gh api "repos/$repo/issues/$issue/parent" -q .number 2>&1); then
  case "$parent" in
    *'No parent issue found'*|*'HTTP 404'*) echo 'epic=none' ;;
    *) echo "epic=error（親の Epic を調べられない: $(printf '%s' "$parent" | tail -n 1)）" ;;
  esac
  exit 0
fi
psubs=$(sub_issues "$parent") || { echo "epic=#${parent}（子 issue を取得できない）"; exit 0; }
if [ "$(jq '[.[] | select(.state == "open")] | length' <<<"$psubs")" -eq 0 ]; then
  echo "epic=#$parent 子はすべて閉じた（Epic のワークツリーで done を）"
  exit 0
fi
ready=''; waiting=''
while IFS=$'\t' read -r n hold; do
  if [ "$hold" = true ]; then waiting="$waiting #$n(on-hold)"; continue; fi
  by=$(gh api "repos/$repo/issues/$n/dependencies/blocked_by" --paginate -q '[.[] | select(.state == "open") | "#\(.number)"] | join(",")' 2>/dev/null) \
    || { waiting="$waiting #$n(前提を確かめられない)"; continue; }
  if [ -n "$by" ]; then waiting="$waiting #$n(←$by)"; else ready="$ready #$n"; fi
done < <(jq -r 'sort_by(.number)[] | select(.state == "open") | [.number, ([.labels[]?.name] | index("on-hold") != null)] | @tsv' <<<"$psubs")
echo "epic=#$parent"
echo "着手できる子:${ready:- なし}"
echo "前提待ち・保留:${waiting:- なし}"
exit 0
