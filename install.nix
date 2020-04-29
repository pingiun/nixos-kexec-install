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

          set -e

          wipefs -a ${cfg.rootDevice}

          parted ${cfg.rootDevice} -- mklabel msdos
          parted ${cfg.rootDevice} -- mkpart primary 1MiB ${toString cfg.bootSize}MiB
          parted ${cfg.rootDevice} -- mkpart primary ${toString cfg.bootSize}MiB 100%

          mkfs.ext4 ${cfg.rootDevice}

          zpool create ${cfg.poolName} ${cfg.rootDevice}2
          zfs create -o mountpoint=legacy -o xattr=sa -o acltype=posixacl ${cfg.poolName}/local/root
          zfs create -o mountpoint=legacy ${cfg.poolName}/local/nix
          zfs create -o mountpoint=legacy ${cfg.poolName}/safe/persist

          # From: https://github.com/zfsonlinux/pkg-zfs/wiki/HOWTO-use-a-zvol-as-a-swap-device
          zfs create -V ${toString cfg.swapSize}M -b $(getconf PAGESIZE) -o compression=zle \
          -o logbias=throughput -o sync=always \
          -o primarycache=metadata -o secondarycache=none \
          -o com.sun:auto-snapshot=false rpool/swap
          mkswap -f /dev/zvol/rpool/swap
          swapon /dev/zvol/rpool/swap

          mkdir -p /mnt

          mount -t zfs ${cfg.poolName}/local/root /mnt/
          mkdir /mnt/{persist,nix,boot}
          mount ${cfg.rootDevice}1 /mnt/boot
          mount -t zfs ${cfg.poolName}/persist /mnt/persist/
          mount -t zfs ${cfg.poolName}/nix /mnt/nix/

          nixos-generate-config --root /mnt/

          hostId=$(echo $(head -c4 /dev/urandom | od -A none -t x4))

          cat > /mnt/etc/nixos/generated.nix <<EOF
          { ... }:
          {
            boot.loader.grub.device = "${cfg.rootDevice}";
            networking.hostId = "$hostId"; # required for zfs use
          }
          EOF

          nix-channel --update
          nixos-install --no-root-passwd

          zpool export ${cfg.poolName}
          swapoff $SWAP_DEVICE
          reboot
        '';
      };
    };
  };
}
