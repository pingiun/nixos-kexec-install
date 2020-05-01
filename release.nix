let
  jobs = rec {

    hetzner-install =
      let nixos = import <nixpkgs/nixos> { configuration = ./hetzner.nix; };
      in
        nixos.config.system.build.kexec_tarball;

    generic =
      let nixos = import <nixpkgs/nixos> { configuration = ./generic.nix; };
      in
        nixos.config.system.build.kexec_tarball;

    generic-tiny =
      let nixos = import <nixpkgs/nixos> { configuration = ./generic-tiny.nix; };
      in
        nixos.config.system.build.kexec_tarball;
  };
in
  jobs
