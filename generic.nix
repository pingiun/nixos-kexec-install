{ lib, pkgs, config, ... }:

with lib;

{
  imports = [
    <nixpkgs/nixos/modules/profiles/installation-device.nix>
    ./common.nix
  ];
}
