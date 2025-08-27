# sudo darwin-rebuild switch --flake ~/.config/nix-darwin

{
  description = "scomac nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, ... }:
  let
    system = "aarch64-darwin";
  in {
    darwinConfigurations."scomac" = nix-darwin.lib.darwinSystem {
      specialArgs = { inherit inputs; };

      modules = [

        ({ pkgs, ... }: {
          environment.systemPackages = [
            pkgs.home-manager
          ];

          # nix-darwin by default makes a ca-certificates.crt, but some tools (like git) need it be named ca-bundle.crt
          environment.etc."ssl/certs/ca-bundle.crt" = {
            source = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          };

          # name of this mac
          networking.hostName = "scomac";       # used for dns and the shell prompt
          networking.localHostName = "scomac";  # bonjour networking
          networking.computerName = "scomac";   # user-friendly name used in finder etc

          security.pam.services.sudo_local.touchIdAuth = true; # ??? unsure this works

          system.primaryUser = "scott.bilas";
          system.configurationRevision = self.rev or self.dirtyRev or null;
          system.stateVersion = 6;
          nix.settings.experimental-features = [ "nix-command" "flakes" ];
          nixpkgs.config.allowUnfree = true;
          nixpkgs.hostPlatform = system;

          # apple system settings
          system.defaults.finder.AppleShowAllFiles = true; # show hidden files (like dotfiles)
          system.defaults.dock.show-recents = false;      # dislike recents appearing in dock

          fonts.packages = with pkgs; [
            nerd-fonts.jetbrains-mono
          ];

          # pmset not supported yet by nix-darwin so have to script it (note that this is not idempotent)
          system.activationScripts.customPmsetSettings = ''
            /usr/bin/pmset -b powernap 0  # powernap will wake a lot during sleep to check for updates, don't care
            /usr/bin/pmset -b womp 0      # wake on lan, don't need
          '';
        })

        home-manager.darwinModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        }
      ];
    };
  };
}

# failed experiments
#
# keeping these here for now so i have some record of it (until i get this into gh)
#
# https://github.com/nix-darwin/nix-darwin/issues/1041#issuecomment-2893976650
# UPDATE: fuck it, can't get this working. background services issue still. abort.
# services.karabiner-elements = {
#   enable = true;
#   package = pkgs.karabiner-elements.overrideAttrs (old: {
#     version = "14.13.0";
#     src = pkgs.fetchurl {
#       inherit (old.src) url;
#       hash = "sha256-gmJwoht/Tfm5qMecmq1N6PSAIfWOqsvuHU8VDJY8bLw=";
#     };
#     dontFixup = true;
#   });
# };
