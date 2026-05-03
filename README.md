# Dotfiles

[Chezmoi](https://www.chezmoi.io/)-managed, multi-platform dotfiles.

## How it works

Chezmoi source lives under `home/` (set via `.chezmoiroot`). Templates and ignore rules handle platform differences so the same repo works everywhere.

Folders under `.config` use chezmoi's `exact_` prefix, which means untracked files show up in `chezmoi status` - making it easy to notice new configs and decide whether to track them. Folders that shouldn't be fully tracked drop the `exact_` prefix; folders to ignore entirely get a `.keep` file.

External dependencies (fonts, plugins, theme repos) are declared in `.chezmoiexternal.toml` rather than vendored. Private data lives in a separate repo and is never checked in here.

## NixOS Bringup

```sh
# generate hardware config (detects boot loader, filesystems, etc.); use --force to overwrite default 'minimal iso setup'
sudo nixos-generate-config --force

# bootstrap: fetches nix files from github, generates profile.nix (prompts for details)
curl -fsSL https://raw.githubusercontent.com/scottbilas/chezmoi/dev/special/nixos/bootstrap.sh | sudo bash
# can use `| sudo bash -s -- --dry-run` first to test

# build and activate
sudo nixos-rebuild switch

# set up dotfiles and home-manager
nix shell nixpkgs#chezmoi nixpkgs#git --command chezmoi init -a scottbilas/chezmoi

# activate home-manager config (packages, shell, tools)
home-manager switch --flake ~/.config/nix
```

> **Pi note:** when prompted for a profile, choose `pi`. The Pi has no UEFI —
> it boots via GPU firmware reading `config.txt` from the SD card, then extlinux.
> `nixos-generate-config` usually detects this correctly; `hardware-pi.nix` makes
> it explicit in case it doesn't.

## Mac Bringup

```sh
# ensure correct pooter
name='my-overpriced-mac'; for key in ComputerName LocalHostName HostName; do sudo scutil --set "$key" "$name"; done

# some packages may need to compile native code, for which we'll need this (note: runs gui app)
xcode-select --install

# install lix (nix-darwin recommends this over the official nix installer, and it will auto-escalate if needed)
curl -sSf -L https://install.lix.systems/lix | sh -s -- install --no-confirm

# pick up nix env in current shell
exec $SHELL -l

# set up dotfiles (which includes nix config)
nix shell nixpkgs#chezmoi nixpkgs#git --command chezmoi init -a scottbilas/chezmoi

# prep for nix-darwin
sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin
sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin

# set up nix-darwin (this gives a warning about HOME owner, which is expected)
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake ~/.config/nix

# one more time to pick up darwin/brew/hm stuff! (or can exit and switch to wezterm)
exec $SHELL -l
```

## License

[Dual-licensed](LICENSE.md): Public Domain (Unlicense) or MIT.
