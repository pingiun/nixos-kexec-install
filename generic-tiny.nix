{ lib, pkgs, config, ... }:

with lib;

{
  imports = [
    ./common.nix
  ];

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

  services.openssh.enable = true;
}
