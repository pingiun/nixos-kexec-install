{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.kexec.install;
in {
  options = {
    kexec.install = {
      enable = mkEnableOption "installation";
      rootDevice = mkOption {
        type = types.str;
        default = "/dev/sda";
      };
      bootSize = mkOption {
        type = types.int;
        default = 512;
        description = "size of /boot in mb";
      };
      swapSize = mkOption {
        type = types.int;
        default = 1024;
        description = "size of swap in mb";
      };
      poolName = mkOption {
        type = types.str;
        default = "rpool";
        description = "zfs pool name";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.services.install = {
      description = "Installation script";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeScript "install" ''
          #!${pkgs.stdenv.shell}

          export PATH=${with pkgs; makeBinPath [ systemd nix glibc utillinux zfs parted e2fsprogs config.system.build.nixos-install config.system.build.nixos-generate-config ]}:$PATH

          set -e

          wipefs -a ${cfg.rootDevice}

          parted -s ${cfg.rootDevice} -- mklabel msdos
          parted -s ${cfg.rootDevice} -- mkpart primary 1MiB ${toString cfg.bootSize}MiB
          parted -s ${cfg.rootDevice} -- mkpart primary ${toString cfg.bootSize}MiB 100%

          mkfs.ext4 ${cfg.rootDevice}1

          zpool create ${cfg.poolName} ${cfg.rootDevice}2
          # From: https://github.com/zfsonlinux/pkg-zfs/wiki/HOWTO-use-a-zvol-as-a-swap-device
          zfs create -V ${toString cfg.swapSize}M -b $(getconf PAGESIZE) -o compression=zle \
          -o logbias=throughput -o sync=always \
          -o primarycache=metadata -o secondarycache=none \
          -o com.sun:auto-snapshot=false rpool/swap
          zfs create -p -o mountpoint=legacy -o xattr=sa -o acltype=posixacl ${cfg.poolName}/local/root
          zfs create -p -o mountpoint=legacy ${cfg.poolName}/local/nix
          zfs create -p -o mountpoint=legacy ${cfg.poolName}/safe/persist

          mkswap -f /dev/zvol/rpool/swap
          swapon /dev/zvol/rpool/swap

          mkdir -p /mnt

          mount -t zfs ${cfg.poolName}/local/root /mnt/
          mkdir /mnt/{persist,nix,boot}
          mount ${cfg.rootDevice}1 /mnt/boot
          mount -t zfs ${cfg.poolName}/safe/persist /mnt/persist/
          mount -t zfs ${cfg.poolName}/local/nix /mnt/nix/

          nixos-generate-config --root /mnt/

          hostId=$(echo $(head -c4 /dev/urandom | od -A none -t x4))

          cat > /mnt/etc/nixos/configuration.nix <<EOF
          { ... }:
          {
            imports = [
              ./hardware-configuration.nix
            ];
            boot.loader.grub.enable = true;
            boot.loader.grub.version = 2;
            boot.loader.grub.device = "${cfg.rootDevice}";
            networking.hostId = "$hostId"; # required for zfs use

            networking.useDHCP = true;

            services.openssh.enable = true;
            users.users.root.openssh.authorizedKeys.keyFiles = [ /root/.ssh/authorized_keys ];

            system.stateVersion = "20.03";
          }
          EOF

          nix-channel --update
          nixos-install --no-root-passwd

          reboot
        '';
      };
    };
  };
}
