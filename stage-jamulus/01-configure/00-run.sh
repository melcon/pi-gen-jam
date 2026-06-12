#!/bin/bash -e

install -m 0644 files/vncserver@.service "${ROOTFS_DIR}/etc/systemd/system/vncserver@.service"
install -m 0644 files/novnc.service "${ROOTFS_DIR}/etc/systemd/system/novnc.service"
install -m 0644 files/jackd.service "${ROOTFS_DIR}/etc/systemd/system/jackd.service"

install -d "${ROOTFS_DIR}/home/pi/.vnc"
install -m 0755 files/xstartup "${ROOTFS_DIR}/home/pi/.vnc/xstartup"

install -d "${ROOTFS_DIR}/home/pi/.config/lxsession/LXDE"
install -m 0644 files/lxde-autostart "${ROOTFS_DIR}/home/pi/.config/lxsession/LXDE/autostart"

install -m 0755 files/start-jamulus.sh "${ROOTFS_DIR}/home/pi/start-jamulus.sh"

on_chroot <<'EOF'
set -e

# Jamulus repo
curl -fsSL https://raw.githubusercontent.com/jamulussoftware/jamulus/main/linux/setup_repo.sh -o /tmp/setup_repo.sh
chmod +x /tmp/setup_repo.sh
/tmp/setup_repo.sh
apt-get update
apt-get install -y jamulus

# User permissions
usermod -aG audio,video,input,render pi

# JACK realtime permissions
cat >/etc/security/limits.d/audio.conf <<'LIMITS'
@audio - rtprio 95
@audio - memlock unlimited
LIMITS

# Disable onboard Wi-Fi and Bluetooth.
# Audio disabled via dtparam below; external USB audio remains usable.
cat >>/boot/firmware/config.txt <<'CONFIG'

# Jamulus appliance tuning
dtoverlay=disable-wifi
dtoverlay=disable-bt
dtparam=audio=off

# Prefer HDMI if present; VNC virtual X runs independently.
CONFIG

# Optional: disable wireless services if present
systemctl disable wpa_supplicant.service || true
systemctl disable bluetooth.service || true
systemctl mask hciuart.service || true

# LightDM autologin to pi on local HDMI desktop
mkdir -p /etc/lightdm/lightdm.conf.d
cat >/etc/lightdm/lightdm.conf.d/50-autologin.conf <<'LIGHTDM'
[Seat:*]
autologin-user=pi
autologin-user-timeout=0
user-session=LXDE
LIGHTDM

echo "/usr/sbin/lightdm" >/etc/X11/default-display-manager

if [ -f /lib/systemd/system/lightdm.service ]; then
  ln -sf /lib/systemd/system/lightdm.service /etc/systemd/system/display-manager.service
  systemctl enable display-manager.service || true
else
  echo "ERROR: /lib/systemd/system/lightdm.service not found for linking"
  dpkg -l | grep -E 'lightdm|lxde|xserver' || true
#  exit 1
fi

# VNC password: change this on first boot
install -d -o pi -g pi /home/pi/.vnc
#echo "jamulus" | /usr/bin/tigervncpasswd -f >/home/pi/.vnc/passwd
#chmod 600 /home/pi/.vnc/passwd
chown -R pi:pi /home/pi/.vnc

#systemctl enable lightdm
systemctl enable vncserver@1.service
systemctl enable novnc.service
systemctl enable jackd.service
EOF