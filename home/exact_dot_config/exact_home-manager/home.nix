# nix flake update --flake ~/.config/home-manager
# home-manager switch

{ pkgs, ... }:

let
  username = "scott.bilas"; # builtins.getEnv "USER";

in {
  nixpkgs.config.allowUnfree = true;

  home.stateVersion = "24.05";
  home.username = username;
  home.homeDirectory = "/Users/${username}";
  news.display = "silent";

  home.packages = with pkgs; [

    # cli
    bat
    chezmoi
    delta
    difftastic
    eza
    fd
    fzf
    git
    git-lfs
    git-sizer
    glab
    gh  # gh auth login
    hyperfine
    jsonnet
    markdownlint-cli2
    numbat
    patchutils
    ripgrep
    rsync
    scrcpy
    sheldon
    shellcheck
    starship
    wget
    yq-go
    zoxide

    # shells
    nushell
    powershell

    # tui
    basalt
    btop
    gdu
    lazygit
    micro
    neovim
    ranger
    tmux

    # python
    pipx
    python3
    uv

    # other environments
    cmake
    go
    nodejs_24
    (pnpm.override { nodejs = nodejs_24; }) # nix default is node 22
    ollama

    # gui
    keka
    obsidian
    wezterm
  ];
}
