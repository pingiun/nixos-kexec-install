{ lib, pkgs, config, ... }:

with lib;

{
  imports = [
    <nixpkgs/nixos/modules/installer/netboot/netboot.nix>
    <nixpkgs/nixos/modules/profiles/all-hardware.nix>
    <nixpkgs/nixos/modules/profiles/base.nix>
    <nixpkgs/nixos/modules/profiles/minimal.nix>
    ./autoreboot.nix ./kexec.nix ./install.nix ];

  system.build.squashfsStore = pkgs.callPackage <nixpkgs/nixos/lib/make-squashfs.nix> {
    storeContents = config.netboot.storeContents;
    comp = "xz";
  };

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    # Allow the graphical user to login without password
    initialHashedPassword = "";
  };
  users.users.root.initialHashedPassword = "";
  services.mingetty.autologinUser = "nixos";

  hardware.enableRedistributableFirmware = mkForce false;

  security.sudo = {
    enable = mkDefault true;
    wheelNeedsPassword = mkForce false;
  };

  boot.supportedFilesystems = [ "zfs" ];
  boot.loader.grub.enable = false;
  boot.kernelParams = [
    "console=ttyS0,115200"          # allows certain forms of remote access, if the hardware is setup right
    "panic=30" "boot.panic_on_fail" # reboot the machine upon fatal boot issues
  ];
  services.openssh.enable = true;

  networking.hostName = "kexec";
}
