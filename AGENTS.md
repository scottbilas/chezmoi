# Workspace Instructions

## Editing Rule: Live Files First

When asked to edit, create, or modify files, **always target the deployed (live) file paths** — not the chezmoi source files in this repo.

- Edit `~/.config/git/config`, not `home/exact_dot_config/exact_git/config`
- Edit `~/.zshenv`, not `home/dot_zshenv`
- Edit `~/.config/starship.toml`, not the chezmoi source equivalent

My workflow is: make changes to live files, verify they work, then integrate back into chezmoi source myself. Do not run `chezmoi apply`, `chezmoi add`, or similar commands unless explicitly asked.

## Repository Context

This is a **chezmoi**-managed dotfiles repository. The source of truth lives under `home/` using chezmoi naming conventions:

| Prefix/Suffix | Meaning |
|---|---|
| `dot_` | Expands to `.` (e.g. `dot_zshenv` → `.zshenv`) |
| `exact_` | Directory is fully tracked (extra files get removed on apply) |
| `executable_` | File gets `+x` permission |
| `symlink_` | Creates a symlink |
| `.tmpl` | Go template, rendered by chezmoi with platform/machine variables |

Key paths:
- **Chezmoi source**: `~/.local/share/chezmoi/home/`
- **Chezmoi config**: `~/.config/chezmoi/`
- **Private data**: `~/.local/share/private/` (do not touch anything in here)

## Platforms

Configs target **macOS** (primary), **Windows** (PowerShell 7+), **Linux**, **WSL2**, and **Android/Termux**. Templates use platform conditionals — be aware of this when reading `.tmpl` files.

## Key Tools Managed

Shell (zsh, PowerShell, nushell), git, VSCode, bat, eza, fd, ripgrep, starship, lazygit, tmux, hammerspoon (macOS), karabiner (macOS).

## Security: Preflight Scan

This is a **public repo**. After making significant changes, invoke the `preflight-scan` skill to check for leaked secrets, private data, and work-related content before integrating back into chezmoi source. When in doubt, scan.
