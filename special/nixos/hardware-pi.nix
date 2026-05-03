# Boot configuration for Raspberry Pi / ARM boards without UEFI
#
# The Pi has no BIOS or UEFI. Instead, the SoC's VideoCore GPU runs first on
# power-on, reads start.elf + config.txt from the SD card, then hands off to
# the CPU. NixOS hooks into this via extlinux, writing a boot menu to
# /boot/extlinux/extlinux.conf that the Pi firmware knows how to read.
#
# Note: nixos-generate-config on a Pi will typically generate these same
# settings automatically. This file exists so the profile can include it
# explicitly without relying on that.
{ ... }:

{
  # GRUB and systemd-boot are for BIOS/UEFI machines — disable both on Pi
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub.enable = false;

  # Generate /boot/extlinux/extlinux.conf on each rebuild.
  # This is the boot menu format understood by the Pi's firmware and
  # by U-Boot on other ARM SBCs that lack UEFI.
  boot.loader.generic-extlinux-compatible.enable = true;
}
