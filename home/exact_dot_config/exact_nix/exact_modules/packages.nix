# portable packages for all platforms (home-manager module)

{ username, homeDir, claude-code }: { pkgs, ... }:

{
  home.stateVersion = "24.05";
  home.username = username;
  home.homeDirectory = homeDir;
  news.display = "silent";

  home.packages = with pkgs; [

    # cli
    bat
    chezmoi
    delta
    difftastic
    eza
    fd
    ffmpeg
    fzf
    git
    git-lfs
    gnutar
    git-sizer
    glab
    gh  # gh auth login
    hyperfine
    jsonnet
    markdownlint-cli2
    numbat
    patchutils
    ripgrep
    rclone
    rsync
    scrcpy
    sheldon
    shellcheck
    starship
    wget
    yq-go
    zoxide

    # shells
    (nushell.overrideAttrs { doCheck = false; }) # SHLVL test flaky in nix sandbox
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

    # ai
    claude-code.packages.${pkgs.system}.default
  ];
}
