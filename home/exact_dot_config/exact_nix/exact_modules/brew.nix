# homebrew configuration (nix-darwin module)
# tap input URLs live in flake.nix (nix flake structural constraint)

{ inputs, username }: { pkgs, lib, config, ... }: {

  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

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

  # align homebrew taps config with nix-homebrew
  homebrew.taps = builtins.attrNames config.nix-homebrew.taps;

  # FUTURE: figure out how to make brew user-local (without sudo) for most things
  homebrew.enable = true;
  homebrew.brews = [
    "fresh"
    "yt-dlp"
  ];
  homebrew.casks = [
      "coteditor"
      "notunes"
    ] ++
    # these may exist on nix but we want latest latest for these tools
    (map (name: { inherit name; greedy = true; }) [
      "codex"
      "microsoft-edge"
      "visual-studio-code"
    ]);

  # automatically remove packages and prefs and supporting files not listed in the configuration
  homebrew.onActivation.cleanup = "zap";
  # upgrade outdated formulae and casks on nix-darwin activation (i.e. `darwin-rebuild switch`)
  homebrew.onActivation.upgrade = true;
}
