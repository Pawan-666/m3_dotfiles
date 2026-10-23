# Powerlevel10k instant prompt - keep at top for fast startup
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Homebrew setup (macOS)
# ~/.zprofile already runs this for login shells; the guard skips a redundant
# 20ms fork there and still covers non-login shells, where it hasn't run.
if [[ -z $HOMEBREW_PREFIX && -f "/opt/homebrew/bin/brew" ]] then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Zinit plugin manager setup
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Auto-install Zinit if not present
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Load Zinit
source "${ZINIT_HOME}/zinit.zsh"

# Prompt theme
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Essential plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Oh My Zsh snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl

# Initialize completions
# compaudit (the fpath security scan) costs ~22ms and rarely changes its answer,
# so pay for it once a day; -C reuses the existing dump the rest of the time.
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi
zinit cdreplay -q

# Editor configuration
export EDITOR=nvim

# Powerlevel10k configuration
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Key bindings (emacs mode)
bindkey -e
bindkey '^p' history-search-backward   # Ctrl+P for previous command
bindkey '^n' history-search-forward    # Ctrl+N for next command
bindkey '^[w' kill-region              # Alt+W to kill region

# History configuration
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
setopt appendhistory          # Append to history file
setopt sharehistory          # Share history between sessions
setopt hist_ignore_space     # Ignore commands starting with space
setopt hist_ignore_all_dups  # Remove all duplicate entries
setopt hist_save_no_dups     # Don't save duplicates
setopt hist_find_no_dups     # Don't display duplicates in search

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

# Aliases
alias ls='ls --color'
alias vim='nvim'
alias vi='nvim'
# nvim's TUI (0.12+) runs as a parent with an `nvim --embed` server child, and
# lazy-tmux saves the child's command line. Replayed into a shell it waits on
# stdin for RPC (blank screen), so drop --embed when stdin is a terminal.
nvim() {
  [[ $1 == --embed && -t 0 ]] && shift
  command nvim "$@"
}

# Shell integrations
eval "$(fzf --zsh)"



export PATH=/opt/homebrew/bin:/opt/homebrew/sbin:/opt/homebrew/opt/mysql-client/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:~/.local/bin:~/.cargo/bin:/nix/var/nix/profiles/default/bin:/opt/homebrew/opt/postgresql@18/bin:/Users/pawan/dragterm/dragterm



source ~/.zsh_alias


function yy() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# Python environment management
penv() {
    pyenv virtualenv 3.13.0 $(basename $(pwd)) && pyenv local $(basename $(pwd))
}

# Pyenv initialization
# --no-rehash skips the shim rebuild on every shell start (faster panes, and
# avoids wedging on a stale ~/.pyenv/shims/.pyenv-shim lock). Run `pyenv rehash`
# by hand after installing a package that adds a new executable.
#
# Both inits emit the same script every time but cost ~140ms of fork+exec to do
# it — half of total startup — so cache their output and just source it. Cached
# rather than lazy-loaded on purpose: lazy-loading would leave virtualenv-init's
# auto-activate hook uninstalled until the first `pyenv` call. The cache is
# rebuilt whenever the pyenv binary is newer than it, i.e. after a brew upgrade.
_pyenv_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/pyenv-init.zsh"
if [[ ! -s $_pyenv_cache || $commands[pyenv] -nt $_pyenv_cache ]]; then
  mkdir -p ${_pyenv_cache:h}
  { pyenv init - --no-rehash
    which pyenv-virtualenv-init >/dev/null && pyenv virtualenv-init -
  } >| $_pyenv_cache
fi
source $_pyenv_cache

# Utility functions
mkdircd() {
    mkdir -p -- "$1" && cd -P -- "$1"
}

# UI improvements
export PROMPT_EOL_MARK=""           # Hide EOL sign ('%')
bindkey -s '^t' '^uyy\n'           # Ctrl+T opens yazi

# Node Version Manager (lazy-loaded — eager sourcing cost ~330ms/77% of startup)
export NVM_DIR="$HOME/.nvm"
_load_nvm() {
    unset -f nvm node npm npx 2>/dev/null
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}
nvm()  { _load_nvm; nvm  "$@"; }
node() { _load_nvm; node "$@"; }
npm()  { _load_nvm; npm  "$@"; }
npx()  { _load_nvm; npx  "$@"; }

# Ctrl+X Ctrl+E to edit the current command line in $EDITOR
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line
