{ lib, pkgs, config, ... }:

with lib;

{
	imports = [ ./configuration.nix ];
	kexec.install.enable = true;
}
