# home-manager switch

{ pkgs, ... }:

let
  username = "scott.bilas";
in {
  nixpkgs.config.allowUnfree = true;

  home.stateVersion = "24.05";
  home.username = username;
  home.homeDirectory = "/Users/${username}";

  home.packages = [

    # cli
    pkgs.bat
    pkgs.chezmoi
    pkgs.delta
    pkgs.eza
    pkgs.fd
    pkgs.git
    pkgs.git-lfs
    pkgs.ripgrep
    pkgs.sheldon
    pkgs.starship
    pkgs.wget

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

    # other environments
    pkgs.go
    pkgs.nodejs_24
    (pkgs.dotnetCorePackages.combinePackages [
      pkgs.dotnet-sdk_8
      pkgs.dotnet-sdk_9
    ])

    # gui
    pkgs.keka
    pkgs.obsidian
    pkgs.syncthing-macos
    pkgs.vscode
    pkgs.wezterm
  ];
}
