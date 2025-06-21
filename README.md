#### dotfiles stowed


```bash
#initial setup
mkdir -p yazi/.config/yazi
cp -r ~/.config/yazi/* yazi/.config/yazi/
rm -rf ~/.config/yazi

stow yazi
```
