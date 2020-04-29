let
  jobs = rec {

    tarball =
      let nixos = import <nixpkgs/nixos> { configuration = ./hetzner.nix; };
      in
        nixos.config.system.build.kexec_tarball;
  };
in
  jobs
