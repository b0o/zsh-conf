#!/bin/env zsh
[[ -v _smart_sudo_prev_histcmd ]]   || _smart_sudo_prev_histcmd=-1
[[ -v _smart_sudo_prev_prefix ]]    || _smart_sudo_prev_prefix=""
[[ -v _smart_sudo_prefixes ]]       || _smart_sudo_prefixes=("(s)" "(sudo)" "(se)")
[[ -v _smart_sudo_default_prefix ]] || _smart_sudo_default_prefix="s"
[[ -v _smart_sudo_regex ]]          || _smart_sudo_regex="(#s)[[:space:]]#(${(pj:|:)_smart_sudo_prefixes})([[:space:]]##|(#e))"

function _smart_sudo() {
  local replaced="${LBUFFER/${~_smart_sudo_regex}}"
  local diff="${LBUFFER:0:$((${#LBUFFER} - ${#replaced}))}"
  if [[ -n "$diff" ]]; then
    LBUFFER="$replaced"
    _smart_sudo_prev_prefix="$diff"
    _smart_sudo_prev_histcmd=$HISTCMD
  else
    if [[ -n "$_smart_sudo_prev_prefix" && $_smart_sudo_prev_histcmd -eq $HISTCMD ]]; then
      LBUFFER="${_smart_sudo_prev_prefix}$LBUFFER"
    else
      LBUFFER="${_smart_sudo_default_prefix} $LBUFFER"
    fi
    _smart_sudo_prev_prefix=""
  fi
  zle reset-prompt
}

zle -N smart-sudo _smart_sudo

bindkey "^[s" smart-sudo
