{
  description = "NixOS system configuration";

  # Pinning nixpkgs to a specific channel here (rather than using nix-channel) means:
  # 1. nixos-rebuild uses exactly this nixpkgs commit, which is fully built by Hydra
  #    and available in the binary cache (cache.nixos.org) - no local compilation.
  # 2. The pinned commit is recorded in flake.lock, making builds reproducible.
  # 3. No manual `nix-channel --add/--update` needed - the source is declarative.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = { self, nixpkgs }:
    let
      # nixos-rebuild looks up nixosConfigurations.${hostname} in this flake.
      # By reading the hostname at eval time rather than hardcoding it, this same
      # flake.nix works on any machine without modification - bootstrap.sh drops it
      # into /etc/nixos as-is. The hostname on first boot comes from the ISO default;
      # after the first rebuild it matches networking.hostName set in profile.nix.
      hostname = builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile /etc/hostname);
    in {
      nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
        # nixos-generate-config writes nixpkgs.hostPlatform into hardware-configuration.nix
        # (e.g. "x86_64-linux"), so we don't need to repeat it here.
        modules = [ ./configuration.nix ];
      };
    };
}
