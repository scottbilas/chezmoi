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

    # homebrew
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-core = { url = "github:homebrew/homebrew-core"; flake = false; };
    homebrew-cask = { url = "github:homebrew/homebrew-cask"; flake = false; };
    sinelaw-homebrew-fresh = { url = "github:sinelaw/homebrew-fresh"; flake = false; };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, nix-homebrew, ... }:
  let
    system = "aarch64-darwin";
    username = "scott.bilas"; # builtins.getEnv "USER"; (no work)
  in {
    darwinConfigurations."scomac" = nix-darwin.lib.darwinSystem {
      specialArgs = { inherit inputs; };

      modules = [

        ({ pkgs, lib, ... }: {
          environment.systemPackages = [
            pkgs.home-manager
            pkgs.pam-reattach
          ];

          # nix-darwin by default makes a ca-certificates.crt, but some tools (like git) need it be named ca-bundle.crt
          environment.etc."ssl/certs/ca-bundle.crt" = {
            source = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          };

          # add zsh to /etc/shells (must manually do `chsh $(which zsh)` after rebuild, not supported by nix-darwin currently)
          environment.shells = [ pkgs.zsh ];

          # name of this mac
          networking.hostName = "scomac";       # used for dns and the shell prompt
          networking.localHostName = "scomac";  # bonjour networking
          networking.computerName = "scomac";   # user-friendly name used in finder etc

          security.pam.services.sudo_local.touchIdAuth = true;
          security.pam.services.sudo_local.text = ''
            auth optional ${pkgs.pam-reattach}/lib/pam/pam_reattach.so
            auth sufficient pam_tid.so
          '';

          system.primaryUser = username;
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

        nix-homebrew.darwinModules.nix-homebrew {
          nix-homebrew = {
            enable = true;
            user = username;
            autoMigrate = true;

            taps = with inputs; {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
              "sinelaw/homebrew-fresh" = sinelaw-homebrew-fresh;
            };
            mutableTaps = false; # taps can no longer be added imperatively with `brew tap`.
          };
        }
        # align homebrew taps config with nix-homebrew
        ({config, ...}: {
          homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
        })

        # used to generate a Brewfile
        # FUTURE: figure out how to make brew user-local (without sudo) for most things
        {
          homebrew.enable = true;
          homebrew.brews = [
            "fresh"
          ];
          homebrew.casks = [
            "coteditor"
            "visual-studio-code" # vscode is kept way more current with brew than nix
          ];
          
          # automatically remove packages and prefs and supporting files not listed in the configuration
          homebrew.onActivation.cleanup = "zap";
        }

        home-manager.darwinModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        }
      ];
    };
  };
}
