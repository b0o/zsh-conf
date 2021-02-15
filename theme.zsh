ZSH_THEME_GIT_PROMPT_ADDED="+"
ZSH_THEME_GIT_PROMPT_MODIFIED='*'
ZSH_THEME_GIT_PROMPT_RENAMED='R'
ZSH_THEME_GIT_PROMPT_DELETED='D'
ZSH_THEME_GIT_PROMPT_STASHED='S'
ZSH_THEME_GIT_PROMPT_UNMERGED='^'
ZSH_THEME_GIT_PROMPT_AHEAD='>'
ZSH_THEME_GIT_PROMPT_BEHIND='<'
ZSH_THEME_GIT_PROMPT_DIVERGED='='

LSCOLORS="exfxcxdxbxegedabagacad"
LS_COLORS='no=00:fi=00:di=01;34:ln=00;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=41;33;01:ex=00;32:*.cmd=00;32:*.exe=01;32:*.com=01;32:*.bat=01;32:*.btm=01;32:*.dll=01;32:*.tar=00;31:*.tbz=00;31:*.tgz=00;31:*.rpm=00;31:*.deb=00;31:*.arj=00;31:*.taz=00;31:*.lzh=00;31:*.lzma=00;31:*.zip=00;31:*.zoo=00;31:*.z=00;31:*.Z=00;31:*.gz=00;31:*.bz2=00;31:*.tb2=00;31:*.tz2=00;31:*.tbz2=00;31:*.avi=01;35:*.bmp=01;35:*.fli=01;35:*.gif=01;35:*.jpg=01;35:*.jpeg=01;35:*.mng=01;35:*.mov=01;35:*.mpg=01;35:*.pcx=01;35:*.pbm=01;35:*.pgm=01;35:*.png=01;35:*.ppm=01;35:*.tga=01;35:*.tif=01;35:*.xbm=01;35:*.xpm=01;35:*.dl=01;35:*.gl=01;35:*.wmv=01;35:*.aiff=00;32:*.au=00;32:*.mid=00;32:*.mp3=00;32:*.ogg=00;32:*.voc=00;32:*.wav=00;32:'

# Sets GITSTATUS_PROMPT to reflect the state of the current git repository. Empty if not
# in a git repository. In addition, sets GITSTATUS_PROMPT_LEN to the number of columns
# $GITSTATUS_PROMPT will occupy when printed.
#
# Example:
#
#   GITSTATUS_PROMPT='ϟ'
#   GITSTATUS_RPROMPT='master ⇣42⇡42 ⇠42⇢42 *42 merge ~42 +42 !42 ?42'
#   GITSTATUS_RPROMPT_LEN=39
#
#   master  current branch
#      ⇣42  local branch is 42 commits behind the remote
#      ⇡42  local branch is 42 commits ahead of the remote
#      ⇠42  local branch is 42 commits behind the push remote
#      ⇢42  local branch is 42 commits ahead of the push remote
#      *42  42 stashes
#    merge  merge in progress
#      ~42  42 merge conflicts
#      +42  42 staged changes
#      !42  42 unstaged changes
#      ?42  42 untracked files
function gitstatus_prompt_update() {
  emulate -L zsh
  setopt extended_glob

  typeset -g  GITSTATUS_PROMPT=''
  typeset -g  GITSTATUS_RPROMPT=''
  typeset -gi GITSTATUS_RPROMPT_LEN=0

  # Call gitstatus_query synchronously. Note that gitstatus_query can also be called
  # asynchronously; see documentation in gitstatus.plugin.zsh.
  gitstatus_query 'MY'                  || return 1  # error
  [[ $VCS_STATUS_RESULT == 'ok-sync' ]] || return 0  # not a git repo

  local      clean="%{${fg_no_bold[magenta]}%}"
  local   modified="%{${fg_no_bold[yellow]}%}"
  local  untracked="%{${fg_no_bold[cyan]}%}"
  local conflicted="%{${fg_no_bold[orange]}%}"
  local     staged="%{${fg_no_bold[green]}%}"
  local    deleted="%{${fg_no_bold[red]}%}"

  local -i c=1
  local p

  local where  # branch name, tag or commit
  if [[ -n $VCS_STATUS_LOCAL_BRANCH ]]; then
    where=$VCS_STATUS_LOCAL_BRANCH
  elif [[ -n $VCS_STATUS_TAG ]]; then
    p+='%f#'
    where=$VCS_STATUS_TAG
  else
    p+='%f@'
    where=${VCS_STATUS_COMMIT[1,8]}
  fi

  (( $#where > 32 )) && where[13,-13]="…"  # truncate long branch names and tags
  p+="${clean}${where//\%/%%} "            # escape %

  # ⇣42 if behind the remote.
  (( VCS_STATUS_COMMITS_BEHIND )) && p+="${clean}⇣${VCS_STATUS_COMMITS_BEHIND}"

  # ⇡42 if ahead of the remote; no leading space if also behind the remote: ⇣42⇡42.
  # (( VCS_STATUS_COMMITS_AHEAD && !VCS_STATUS_COMMITS_BEHIND )) && p+=" "
  (( VCS_STATUS_COMMITS_AHEAD )) && p+="${clean}⇡${VCS_STATUS_COMMITS_AHEAD}"

  # ⇠42 if behind the push remote.
  (( VCS_STATUS_PUSH_COMMITS_BEHIND )) && p+="${clean}⇠${VCS_STATUS_PUSH_COMMITS_BEHIND}"
  # (( VCS_STATUS_PUSH_COMMITS_AHEAD && !VCS_STATUS_PUSH_COMMITS_BEHIND )) && p+=" "

  # ⇢42 if ahead of the push remote; no leading space if also behind: ⇠42⇢42.
  (( VCS_STATUS_PUSH_COMMITS_AHEAD )) && p+="${clean}⇢${VCS_STATUS_PUSH_COMMITS_AHEAD}"

  # *42 if have stashes.
  (( VCS_STATUS_STASHES )) && p+="${clean}*${VCS_STATUS_STASHES}"

  # 'merge' if the repo is in an unusual state.
  [[ -n $VCS_STATUS_ACTION ]] && c=0 p+="${conflicted}${VCS_STATUS_ACTION}"

  # ~42 if have merge conflicts.
  (( VCS_STATUS_NUM_CONFLICTED )) && c=0 p+="${conflicted}~${VCS_STATUS_NUM_CONFLICTED}"

  # +42 if have staged changes.
  (( VCS_STATUS_NUM_STAGED )) && c=0 p+="${staged}+${VCS_STATUS_NUM_STAGED}"

  # !42 if have unstaged changes.
  (( VCS_STATUS_NUM_UNSTAGED )) && c=0 p+="${modified}!${VCS_STATUS_NUM_UNSTAGED}"

  # ?42 if have untracked files. It's really a question mark, your font isn't broken.
  (( VCS_STATUS_NUM_UNTRACKED )) && c=0 p+="${untracked}?${VCS_STATUS_NUM_UNTRACKED}"

  # -42 if have deleted files.
  local n_deleted=$(( VCS_STATUS_NUM_UNSTAGED_DELETED + VCS_STATUS_NUM_STAGED_DELETED ))
  (( n_deleted )) && c=0 p+="${deleted}-${n_deleted}"

  GITSTATUS_PROMPT="%{$fg_bold[blue]%}"
  [[ $c -eq 0 ]] && GITSTATUS_PROMPT="%{$fg_bold[cyan]%}ϟ"

  # trim leading/trailing whitespace
  GITSTATUS_RPROMPT="${p//((#s)[[:space:]]##|[[:space:]]##(#e))}"

  # The length of GITSTATUS_PROMPT after removing %f and %F.
  GITSTATUS_RPROMPT_LEN="${(m)#${${GITSTATUS_RPROMPT//\%\%/x}//\%(f|<->F)}}"
}

command -v gitstatus_start &>/dev/null && {
  # Start gitstatusd instance with name "MY". The same name is passed to
  # gitstatus_query in gitstatus_prompt_update. The flags with -1 as values
  # enable staged, unstaged, conflicted and untracked counters.
  gitstatus_stop 'MY' && gitstatus_start -s -1 -u -1 -c -1 -d -1 'MY'

  # On every prompt, fetch git status and set GITSTATUS_PROMPT.
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd gitstatus_prompt_update
}

PROMPT=' $(_suto_prompt "%{$fg_no_bold[red]%}" "%{$fg_no_bold[magenta]%}")%(?.♥.💔) %{$fg_no_bold[cyan]%}%3~ ${GITSTATUS_PROMPT:+$GITSTATUS_PROMPT }'
RPROMPT='%(?..%{$fg_no_bold[yellow]%}↪ $? )${GITSTATUS_RPROMPT:+$GITSTATUS_RPROMPT }%{$fg_bold[grey]%}%*%{$reset_color%}'

