# done-close.sh と done-cleanup.sh が共有する関数（source して使う）

# 結果の 1 行目（<key>=error）と理由を出して終わる。どのスクリプトも exit 0（判断は呼び出し側）
# 途中で済ませた操作は note で貯め、状態の行のあとに出す（1 行目を必ず状態にするため）
STATUS_KEY=status
INFO=''
note() { INFO="$INFO$1"$'\n'; }
die() { echo "$STATUS_KEY=error"; echo "$1"; printf '%s' "$INFO"; exit 0; }

# リリース先のブランチ（引数が空ならリポジトリの既定ブランチ）を決め、origin から取り直す
# 追跡ブランチを明示して取る（single-branch の clone では origin/<base> が更新されず、古い参照で判定してしまう）
resolve_base() {
  base="$1"
  [ -n "$base" ] || base=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null)
  [ -n "$base" ] || die 'リリース先のブランチが分からない（--base で渡す）'
  git fetch -q origin "+refs/heads/$base:refs/remotes/origin/$base" 2>/dev/null \
    || die "origin/$base を取得できない（古い参照のまま出荷済みと判定しない）"
}

# HEAD が出荷済みかを判定し、shipped_via に「<コミット>」か「PR #<番号>」を入れる（未出荷なら空）
#   - HEAD が origin/<base> に入っている
#   - または、このブランチの PR が HEAD のまま <base> にマージされ、そのマージコミットが origin/<base> に入っている（squash / rebase マージ）
# PR を調べられなかったとき（認証・通信）は「未出荷」と区別して die する
check_shipped() {
  shipped_via=''
  local head sha branch pr err
  head=$(git rev-parse HEAD)
  sha=$(git rev-parse --short HEAD)
  if git merge-base --is-ancestor HEAD "origin/$base" 2>/dev/null; then
    shipped_via="$sha"; return
  fi
  branch=$(git branch --show-current)
  [ -n "$branch" ] || return
  err=$(mktemp)
  if ! pr=$(gh pr view "$branch" --json number,state,baseRefName,headRefOid,mergeCommit 2>"$err"); then
    if grep -qi 'no pull requests found' "$err"; then rm -f "$err"; return; fi
    local msg; msg=$(tail -n 1 "$err"); rm -f "$err"
    die "PR を調べられない（${msg}）"
  fi
  rm -f "$err"
  local state prbase prhead merge
  state=$(jq -r .state <<<"$pr"); prbase=$(jq -r .baseRefName <<<"$pr")
  prhead=$(jq -r .headRefOid <<<"$pr"); merge=$(jq -r '.mergeCommit.oid // empty' <<<"$pr")
  if [ "$state" = MERGED ] && [ "$prbase" = "$base" ] && [ "$prhead" = "$head" ] && [ -n "$merge" ] \
    && git merge-base --is-ancestor "$merge" "origin/$base" 2>/dev/null; then
    shipped_via="PR #$(jq -r .number <<<"$pr")"
  fi
}
