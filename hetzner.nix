{ lib, pkgs, config, ... }:

with lib;

{
  imports = [ ./generic-tiny.nix ];
  kexec.install.enable = true;
}
