# Lightweight desktop for Pi / low-resource machines
{ config, lib, pkgs, ... }:

{
  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
    desktopManager.xfce.enable = true;
  };
  services.xrdp = {
    enable = true;
    openFirewall = true;
    defaultWindowManager = "startxfce4";
  };
}
