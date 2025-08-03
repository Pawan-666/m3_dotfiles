# macOS Dotfiles

This repository contains personal dotfiles for macOS, managed using [GNU Stow](https://www.gnu.org/software/stow/). Each directory represents a different tool or application configuration.

## Prerequisites

Install GNU Stow using Homebrew:
```bash
brew install stow
```

## Git Stow Setup Process

### Initial Repository Setup
```bash
# Clone this repository to your home directory
cd ~
git clone <your-repo-url> mac_dotfiles
cd mac_dotfiles
```

### First-time Setup for Each Tool

For each tool directory, follow this pattern:
```bash
# 1. Create the appropriate directory structure
mkdir -p <tool>/.config/<tool>  # or mkdir -p <tool>/Library/Application\ Support/<tool>

# 2. Copy existing config to the dotfiles directory
cp -r ~/.config/<tool>/* <tool>/.config/<tool>/  # or appropriate source path

# 3. Remove the original config directory
rm -rf ~/.config/<tool>  # or appropriate target path

# 4. Stow the dotfiles (creates symlinks)
stow <tool>
```

### Example: Setting up Yazi
```bash
# Create directory structure
mkdir -p yazi/.config/yazi

# Copy existing config
cp -r ~/.config/yazi/* yazi/.config/yazi/

# Remove original
rm -rf ~/.config/yazi

# Stow the config (creates symlink ~/.config/yazi -> ~/mac_dotfiles/yazi/.config/yazi)
stow yazi
```

### Daily Usage

After initial setup, use these commands:
```bash
# Apply/update configs (creates symlinks)
stow <tool>

# Remove symlinks (useful when making changes)
stow -D <tool>

# Re-stow (remove and apply again)
stow -R <tool>

# Stow all tools at once
stow */
```

## Directory Structure & Configurations

### aerospace/ - AeroSpace Window Manager
Tiling window manager for macOS with i3-like features.

**Config Files:**
- `aerospace.toml` - Main configuration file

**Key Features:**
- Automatic workspace assignments for different apps
- Custom keybindings using Cmd/Alt modifiers
- Gaps configuration and floating window rules
- Service mode for advanced operations

**Basic Setup:**
```bash
# Install AeroSpace
brew install --cask nikitabobko-aerospace

# Stow config
stow aerospace
```

### borders/ - Window Borders
Adds colorful borders around windows to improve visual focus.

**Config Files:**
- `bordersrc` - Border styling configuration

**Key Features:**
- Round border style with customizable width
- Active/inactive color schemes
- HiDPI support

**Basic Setup:**
```bash
# Install borders
brew tap FelixKratz/formulae
brew install borders

# Stow config
stow borders

# Start service
brew services start borders
```

### ghostty/ - Terminal Emulator
A fast, native terminal emulator.

**Config Files:**
- `config` - Main terminal configuration

**Key Features:**
- Gruvbox theme with opacity support
- JetBrains Nerd Font configuration
- Custom keybindings for tmux integration
- Hidden titlebar for minimal design

**Basic Setup:**
```bash
# Install Ghostty (when available)
# Currently in beta - check https://ghostty.org/

# Stow config
stow ghostty
```

### k9s/ - Kubernetes CLI Manager
Terminal-based UI for managing Kubernetes clusters.

**Config Files:**
- `config.yaml` - Main k9s configuration
- `skins/transparent.yaml` - Transparent theme

**Key Features:**
- Transparent skin that preserves terminal background
- Custom refresh rates and resource limits
- Pod shell configuration with busybox

**Basic Setup:**
```bash
# Install k9s
brew install k9s

# Stow config (note: different path structure)
stow k9s
```

### mpv/ - Media Player
Minimalist command-line media player.

**Config Files:**
- `mpv.conf` - Main player configuration
- `input.conf` - Custom keybindings

**Key Features:**
- Auto-save position on quit
- Custom subtitle size and controls
- Vim-like navigation keybindings
- Window maximization by default

**Basic Setup:**
```bash
# Install mpv
brew install mpv

# Stow config
stow mpv
```

### sketchybar/ - Menu Bar
Highly customizable menu bar replacement.

**Config Files:**
- `sketchybarrc` - Main configuration script

**Key Features:**
- Minimal black bar design
- Catppuccin color scheme ready
- Extensible with custom modules
- System event subscriptions

**Basic Setup:**
```bash
# Install sketchybar
brew tap FelixKratz/formulae
brew install sketchybar

# Stow config
stow sketchybar

# Start service
brew services start sketchybar
```

### vscode/ - Visual Studio Code
Code editor configuration.

**Config Files:**
- `settings.json` - Editor settings and preferences
- `keybindings.json` - Custom keybindings for Vim mode

**Key Features:**
- Vim mode with custom keybindings
- Space-based leader key shortcuts
- File explorer navigation with vim keys
- Catppuccin theme integration

**Basic Setup:**
```bash
# Install VS Code
brew install --cask visual-studio-code

# Stow config
stow vscode
```

### yazi/ - File Manager
Blazingly fast terminal file manager written in Rust.

**Config Files:**
- `yazi.toml` - Main configuration
- `keymap.toml` - Custom keybindings
- `init.lua` - Lua initialization script
- `package.toml` - Plugin configuration

**Key Features:**
- Vim-like navigation
- Built-in preview support
- Custom opener rules for different file types
- Plugin system support

**Basic Setup:**
```bash
# Install yazi
brew install yazi

# Install optional dependencies
brew install ffmpegthumbnailer unar jq poppler fd ripgrep fzf zoxide

# Stow config
stow yazi
```

### zsh/ - Z Shell
Shell configuration with modern features.

**Config Files:**
- `.zshrc` - Main shell configuration

**Key Features:**
- Zinit plugin manager
- Powerlevel10k prompt
- Modern plugins (syntax highlighting, autosuggestions, fzf-tab)
- Custom aliases and functions
- History optimization
- Yazi integration function

**Basic Setup:**
```bash
# Zinit will be auto-installed on first run
# Stow config
stow zsh

# Source the new config
source ~/.zshrc
```

## Managing Configuration Changes

### Adding a New Tool
1. Create directory: `mkdir -p newtool/.config/newtool`
2. Add your config files to the directory
3. Stow it: `stow newtool`
4. Update this README with the new tool information

### Updating Existing Configs
1. Edit files directly in the dotfiles directory
2. Changes are automatically reflected (symlinks)
3. For major changes, test with: `stow -R <tool>`

### Backing Up Before Changes
```bash
# Unstow before major edits
stow -D <tool>

# Edit files
# ...

# Re-stow when ready
stow <tool>
```

## Troubleshooting

### Common Issues
- **Symlink conflicts**: Use `stow -D <tool>` then `stow <tool>`
- **Permission errors**: Check file ownership and permissions
- **Missing directories**: Some tools create config dirs on first run

### Useful Commands
```bash
# Check what would be stowed (dry run)
stow -n <tool>

# Verbose output for debugging
stow -v <tool>

# Target different directory
stow -t /path/to/target <tool>
```