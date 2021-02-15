#!/usr/bin/env zsh

# Platform-specific configuration
function _zshenv_linux() {
  # Inherit environment variables from systemd
  if (($+commands[systemctl])); then
    local pwd="$PWD" # save PWD
    eval "$(systemctl show-environment)"
    eval "$(systemctl --user show-environment)"
    PWD="$pwd" # restore PWD
  fi
  # If running wayland, ensure programs use it
  if [[ -v WAYLAND_DISPLAY ]]; then
    export QT_QPA_PLATFORM=wayland
    export GDK_BACKEND=wayland
    export CLUTTER_BACKEND=wayland
    export SDL_VIDEODRIVER=wayland
    export MOZ_ENABLE_WAYLAND=1
  fi
}

function _zshenv_darwin() {}

case $(uname -s) in
Linux)
  _zshenv_linux
  ;;
Darwin)
  _zshenv_darwin
  ;;
esac

# Load user environment
# NOTE: these variables override environment variables inherited from systemd
if [[ -r "$HOME/.env" ]]; then
  emulate sh -c "$HOME/.env"
fi

### zsh options
export SAVEHIST=1000000
export HISTSIZE=1000000
export HISTFILE="${HISTFILE:-$ZDOTDIR/.zsh_history}"
export HIST_IGNORE_SPACE=1
export SHARE_HISTORY=1
export DISABLE_AUTO_UPDATE=1
export DISABLE_UPDATE_PROMPT=1
export ZSH_CACHE_DIR="$HOME/.cache/zsh"
export ZSH_BASH_COMPL_DIR="${${ZDOTDIR:+$ZDOTDIR/}:-$HOME/.zsh_}bash_completions"
export ZSH_USER_FUNCTIONS_DIR="${${ZDOTDIR:+$ZDOTDIR/}:-$HOME/.zsh_}functions"

[[ -d "$ZSH_BASH_COMPL_DIR" ]] && fpath+=("$ZSH_BASH_COMPL_DIR")
[[ -d "$ZSH_USER_FUNCTIONS_DIR" ]] && fpath+=("$ZSH_USER_FUNCTIONS_DIR")

### zsh plugins
## zinit
declare -A ZINIT
export ZINIT[HOME_DIR]="${ZDOTDIR}/zinit"
export ZINIT[PLUGINS_DIR]="${ZINIT[HOME_DIR]}/plugins"
export ZINIT[BIN_DIR]="${ZINIT[HOME_DIR]}/zinit"
export ZINIT[MUTE_WARNINGS]=1

# Display red dots while waiting for tab completion
export COMPLETION_WAITING_DOTS="true"

## zsh-autosuggestions
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#777"
export ZSH_AUTOSUGGEST_STRATEGY=("history" "completion")
export ZSH_AUTOSUGGEST_USE_ASYNC=1

## comark
export COMARK_DIR="$HOME/,"
export COMARK_ALIAS=1
export COMARK_GLOBAL_ALIAS=1
export COMARK_PREFIX=","
export COMARK_ALIAS_PREFIX=","
export COMARK_GLOBAL_ALIAS_PREFIX=",,"

## last-working-dir
# export LWD_AUTO_CD=1
# export LWD_DEFAULT_DIR="$HOME"
# export LWD_IGNORE_DIRS=(
#   "$HOME/.asdf"
# )

## git
export GIT_PROJECTS_DIR="$HOME/git"

## fzf
export FZF_DEFAULT_OPTS="$(printf '%s ' \
    "--bind=ctrl-p:toggle+up"           \
    "--bind=ctrl-n:toggle+down"         \
  )"
