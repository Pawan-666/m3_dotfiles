# Powerlevel10k instant prompt - keep at top for fast startup
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Homebrew setup (macOS)
if [[ -f "/opt/homebrew/bin/brew" ]] then
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
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# Initialize completions
autoload -Uz compinit && compinit
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
HISTDUP=erase
setopt appendhistory          # Append to history file
setopt sharehistory          # Share history between sessions
setopt hist_ignore_space     # Ignore commands starting with space
setopt hist_ignore_all_dups  # Remove all duplicate entries
setopt hist_save_no_dups     # Don't save duplicates
setopt hist_ignore_dups      # Don't record duplicate entries
setopt hist_find_no_dups     # Don't display duplicates in search

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
# zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
alias ls='ls --color'
alias vim='nvim'
alias vi='nvim'

# Shell integrations
eval "$(fzf --zsh)"
# eval "$(zoxide init --cmd cd zsh)"
#



export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:~/.local/bin




##############New addittion
# export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:~/.local/bin
# export EDITOR=lvim

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
eval "$(pyenv init -)"
if which pyenv-virtualenv-init > /dev/null; then eval "$(pyenv virtualenv-init -)"; fi

# Utility functions
mkdircd() {
    mkdir -p -- "$1" && cd -P -- "$1"
}

# UI improvements
export PROMPT_EOL_MARK=""           # Hide EOL sign ('%')
bindkey -s '^t' '^uyy\n'           # Ctrl+T opens yazi

# Node Version Manager
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Tmux-specific configuration
if [[ -n "$TMUX" ]]; then
    autoload -U edit-command-line
    zle -N edit-command-line
    bindkey '^X^E' edit-command-line    # Ctrl+X Ctrl+E to edit command line
fi
