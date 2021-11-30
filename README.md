# Chezmoi-based dotfiles (WIP)

_currently a "clean" aux project, eventually will take over dotfiles entirely_

## Setup

```powershell
# do stuff in ps1sh to get poshcore7
scoop install chezmoi
chezmoi init --config-format yaml scottbilas/chezmoi
cd ~/Documents/PowerShell
./setup
```

## Conventions

* `.config` and its contents are `exact` by default so anything new shows up and can decide whether to add to cm/git.
* Use non-`exact` naming to exclude a subfolder that don't want to (fully) track. Add a `.keep` file when totally ignoring the folder.

## Catalog of external dependencies

These paths are expected to exist..

### Personal

### Work

* `~/Sync/Private` - shared private data
