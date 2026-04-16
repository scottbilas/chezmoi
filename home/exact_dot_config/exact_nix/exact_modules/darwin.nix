# macOS system configuration (nix-darwin module)

{ inputs, username, hostname, system, packagesModule }: { pkgs, lib, config, ... }: {

  imports = [
    (import ./brew.nix { inherit inputs username; })
    inputs.home-manager.darwinModules.home-manager
    inputs.mac-app-util.darwinModules.default
  ];

  nixpkgs.hostPlatform = system; # nix-darwin still warns "'system' has been renamed" — upstream issue, not ours
  home-manager.users.${username} = packagesModule;

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
  networking.hostName = hostname;       # used for dns and the shell prompt
  networking.localHostName = hostname;  # bonjour networking
  networking.computerName = hostname;   # user-friendly name used in finder etc

  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.text = ''
    auth optional ${pkgs.pam-reattach}/lib/pam/pam_reattach.so
    auth sufficient pam_tid.so
  '';

  system.primaryUser = username;
  users.users.${username}.home = "/Users/${username}";
  system.configurationRevision = null; # set by flake.nix
  system.stateVersion = 6;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # apple system settings
  system.defaults.finder.AppleShowAllFiles = true; # show hidden files (like dotfiles)
  system.defaults.dock.show-recents = false; # dislike recents appearing in dock
  system.defaults.NSGlobalDomain."com.apple.keyboard.fnState" = true; # F1/F2/etc without holding Fn

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # pmset not supported yet by nix-darwin so have to script it (note that this is not idempotent)
  system.activationScripts.customPmsetSettings = ''
    /usr/bin/pmset -b powernap 0      # powernap will wake a lot during sleep to check for updates, don't care (-b battery only)
    /usr/bin/pmset -b womp 0          # wake on lan, don't need (-b battery only)
    /usr/bin/pmset -c sleep 0         # no idle sleep on AC (lid close still triggers sleep independently)
  '';

  # disable annoying Tips app
  system.activationScripts.disableTips.text = ''
    /bin/launchctl disable "gui/$(id -u)/com.apple.tipsd" || true
  '';

  # === home-manager ===

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.sharedModules = [
    inputs.mac-app-util.homeManagerModules.default # creates Finder aliases so nix GUI apps appear in Spotlight
  ];
}
