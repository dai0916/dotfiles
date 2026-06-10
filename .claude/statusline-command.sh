#!/usr/bin/env bash
# Claude Code statusLine command - based on asciiship zsh theme

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# Shorten cwd: replace $HOME with ~
home="$HOME"
if [ -n "$cwd" ]; then
  short_cwd="${cwd/#$home/~}"
else
  short_cwd="$(pwd)"
  short_cwd="${short_cwd/#$home/~}"
fi

# Git info (skip optional locks)
git_part=""
if git -C "${cwd:-$(pwd)}" rev-parse --is-inside-work-tree --no-optional-locks 2>/dev/null | grep -q true; then
  branch=$(git -C "${cwd:-$(pwd)}" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || \
           git -C "${cwd:-$(pwd)}" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  status_flags=""
  git_status=$(git -C "${cwd:-$(pwd)}" --no-optional-locks status --porcelain 2>/dev/null)
  if echo "$git_status" | grep -q '^[MADRCU]'; then
    status_flags="${status_flags}+"
  fi
  if echo "$git_status" | grep -q '^ [MADRCU?]'; then
    status_flags="${status_flags}!"
  fi
  ahead=$(git -C "${cwd:-$(pwd)}" --no-optional-locks rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
  behind=$(git -C "${cwd:-$(pwd)}" --no-optional-locks rev-list --count HEAD..@{u} 2>/dev/null || echo "0")
  [ "$ahead" -gt 0 ] 2>/dev/null && status_flags="${status_flags}>"
  [ "$behind" -gt 0 ] 2>/dev/null && status_flags="${status_flags}<"
  if [ -n "$status_flags" ]; then
    git_part=" on ${branch} [${status_flags}]"
  else
    git_part=" on ${branch}"
  fi
fi

# Model info
model_part=""
[ -n "$model" ] && model_part=" | ${model}"

# Context remaining
ctx_part=""
if [ -n "$remaining" ]; then
  ctx_part=" | ctx: ${remaining}%"
fi

# Vim mode
vim_part=""
if [ -n "$vim_mode" ]; then
  vim_part=" | ${vim_mode}"
fi

printf "\033[36m%s\033[0m%s%s%s%s" \
  "${short_cwd}" \
  "${git_part}" \
  "${model_part}" \
  "${ctx_part}" \
  "${vim_part}"
