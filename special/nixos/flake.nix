{
  description = "NixOS system configuration";

  # Pinning nixpkgs to a specific channel here (rather than using nix-channel) means:
  # 1. nixos-rebuild uses exactly this nixpkgs commit, which is fully built by Hydra
  #    and available in the binary cache (cache.nixos.org) - no local compilation.
  # 2. The pinned commit is recorded in flake.lock, making builds reproducible.
  # 3. No manual `nix-channel --add/--update` needed - the source is declarative.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = { self, nixpkgs }: {
    # nixos-rebuild looks up nixosConfigurations.${hostname} in this flake.
    # The hostname is substituted by bootstrap.sh at generation time (same as profile.nix)
    # to avoid impure filesystem reads, which are forbidden in flake pure eval mode.
    nixosConfigurations."@hostname@" = nixpkgs.lib.nixosSystem {
      # nixos-generate-config writes nixpkgs.hostPlatform into hardware-configuration.nix
      # (e.g. "x86_64-linux"), so we don't need to repeat it here.
      modules = [ ./configuration.nix ];
    };
  };
}
