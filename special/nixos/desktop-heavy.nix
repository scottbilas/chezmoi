# Modern desktop for VM / capable machines
{ config, lib, pkgs, ... }:

{
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.xrdp = {
    enable = true;
    openFirewall = true;
    defaultWindowManager = "gnome-session";
  };
}
