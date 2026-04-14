# home-manager switch --flake ~/.config/home-manager
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code.url = "github:sadjow/claude-code-nix";
  };

  outputs = { self, nixpkgs, home-manager, claude-code }: {
    homeManagerModules.default = import ./home.nix;

    homeConfigurations."scott.bilas" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      extraSpecialArgs = { inherit claude-code; };
      modules = [ ./home.nix ];
    };
  };
}
