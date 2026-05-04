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
    git-filter-repo
    git-lfs
    gnutar
    git-sizer
    glab
    gh  # 'gh auth login' to use
    hyperfine
    jsonnet
    markdownlint-cli2
    marksman
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
    yaml-language-server
    yq-go
    zoxide

    # shells
    (nushell.overrideAttrs { doCheck = false; }) # SHLVL test flaky in nix sandbox
    powershell

    # tui
    basalt
    btop
    fresh-editor
    gdu
    lazygit
    micro
    neovim
    ranger
    tmux
    zenith

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

    # ai
    claude-code.packages.${pkgs.system}.default
  ];
}
