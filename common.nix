{ lib, pkgs, config, ... }:

with lib;

{
  imports = [
    <nixpkgs/nixos/modules/installer/netboot/netboot.nix>
    <nixpkgs/nixos/modules/profiles/all-hardware.nix>
    <nixpkgs/nixos/modules/profiles/base.nix>
    <nixpkgs/nixos/modules/profiles/minimal.nix>
    ./kexec.nix
    ./install.nix
  ];

  boot.supportedFilesystems = [ "zfs" ];
  boot.loader.grub.enable = false;
  boot.kernelParams = [
    "console=ttyS0,115200"          # allows certain forms of remote access, if the hardware is setup right
    "panic=30" "boot.panic_on_fail" # reboot the machine upon fatal boot issues
  ];
  services.openssh.enable = true;

  networking.hostName = "kexec";
}
