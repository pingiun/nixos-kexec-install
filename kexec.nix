{ pkgs, config, ... }:

{
  system.build = rec {
    image = pkgs.runCommand "image" { buildInputs = [ pkgs.nukeReferences ]; } ''
      mkdir $out
      cp ${config.system.build.kernel}/bzImage $out/kernel
      cp ${config.system.build.netbootRamdisk}/initrd $out/initrd
      echo "init=${builtins.unsafeDiscardStringContext config.system.build.toplevel}/init ${toString config.boot.kernelParams}" > $out/cmdline
      nuke-refs $out/kernel
    '';
    kexec_script = pkgs.writeTextFile {
      executable = true;
      name = "kexec-nixos";
      text = ''
        #!${pkgs.stdenv.shell}
        export PATH=${pkgs.kexectools}/bin:${pkgs.cpio}/bin:$PATH
        set -x
        set -e
        cd $(mktemp -d)
        pwd
        mkdir initrd
        pushd initrd
        if [ -e ~/.ssh/authorized_keys ]; then
          cat ~/.ssh/authorized_keys >> authorized_keys
        fi
        if [ -e /root/.ssh/authorized_keys ]; then
          cat /root/.ssh/authorized_keys >> authorized_keys
        fi
        if [ -e /install_script -a  ]; then
          cp /install_script install_script
        else
          echo "No install script found at /install_script, proceding without installation"
        fi
        find . -print0 | sort -z | cpio -o -H newc -R +0:+0 --reproducible --null | gzip -9 > ../extra.gz
        popd
        cat ${image}/initrd extra.gz > final.gz

        kexec -l ${image}/kernel --initrd=final.gz --append="init=${builtins.unsafeDiscardStringContext config.system.build.toplevel}/init ${toString config.boot.kernelParams}" --reset-vga
        sync
        echo "executing kernel, filesystems will be improperly umounted"
        kexec -e
        '';
    };
  };
  boot.initrd.postMountCommands = ''
    mkdir -p /mnt-root/root/.ssh/
    cp /authorized_keys /mnt-root/root/.ssh/
  '';
  system.build.kexec_tarball = pkgs.callPackage <nixpkgs/nixos/lib/make-system-tarball.nix> {
    storeContents = [
      { object = config.system.build.kexec_script; symlink = "/kexec_nixos"; }
    ];
    contents = [];
  };
}
