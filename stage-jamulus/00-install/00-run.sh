#!/bin/bash -e

install -m 0644 files/00-packages "${ROOTFS_DIR}/tmp/stage-jamulus-packages"

on_chroot <<'EOF'
apt-get update
xargs -a /tmp/stage-jamulus-packages apt-get install -y --no-install-recommends
rm -f /tmp/stage-jamulus-packages
EOF