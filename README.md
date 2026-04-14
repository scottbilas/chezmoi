# Dotfiles

[Chezmoi](https://www.chezmoi.io/)-managed, multi-platform dotfiles.

## How it works

Chezmoi source lives under `home/` (set via `.chezmoiroot`). Templates and ignore rules handle platform differences so the same repo works everywhere.

Folders under `.config` use chezmoi's `exact_` prefix, which means untracked files show up in `chezmoi status` — making it easy to notice new configs and decide whether to track them. Folders that shouldn't be fully tracked drop the `exact_` prefix; folders to ignore entirely get a `.keep` file.

External dependencies (fonts, plugins, theme repos) are declared in `.chezmoiexternal.toml` rather than vendored. Private data lives in a separate repo and is never checked in here.

## Mac Bringup

```sh
# ensure correct pooter
name='my-overpriced-mac'; for key in ComputerName LocalHostName HostName; do sudo scutil --set "$key" "$name"; done

# some packages may need to compile native code, for which we'll need this (note: runs gui app)
xcode-select --install

# install nix multi-user (single user not supported on mac)
curl -L https://nixos.org/nix/install | sh -s -- --daemon

# pick up nix env in curent shell
exec $SHELL -l

# set up dotfiles (which includes nix config)
nix-shell -p chezmoi git --run 'chezmoi init -a scottbilas/chezmoi'

# prep for nix-darwin
sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin
sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin
sudo touch /etc/synthetic.conf

# set up nix-darwin (this gives a warning about HOME owner, which is expected)
sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin/master#darwin-rebuild -- switch --flake ~/.config/nix

# one more time to pick up darwin/brew/hm stuff! (or can exit and switch to wezterm)
exec $SHELL -l
```

## License

[Dual-licensed](LICENSE.md): Public Domain (Unlicense) or MIT.
