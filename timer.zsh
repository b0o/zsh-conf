#!/usr/bin/env zsh

# A handy-dandy timer plugin for zsh
#
# Copyright (C) 2020 Maddison Hellstrom <https://github.com/b0o>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

declare -gA _TIMERS=()
declare -gA _TIMERS_TITLE=()

declare -i _timer_purged=0

function _timers_init() {
  local cache_dir
  if ! [[ -v _TIMERS_CACHE_FILE ]]; then
    declare -xg _TIMERS_CACHE_FILE="${ZSH_CACHE_DIR:-$HOME/.cache}/timers"
    cache_dir="$(dirname $_TIMERS_CACHE_FILE)"
    if [[ ! -d "$cache_dir" ]]; then
      mkdir -p "$cache_dir" || {
        echo "$0: error making cache dir $cache_dir" >&2
        return 1
      }
    fi
  fi

  if ! [[ -v _TIMER_UPDATE_INTERVAL ]]; then
    declare -xgi _TIMER_UPDATE_INTERVAL=1
  fi

  if ! [[ -v _TIMER_NOTIFY_START_CMD ]]; then
    if [[ -v DISPLAY ]]; then
      declare -xg _TIMER_NOTIFY_START_CMD='notify-send "%s" "%s"'
    else
      declare -xg _TIMER_NOTIFY_START_CMD='echo "%s - %s"'
    fi
  fi

  if ! [[ -v _TIMER_NOTIFY_END_CMD ]]; then
    if [[ -v DISPLAY ]]; then
      declare -xg _TIMER_NOTIFY_END_CMD='notify-send "%s" "%s"'
    else
      declare -xg _TIMER_NOTIFY_END_CMD='printf "\n%s - %s"'
    fi
  fi
}

function _timers_update() {
  if [[ ${1:-} != "-f" ]] && (( EPOCHSECONDS - _timer_purged < $_TIMER_UPDATE_INTERVAL )) return 3

  local -A _TIMERS_GLOBAL=()
  local -A _TIMERS_GLOBAL_TITLE=()

  if [[ -f  "$_TIMERS_CACHE_FILE" ]]; then
    # Get rid of .zwc versions of cache files
    # TODO: prevent compiled files from being created in the first place (zpmod?)
    if [[ -f  "$_TIMERS_CACHE_FILE.zwc" ]]; then
      rm -f "$_TIMERS_CACHE_FILE.zwc"
    fi
    source "$_TIMERS_CACHE_FILE" || {
      echo "$0: failed to source $_TIMERS_CACHE_FILE" >&2
      return 1
    }
  fi

  local -i pid
  for pid in ${(k)_TIMERS_GLOBAL[@]}; do
    if ps -q $pid &>/dev/null; then
      local t_end=${_TIMERS_GLOBAL[${pid}]}
      _TIMERS[${pid}]=$t_end
      if [[ -v "_TIMERS_GLOBAL_TITLE[${pid}]" ]]; then
        _TIMERS_TITLE[${pid}]="${_TIMERS_GLOBAL_TITLE[${pid}]}"
      fi
    fi
  done

  for pid in ${(k)_TIMERS[@]}; do
    if ! ps -q $pid &>/dev/null; then
      if [[ -v "_TIMERS[${pid}]" ]]; then
        unset "_TIMERS[${pid}]"
      fi
      if [[ -v "_TIMERS[${pid}]" ]]; then
        unset "_TIMERS_TITLE[${pid}]"
      fi
    else
      _TIMERS_GLOBAL[${pid}]=${_TIMERS[${pid}]}
      if [[ -v "_TIMERS_TITLE[${pid}]" ]]; then
        _TIMERS_GLOBAL_TITLE[${pid}]="${_TIMERS_TITLE[${pid}]}"
      fi
    fi
  done

  typeset -p _TIMERS_GLOBAL        > "$_TIMERS_CACHE_FILE"
  typeset -p _TIMERS_GLOBAL_TITLE >> "$_TIMERS_CACHE_FILE"

  _timer_purged=$EPOCHSECONDS
}

function _timer_cancel() {
  _timers_update
  local -i strict=0
  while [[ $# -gt 1 ]]; do
    case $1 in
      -s)
        strict=1
        ;;
      *)
        printf "%s: illegal option −− %s\n" "_timer_cancel" "$1" >&2
        return 1
        ;;
    esac
    shift
  done
  local -i pid=${1:--1}
  local name="$pid"
  [[ -v "_TIMERS[${pid}]" ]] || {
    if (( strict )); then
      echo "timer not found: $pid" >&2
      return 1
    fi
    return 0
  }
  [[ -v "_TIMERS_TITLE[${pid}]" ]] && name+=" (${_TIMERS_TITLE[${pid}]})"
  kill $pid || {
    echo "failed to cancel timer $name" >&2
    return 1
  }
  echo "timer $name cancelled" >&2
}

function _timer_get_data() {
  _timers_update
  local -i pid=${1:--1}
  local -i elapsed end
  local title
  [[ -v "_TIMERS[${pid}]" ]] || return 1
  [[ -v "_TIMERS_TITLE[${pid}]" ]] && title="${_TIMERS_TITLE[${pid}]}"
  end=${_TIMERS[${pid}]}
  elapsed=$(ps --no-headers --format=etimes $pid 2>/dev/null | tr -d ' ') || return 1
  echo "t_title='$title'"
  echo "t_end=$end"
  echo "t_elapsed=$elapsed"
  echo "t_start=$((EPOCHSECONDS - elapsed))"
  echo "t_remaining=$((end - EPOCHSECONDS))"
}

function _timer_most_recent() {
  _timers_update
  local -i t
  local -i min_t=0
  local -i pid
  local -i min_pid=-1

  local -i t_start t_end t_elapsed t_remaining
  for pid in ${(k)_TIMERS[@]}; do
    [[ -v "_TIMERS[${pid}]" ]] || continue
    eval "$(_timer_get_data $pid)" || continue
    if [[ $t_start -lt $min_t || $min_t -eq 0 ]]; then
      min_t=$t_start
      min_pid=$pid
    fi
  done
  if [[ $min_pid -eq -1 ]]; then
    return 1
  fi
  echo $min_pid
}

function _timer_print() {
  local -i pid=$1
  [[ -v "_TIMERS[${pid}]" ]] || return 1
  local -i t_start t_end t_elapsed t_remaining
  local t_title=""
  eval "$(_timer_get_data $pid)" || return 1
  echo "$pid" >&2
  if [[ -n "$t_title" ]]; then
    echo "\tTitle:     $t_title" >&2
  fi
  echo "\tStart:     $(date --date="@$t_start" +%X)" >&2
  echo "\tEnd:       $(date --date="@$t_end" +%X)" >&2
  echo "\tElapsed:   $t_elapsed" >&2
  echo "\tRemaining: $t_remaining" >&2
}

function timer() {
  _timers_update
  local timer_title
  local notify_start="$_TIMER_NOTIFY_START_CMD"
  local notify_end="$_TIMER_NOTIFY_END_CMD"
  local -a extras=()
  local opt OPTARG OPTIND
  while getopts ":hl:c:Cs:e:t:" opt; do
    if [[ "$opt" == ":" ]]; then
      opt="$OPTARG"
      OPTARG=
    # TODO: handle options with optional values
    # elif [[ "$OPTARG" =~ ^- ]]; then
    #   extras+=("$OPTARG")
    fi
    case "$opt" in
    h)
      echo "Usage: $0 [OPTION]... duration|time

Schedule a timer

Options:
  General
    -h           show usage information
    -l [id]      list active timer(s)

  Timer Control
    -c [id]      cancel timer (default: most recent timer)
    -C           cancel all timers

  Timer Creation
    -s           notification command to execute on timer start
    -e           notification command to execute on timer end
    -t           specify a title for the timer

License:
  Copyright 2020-$(date +%Y) Maddison Hellstrom (https://github.com/b0o)
  GPL-3.0 License (https://www.gnu.org/licenses/gpl-3.0.txt)" >&2
      return 0
      ;;
    l)
      if [[ -n "$OPTARG" ]]; then
        _timer_print $OPTARG || {
          echo "timer not found: $OPTARG" >&2
          return 1
        }
        return 0
      fi
      if [[ ${#_TIMERS[@]} -eq 0 ]]; then
        echo "no timers" >&2
        return 0
      fi
      local -i pid
      for pid in ${(k)_TIMERS[@]}; do
        _timer_print $pid || continue
      done
      return 0
      ;;
    c)
      local -i pid
      if [[ -n "$OPTARG" ]]; then
        pid=$OPTARG
      else
        pid=$(_timer_most_recent) || {
          echo "no timers found" >&2
          return 1
        }
      fi
      if [[ $pid -ne 0 ]] ; then
        if [[ ! -v "_TIMERS[${pid}]" ]]; then
          echo "timer not found: $pid" >&2
          return 1
        fi
        _timer_cancel -s $pid || {
          return 1
        }
        return 0
      else
        echo "no timers found" >&2
        return 1
      fi
      ;;
    C)
      local ret=1
      for pid in ${(k)_TIMERS[@]}; do
        _timer_cancel $pid || continue
        ret=0
      done
      [[ $ret -eq 0 ]] || echo "no timers found" >&2
      return $ret
      ;;
    s)
      notify_start="$OPTARG"
      ;;
    e)
      notify_end="$OPTARG"
      ;;
    t)
      timer_title="$OPTARG"
      ;;
    *)
      printf "%s: illegal option −− %s\n" "$0" "$OPTARG" >&2
      return 1
      ;;
    esac
  done
  shift $((OPTIND - 1))
  if [[ $# -lt 1 ]]; then
    echo "error: expected time or duration" >&2
    return 1
  fi
  local tstr="$*"
  local time=0
  local -i end_time=0
  if [[ $tstr =~ : ]]; then
    time=$(( $(date -d "$tstr:00" +%s) - $(date +%s) + 1 )) 2>/dev/null || {
      echo "error: invalid time or duration: $tstr" >&2
      return 1
    }
    if [[ $time -lt 0 ]]; then
      time=$((time + 24*60*60))
    fi
  else
    time=$((tstr * 60))
  fi
  end_time=$(( $(date +%s) + time ))
  if [[ $time -le 0 || $time -gt $((24 * 60 * 60)) ]]; then
    echo "error: invalid time or duration: $tstr" >&2
    return 1
  fi
  () {
    eval "$(printf "$notify_start" "Timer Started${timer_title:+": $timer_title"}" "Ending in $((time/60)) minutes at $(date --date="@$end_time" +%X)")"
    sleep $time
    eval "$(printf "$notify_end" "Timer Finished${timer_title:+": $timer_title"}" "$((time/60)) minute(s) have elapsed")"
  } &
  local -i pid=$!
  _TIMERS[${pid}]=$end_time
  if [[ -n "$timer_title" ]]; then
    _TIMERS_TITLE[${pid}]="$timer_title"
  fi
  _timer_print $pid
  _timers_update -f
}

function _timer() {
  _timers_update
  local -a timers=()
  local -i pid
  for pid in ${(k)_TIMERS[@]}; do
    local -i t_start t_end t_elapsed t_remaining
    local t_title=""
    eval "$(_timer_get_data $pid)" || continue
    timers+=("${pid}:$(date --date="@$t_end" +%X) (${t_remaining}s remaining)${t_title:+$(print '\t')${t_title}}")
  done
  _arguments -s : \
    '-h[show usage information]' \
    "-l[list active timers]:timerpid:{_describe 'Timer PID' timers}" \
    "-c[cancel timer]:timerpid:{_describe 'Timer PID' timers}" \
    '-C[cancel all timers]' \
    '-s[notification command to execute on timer start]: :{_command_names}' \
    '-e[notification command to execute on timer end]: :{_command_names}' \
    '-t[specify a title for the timer]:' \
}

_timers_init
compinit && compdef _timer timer
