# Dotfiles

[Chezmoi](https://www.chezmoi.io/)-managed, multi-platform dotfiles.

## How it works

Chezmoi source lives under `home/` (set via `.chezmoiroot`). Templates and ignore rules handle platform differences so the same repo works everywhere.

Folders under `.config` use chezmoi's `exact_` prefix, which means untracked files show up in `chezmoi status` — making it easy to notice new configs and decide whether to track them. Folders that shouldn't be fully tracked drop the `exact_` prefix; folders to ignore entirely get a `.keep` file.

External dependencies (fonts, plugins, theme repos) are declared in `.chezmoiexternal.toml` rather than vendored. Private data lives in a separate repo and is never checked in here.

## License

[Dual-licensed](LICENSE.md): Public Domain (Unlicense) or MIT.
