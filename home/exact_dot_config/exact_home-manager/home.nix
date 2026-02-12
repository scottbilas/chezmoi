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

  home.packages = [

    # cli
    pkgs.bat
    pkgs.chezmoi
    pkgs.delta
    pkgs.difftastic
    pkgs.eza
    pkgs.fd
    pkgs.fzf
    pkgs.git
    pkgs.git-lfs
    pkgs.git-sizer
    pkgs.glab
    pkgs.gh  # gh auth login
    pkgs.hyperfine
    pkgs.jsonnet
    pkgs.numbat
    pkgs.patchutils
    pkgs.ripgrep
    pkgs.rsync
    pkgs.scrcpy
    pkgs.sheldon
    pkgs.shellcheck
    pkgs.starship
    pkgs.wget
    pkgs.yq-go
    pkgs.zoxide

    # shells
    pkgs.nushell
    pkgs.powershell

    # tui
    pkgs.basalt
    pkgs.btop
    pkgs.gdu
    pkgs.lazygit
    pkgs.micro
    pkgs.neovim
    pkgs.ranger
    pkgs.tmux

    # python
    pkgs.pipx
    pkgs.python3
    pkgs.uv

    # other environments
    pkgs.cmake
    pkgs.go
    pkgs.nodejs_24
    (pkgs.pnpm.override { nodejs = pkgs.nodejs_24; }) # nix default is node 22
    pkgs.ollama

    # gui
    pkgs.keka
    pkgs.obsidian
    pkgs.yt-dlp
    pkgs.wezterm
  ];
}
