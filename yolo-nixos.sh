#!/bin/sh

set -e

curl https://j2.lc/nixos-install.tar.xz > /root/nixos-install.tar.xz
tar xC / -f /root/nixos-install.tar.xz
/kexec_nixos
