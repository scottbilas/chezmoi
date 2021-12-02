# Chezmoi-based dotfiles (WIP)

_currently a "clean" aux project, eventually will take over dotfiles entirely_

## Setup

```powershell
start https://aka.ms/powershell-release?tag=stable # install latest powershell from windows store
iwr https://raw.githubusercontent.com/scottbilas/dotfiles/rework/install.ps1sh | iex
cd ~/Documents/PowerShell
./setup
git remote set-url origin git@github.com:scottbilas/chezmoi.git
```

## Conventions

* `.config` and its contents are `exact` by default so anything new shows up and can decide whether to add to cm/git.
* Use non-`exact` naming to exclude a subfolder that don't want to (fully) track. Add a `.keep` file when totally ignoring the folder.

## Catalog of external dependencies

These paths are expected to exist..

### Personal

### Work

* `~/Sync/Private` - shared private data
