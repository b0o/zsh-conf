#!/usr/bin/env zsh

### ZSH options
setopt hist_ignore_space
setopt share_history
setopt extended_history
setopt extended_glob
setopt multios
setopt pushd_ignore_dups
setopt auto_pushd
setopt pushdminus

# Enable globs in autocompletion searches, e.g.
# typing `grep --i*m<TAB>` will autocomplete `grep --invert-match`
setopt globcomplete

zstyle ':completion:*:descriptions' format

### zinit
_zinit_script="${ZINIT[BIN_DIR]}/zinit.zsh"
[[ ! -f "$_zinit_script" ]] && {
  if (( $+commands[git] )); then
    (
      cd "$ZDOTDIR"
      git submodule update --init --recursive
    )
  else
    echo 'fatal: unable to install zinit: git not found' >&2
    read -rk1
    exit 1
  fi
}

[[ ! -f "$_zinit_script" ]] && {
  echo 'fatal: zinit not found' >&2
  exit 1
}

source "$_zinit_script"

_zinit_modules="${ZINIT[BIN_DIR]}/zmodules/Src"
[[ -e "$_zinit_modules" ]] && {
  module_path+=("$_zinit_modules")
  [[ -e "$_zinit_modules/zdharma/zplugin.so" ]] || {
    zinit module build
  }
  zmodload zdharma/zplugin
}

# zinit light "b0o/last-working-dir-wm"

[[ ${ZSH_LIGHT_MODE:-0} -eq 1 ]] && return

# Functions to make configuration less verbose
# (inspired by https://github.com/NICHOLAS85/dotfiles/tree/master/.zshrc)
function _z_turbo() {
  [[ ${ZSH_NO_TURBO:-0} -eq 1 ]] && {
    [[ $# -gt 1 ]] && {
      zinit ice lucid "${@:2}"
    }
    return
  }
  zinit ice wait"$1" lucid "${@:2}"
}
function _z_mturbo() {
  zinit ice wait"$1" lucid "${@:2}"
}
function _z_ice() {
  zinit ice lucid "$@"
}
function _z_snip() {
  zinit snippet "$@"
}
function _z() {
  zinit light "$@"
}

_z_ice atload'unset -f upgrade_oh_my_zsh'
_z_snip "OMZ::lib/functions.zsh"

_z_snip "OMZ::lib/compfix.zsh"
_z_snip "OMZ::lib/completion.zsh"
_z_snip "OMZ::lib/theme-and-appearance.zsh"
_z_snip "OMZ::lib/key-bindings.zsh"
_z_snip "OMZ::lib/history.zsh"
_z_snip "OMZ::lib/termsupport.zsh"
_z_snip "OMZ::lib/misc.zsh"

### git
_z_ice has'git' atload'_atload_omz_git_plugin'
function _atload_omz_git_plugin() {
  unalias gcl
}
_z_snip "OMZ::plugins/git/git.plugin.zsh"

function _atclone_git_scripts() {
  local -a enabled_scripts=(
    git-addremove
    git-amend-all
    git-branch-status
    git-current
    git-current-branch
    git-fetch-github
    git-filemerge
    git-forest
    git-interactive-merge
    git-trial-merge
    git-undo
    git-whoami
    git-wtf
  )
  [[ -d bin ]] && rm -rf bin
  mkdir bin
  local s
  for s in ${enabled_scripts[@]}; do
    ln -s "../$s" "bin/$s"
  done
}
function _atload_git_scripts() {
  alias gw=git-wtf
}
_z_turbo 0b has'git' as'program' pick'bin/*' atclone'_atclone_git_scripts' atpull'%atclone' atload'_atload_git_scripts'
_z "jwiegley/git-scripts"

# gitstatus
_gitstatus_plugin="/usr/share/gitstatus/gitstatus.plugin.zsh"
[[ -e "$_gitstatus_plugin" ]] && {
  source "$_gitstatus_plugin"
}

_z_snip "OMZ::plugins/command-not-found/command-not-found.plugin.zsh"

# history
function _atload_hist_substr_search() {
  bindkey "${terminfo[kcuu1]}" history-substring-search-up   # up arrow key
  bindkey "${terminfo[kcud1]}" history-substring-search-down # down arrow key
  bindkey -M emacs '^P' history-substring-search-up
  bindkey -M emacs '^N' history-substring-search-down
}
_z_turbo 0b atload'_atload_hist_substr_search'
_z "zsh-users/zsh-history-substring-search"
_z_turbo 0b
_z "zdharma/history-search-multi-word"

# completion
# function _atload_zsh_autosuggestions() {
  bindkey '^[E' autosuggest-execute
# }
# _z_turbo 0b atload'_atload_zsh_autosuggestions'
_z "zsh-users/zsh-autosuggestions"

_z "zsh-users/zsh-completions"

function _atload_fzf_tab() {
  zstyle ':fzf-tab:*' continuous-trigger ','
  enable-fzf-tab
}
# _z_turbo 0b atload'_atload_fzf_tab'
_z "Aloxaf/fzf-tab"

# syntax highlighting
_z "zdharma/fast-syntax-highlighting"

# hooks
_z "willghatch/zsh-hooks"

# bash-my-aws - https://github.com/bash-my-aws/bash-my-aws
_z_turbo 0b has'aws' pick'bin/bma' as'program' \
  atclone'ln -s ${ZINIT[PLUGINS_DIR]}/bash-my-aws---bash-my-aws $HOME/.bash-my-aws' \
  atload'alias a=bma'
_z "bash-my-aws/bash-my-aws"

# ui
_z "b0o/suto-prompt"
_z_snip "$ZDOTDIR/theme.zsh"

# "smart" keybindings
_z_turbo 0b
_z_snip "$ZDOTDIR/smart-sudo.zsh"

# "smart" keybindings
_z_turbo 0b
_z "$GIT_PROJECTS_DIR/zfzf"

# fun
function _atinit_emoji_cli() {
  function emoji_xc() {
    xc "$(emoji::emoji_get)"
  }
  zle -N emoji-xc emoji_xc
  export EMOJI_CLI_KEYBIND='^[;'
  export EMOJI_CLI_USE_EMOJI=1
  bindkey '^[:' emoji-xc
}
_z_mturbo 0b atinit'_atinit_emoji_cli'
_z "b4b4r07/emoji-cli"

# utility
function _atload_timer() {
  # TODO: add support for dunst, MacOS
  if [[ -v SWAYSOCK ]]; then
    export _TIMER_NOTIFY_START_CMD='swaynagmode -e bottom -t info -m "%s - %s"'
    export _TIMER_NOTIFY_END_CMD='play-sound -l Submarine &>/dev/null &; pid=$!; swaynagmode -e bottom -t warning -m "%s - %s"; kill $pid'
  fi
  function brew() {
    local -a opts=(5)
    while [[ $# -gt 1 ]]; do
      opts=("$@")
    done
    timer -t "brew" "${opts[@]}"
  }
  alias t="timer"
  alias tl="timer -l"
  alias tc="timer -c"
  alias tcc="timer -C"
  alias tC="timer -C"
}
_z_mturbo 0b atload'_atload_timer'
_z_snip "$ZDOTDIR/timer.zsh"

# comark
function _atload_comark() {
  bindkey '^[,'       comark-fzf-smart
  bindkey '^[<'       comark-fzf-cd
  bindkey '^[[21;5~'  comark-fzf-insert
}
_z_turbo 0b atload'_atload_comark'
_z "b0o/comark"

function _atload_comp() {
  #  completion aliases
  compdef pip3=pip pip3.8=pip
  compdef pip2.7=pip2
  compdef viman=man

  # pipx
  complete -o nospace -o default -o bashdefault -F _python_argcomplete pipx

  # hashicorp vault
  complete -o nospace -C /usr/bin/vault vault
}

function _atload_autoload() {
  local f
  for f in "$ZSH_USER_FUNCTIONS_DIR"/*; do
    autoload -k "$f"
  done
}

_z_mturbo 0b atload'_atload_comp' atload'_atload_autoload'
_z_snip "/dev/null"

#### Bindings
## builtin/defaults

## movement
bindkey "^a" beginning-of-line
bindkey "^e" end-of-line

bindkey "^b" backward-char
bindkey "^f" forward-char

bindkey "^[b" backward-word
bindkey "^[f" forward-word
bindkey "^[B" backward-word
bindkey "^[F" forward-word

bindkey "^[[A" up-line-or-history   # <up>
bindkey "^[[B" down-line-or-history # <down>

bindkey "^[[D" backward-char        # <left>
bindkey "^[[C" forward-char         # <right>

bindkey "^[[1;3D" backward-word     # <M-right>
bindkey "^[[1;3C" forward-word      # <M-left>
bindkey "^[[1;5D" backward-word     # <C-right>
bindkey "^[[1;5C" forward-word      # <C-left>

## line editing
bindkey "^d" delete-char-or-list
bindkey "^h" backward-delete-char # pre-bound in xst to C-S-D

bindkey "^[d" kill-word
bindkey "^[D" backward-kill-word

bindkey "^t" transpose-chars
bindkey "^[t" transpose-words

bindkey '^xe' edit-command-line # TODO change keys

bindkey "^k"  kill-line
bindkey "^u"  backward-kill-line
bindkey "^[k" kill-whole-line
bindkey "^g"  send-break

## shell/history
bindkey "^q"  push-line
bindkey "^[q" get-line

bindkey "^[a" accept-and-hold

bindkey "^l" clear-screen
bindkey -s "^[^l" "^q:^J^l" # clear screen and exit status

bindkey "^n" down-line-or-history
bindkey "^p" up-line-or-history

bindkey "^r" history-search-multi-word
bindkey "^s" history-search-multi-word-backwards

bindkey "^xa"  _expand_alias
bindkey "^x^a" _expand_alias

function _expand_any() {
  zle _expand_alias
  zle expand-word
}
zle -N expand-any _expand_any

bindkey "^xx"  expand-any
bindkey "^x^x" expand-any

zle -N smart-l _smart_l
bindkey "^[l" smart-l

function _smart_wrap_parens()      { _smart_wrap '(' ')'    }
function _smart_wrap_brackets()    { _smart_wrap '[' ']'    }
function _smart_wrap_cbrackets()   { _smart_wrap '{' '}'    }
function _smart_wrap_squotes()     { _smart_wrap "'" "'"    }
function _smart_wrap_dquotes()     { _smart_wrap '"' '"'    }
function _smart_wrap_backticks()   { _smart_wrap '`' '`'    }
function _smart_wrap_cmd_subst()   { _smart_wrap '$(' ')'   }
function _smart_wrap_param_subst() { _smart_wrap '${' '}'   }
function _smart_wrap_arith_subst() { _smart_wrap '$((' '))' }

zle -N smart-wrap-parens         _smart_wrap_parens
zle -N smart-wrap-brackets       _smart_wrap_brackets
zle -N smart-wrap-cbrackets      _smart_wrap_cbrackets
zle -N smart-wrap-squotes        _smart_wrap_squotes
zle -N smart-wrap-dquotes        _smart_wrap_dquotes
zle -N smart-wrap-backticks      _smart_wrap_backticks
zle -N smart-wrap-cmd-subst      _smart_wrap_cmd_subst
zle -N smart-wrap-param-subst    _smart_wrap_param_subst
zle -N smart-wrap-arith-subst    _smart_wrap_arith_subst

bindkey '^[(' smart-wrap-parens
bindkey '^[[' smart-wrap-brackets
bindkey '^[{' smart-wrap-cbrackets
bindkey "^['" smart-wrap-squotes
bindkey '^["' smart-wrap-dquotes
bindkey '^[`' smart-wrap-backticks
bindkey '^[$' smart-wrap-cmd-subst
bindkey '^[)' smart-wrap-cmd-subst
bindkey '^[}' smart-wrap-param-subst
bindkey '^[=' smart-wrap-arith-subst
bindkey '^[+' smart-wrap-arith-subst

function _fancy_c-z_b () { _fancy_c-z -b }
zle -N fancy-c-z   _fancy_c-z
zle -N fancy-c-z_b _fancy_c-z-b
bindkey '^z'  fancy-c-z
bindkey '^[z' fancy-c-z_b

#### Functions

alias h=help

alias gigg="gig -w"
alias ggig="gig -w"

alias ssh="TERM=xterm ssh"

#### ALIASES
# <3
alias ❤="echo '❤ ❤ ❤ I love you, $USER! ❤ ❤ ❤'"

# shell/builtin/basic
alias c="clear"
alias q="exit"
alias rm="rm --verbose --interactive=once"
alias rmi="rm --verbose --interactive=always"
alias rf="rmi -rf"
alias ccp="rsync --archive --human-readable --progress --verbose --whole-file"
alias cd="cd -P"
alias cdp='cd $(xco)'
alias lb="lsblk -o name,label,size,type,mountpoint,fstype,fsuse%,fssize,fsavail,fsused"
alias cat="$HOME/.cargo/bin/bat" # bat is compatible with unix cat when used in a pipeline
alias cx="chmod +x"
alias tf="tail -f"
alias mo="stat -c '%a %A %n'"
alias lg="ls -1d" # ls filename glob tester
alias peep="peep-tput"
alias pp="peep"
alias l="lll"
alias wwat="wat -v"
alias w="wat"
alias ww="wwat"

# processes
alias k="env kill --verbose"
alias pk="pkill --count --echo"
alias pkk="pk -KILL"
alias psa="ps aux"
alias pga="pgrep -a"
alias pgenv="penv -g"

# clipboard
alias xc="_xc -i"
alias xco="_xc -o"
alias x="xc"
alias xo="xco"
alias xl="xcl" # copy last n command(s) to clipboard

 # output from clipboard
# colorize grep and diff (https://wiki.archlinux.org/index.php/Color_output_in_console)
alias grep='grep --color=auto'
alias diff='diff --color=auto'

# utility
alias xeva="xev | awk -F'[ )]+' '/Press/ { a[NR+2] } NR in a { printf \"%-14s [%-5s %s]\\n\", \$8, \$3, \$5 }'"
alias bat="$GOPATH/bin/bat" # CLI HTTP cURL-like utility
alias py="ptipython"
alias smd="grip --browser" # it stands for 'serve markdown', you pervert.
alias md="glow"
alias mdp="glow -p"
alias imgur="imgur.sh"
alias u="unbuffer"
alias def="sdcv"
alias bed="TERM=xterm-256color bed"
alias msf="msfconsole -q"
alias pip-search="python -m pypisearch"

# network
alias dip4="dig +short myip.opendns.com A @208.67.222.222"
alias dip6="dig +short myip.opendns.com AAAA @2620:0:ccc::2"
alias dip="dig +short myip.opendns.com A @208.67.222.222 myip.opendns.com AAAA @2620:0:ccc::2"
alias hip4="curl ipv4.icanhazip.com"
alias hip6="curl ipv6.icanhazip.com"
alias hip="curl --parallel ipv{4,6}.icanhazip.com"
alias ipp="dip"
alias srv="serve"

# text
alias spreedx='spreed "$(xco)"'
alias xspreed="spreedx"

# qr code generation
alias gxcqr="command xcqr"
alias gxqr="gxcqr"
alias gxq="gxcqr"
alias xcqr='xco | qr'
alias xqr="xcqr"
alias xq="xcqr"

# documentation & help
alias man="viman"
alias m="man"
alias m0="man 0"
alias m1="man 1"
alias m2="man 2"
alias m3="man 3"
alias m4="man 4"
alias m5="man 5"
alias m6="man 6"
alias m7="man 7"
alias m8="man 8"

alias navi="navi --print --no-autoselect"

# man + ag
# XXX: currently, ag has a bug causing the -z flag to malfunction:
# github://ggreer/the_silver_searcher/issues/1280
# function mag() {
#   ag -z "$@" $(sed -e 's/:/ /g' <<<"$MANPATH") 2>/dev/null
# }

alias mag="mg"

alias maf="man --names-only --where --where-cat --regex"

alias rand.bin="rand -b2"
alias rand.oct="rand -b8"
alias rand.hex="rand -b16"
alias rand.b36="rand -b36"

# system
alias sudo="sudo " # The trailing space is necessary to ensure aliases are expanded before running sudo
alias s="sudo "
alias se="sudo -E "

alias sc="systemctl"
alias scs="sc status"
alias scu="sc --user"
alias scudr="scu daemon-reload"
alias scus="scs --user"
alias ssc="s sc"
alias sscdr="s sc daemon-reload"

alias j="journalctl"
alias jf="j --follow --unit"
alias ju="j --user"
alias juf="j --user --follow --unit"

alias sn="s nettog"
alias sne="sn -e"
alias sneu="sn -e up"
alias sned="sn -e down"
alias snw="sn -w"

alias synw="syn -w"

# alias xkbr="$HOME/.config/xkb/conf.sh"
# alias xkr="xkbr"

alias open="mimeo"
# alias o="open"
alias gtl="gtk-launch"

# editor
alias v="/bin/env nvim -p"
alias nvim=v
alias vim=v
alias vi=v
alias nv=v
alias vd="nvim -dO"
alias snvim="sudoedit"
alias svim=snvim
alias snv=snvim
alias sv=snvim
alias sev="se v"
# alias svv="SUDO_EDITOR=\"nvim -c ':call NERDTreeTabsEnable()'\" sudoedit"
# alias vv="nvim -c ':call NERDTreeTabsEnable()'"

# neuron
alias n="neuron -d $ZETTELKASTEN_DIR"

# alias zr="echo 'Reloading .zshrc...'; . $ZDOTDIR/.zshenv; . $ZDOTDIR/.zshrc"
alias zr="echo 'Reloading .zshrc...'; exec zsh"
# alias ze="vim $ZDOTDIR/.zshrc; zr"
alias ze="vim $ZDOTDIR/.zshrc"
alias zrc="ze"
alias zshrc="ze"

alias info="vinfo"

# package management
alias p="pacman"
alias pac="p"

alias sp="s p"
alias sps="sp -S"
alias spr="sp -Rsc"

alias pss="p -Ss"
alias psi="p -Si"

alias pq="p -Q"
alias pqi="pq -i"
alias pqs="pq -s"
alias pql="pq -l"
alias pqo="pq -o"
alias pqox="pqoc"

alias upd="updoot"
alias yay='() { yay "$@" && rehash }'
alias y="yay"
alias pacorphans="pacman -Qdt"

# git
eval "$(hub alias -s)" # Hub for Git
alias gpa="g pa"
alias gpao="g pao"
alias gpat="g pat"
alias gpab="g pab"
alias gai="g add --interactive"
alias gc="g commit --verbose"
alias gca="g  commit --all --verbose"
alias gl="g ls"
alias gla="g la"
alias gls="g ls"
alias gll="g ll"
alias glla="g lla"
alias gr="g remote --verbose"

# diff
alias delta="delta --minus-color='#F0957A' --minus-emph-color='#F76234' --plus-color='#93C98B' --plus-emph-color='#53C285' --theme=1337"
alias ddelta='() { diff -u "$@" | delta }'
alias ddiff="ddelta"

# dootfiles
alias doot="git --git-dir=$HOME/.doots/ --work-tree=$HOME"
alias d="doot"

# productivity
alias mutt="$HOME/bin/mutt"

# golang
# alias gp="gopath"
# alias gps="gopath -s"
# alias gpp="gopath -p"
# alias gpb="gopath -b"
# alias gg="go get"
# alias gs="$GOPATH/bin/go-search"
alias panicparse="$GOPATH/bin/pp"

# node/js
alias gu="gulp"

alias dm="darkmode"

# ocaml
alias ut="dune utop"
alias utl="while ut; do echo -e ''; done"

# multimedia
alias gprint="yad --print --filename "

### Command Not Found Handlers
# do special stuff if a command isn't found

# handlers are functions which accept as input the command which was not found
# and return an integer, 0 if this handler has successfully and fully handled
# the command or 1 if this handler did not. If 0 is returned, no further
# handlers will be attempted to be called.
handlers=()

# Detect attempts to access a , bookmark
# handles ,<bookmark>
function _cnf_handler_bookmarks() {
  if ! [[ ${#} -eq 1 && ${#1} -gt 1 && ${1[1]} == "," ]]; then
    return 1
  fi
  local b="${1:1}"
  echo "bookmark '$b' not found." >&2
  local l
  l="$(l, "${1:1}" 2>/dev/null)"
  [[ $? -ne 0 ]] && {
    return 0
  }
  echo "Did you mean one of these?" >&2
  echo "$l" >&2
  return 0
}
handlers+=("_cnf_handler_bookmarks")

# Detect attempts to cd to a path within the current working directory
# handle .<path>
function _cnf_handler_dot_cd() {
  if ! [[ ${#} -eq 1 && ${#1} -gt 1 && ${1[1]} == "." ]]; then
    return 1
  fi
  echo "${1:1}" > "$ZSH_CACHE_DIR/cnf_handler_dot_cd_dir"
  return 0
}
handlers+=("_cnf_handler_dot_cd")
function _cnf_handler_dot_cd_hook() {
  if [[ -f "$ZSH_CACHE_DIR/cnf_handler_dot_cd_dir" ]]; then
    cd $(<"$ZSH_CACHE_DIR/cnf_handler_dot_cd_dir")
    zle reset-prompt
    command rm "$ZSH_CACHE_DIR/cnf_handler_dot_cd_dir"
  fi
}
hooks-add-hook zle_line_init_hook _cnf_handler_dot_cd_hook

# make a copy of an existing command_not_found_handler function to
# _command_not_found_handler
if [[ ! -v _cnfh_orig && -z $_cnfh_orig ]]; then
  local _cnfh_orig
  _cnfh_orig="$(declare -f command_not_found_handler)"
  if [[ $? -eq 0 ]]; then
    eval "_$_cnfh_orig"
  fi
fi

function command_not_found_handler() {
  for h in ${handlers[@]}; do
    eval "$h $@"
    if [[ $? -eq 0 ]]; then
      return 0
    fi
  done
  local _cnft
  _cnft="$(type -w _command_not_found_handler)"
  if [[ $_cnft == "_command_not_found_handler: function" ]]; then
    _command_not_found_handler $@
    return $?
  fi
  echo "command not found: $*" >&2
  return 1
}

#### Initializations

## OCaml opam
_ocaml_opam_compl="$HOME/.opam/opam-init/init.zsh"
[[ -f "$_ocaml_opam_compl" ]] && {
  _z_snip "$_ocaml_opam_compl"
}

# ## Google Cloud SDK (gcloud)
# _gcloud_sdk="$HOME/.cache/tmp/google-cloud-sdk"
# _gcloud_sdk_zsh_path="$_gcloud_sdk/path.zsh.inc"
# _gcloud_sdk_zsh_compl="$_gcloud_sdk/completion.zsh.inc"
# [[ -f "$_gcloud_sdk_zsh_path" ]] && {
#   source "$_gcloud_sdk_zsh_path"
# }
# [[ -f "$_gcloud_sdk_zsh_compl" ]] && {
#   _z_snip "$_gcloud_sdk_zsh_compl"
# }

## asdf (version manager for node, go, etc)
_asdf_sh="$ASDF_DATA_DIR/asdf.sh"
_asdf_compl="$ASDF_DATA_DIR/completions/asdf.bash"
[[ -f "$_asdf_sh" ]] && {
  source "$_asdf_sh"
}
[[ -f "$_asdf_compl" ]] && {
  _z_snip "$_asdf_compl"
}

# rvm (Ruby enVironment Manager)
# _rvm_rvm="$RVM_DIR/scripts/rvm"
# _rvm_compl="$RVM_DIR/scripts/completion"
# [[ -f "$_rvm_rvm" ]] && {
#   _z_snip "$_rvm_rvm"
# }
# [[ -f "$_rvm_compl" ]] && {
#   _z_snip "$_rvm_compl"
# }

# broot - https://github.com/Canop/broot
_broot="$XDG_CONFIG_HOME/broot/launcher/bash/br"
[[ -f "$_broot" ]] && {
  _z_snip "$_broot"
}

# bash-my-aws - https://github.com/bash-my-aws/bash-my-aws
_bma_compl="$HOME/.bash-my-aws/bash_completion.sh"
[[ -f "$_bma_compl" ]] && {
  _z_snip "$_bma_compl"
}

# fzf: use fd instead of find
_fzf_compgen_path() {
  fd --hidden --follow --exclude ".git" . "$1"
}
_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude ".git" . "$1"
}

# nix
_nix="/etc/profile.d/nix.sh"
[[ -v NIX_PATH ]] || {
  [[ -f "$_nix" ]] && source "$_nix"
}

# home-manager (nix)
_home_mgr="$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
[[ -f "$_home_mgr" ]] && {
  source "$_home_mgr"
}

# gulp
_gulp="$XDG_CONFIG_HOME/yarn/global/node_modules/gulp-cli/completion/zsh"
[[ -f "$_gulp" ]] && {
  function _atload_gulp() {
    compdef _gulp_completion gulp
  }
  _z_turbo 0b atload'_atload_gulp'
  _z_snip "$_gulp"
}

# rakudobrew (Perl6 version manager)
# eval "$(rakudobrew init Zsh)"

# initialize command completions and zsh modules
[[ $ZSHRC_INIT -eq 0 ]] && {
  autoload -Uz _zinit
  autoload -Uz +X compinit && compinit
  autoload -Uz +X bashcompinit && bashcompinit
  ZSHRC_INIT=1
}

zinit cdreplay -q
