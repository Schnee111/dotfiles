#!/usr/bin/env bash
# ==============================================================================
# Setup Permissions for ASUS Battery Limit & Power Profile
# Run with: sudo ./setup_power_permissions.sh
# ASUS laptops only, optional, one-time. Makes the sysfs nodes writable by the asus-power group.
# ==============================================================================
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run with sudo: sudo $0" >&2
    exit 1
fi

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "0. Creating the asus-power group..."
getent group asus-power >/dev/null || groupadd --system asus-power
TARGET_USER="${SUDO_USER:-}"
if [[ -n "$TARGET_USER" && "$TARGET_USER" != "root" ]]; then
    usermod -aG asus-power "$TARGET_USER"
    echo "   added $TARGET_USER to asus-power (log out and back in for it to apply)"
else
    echo "   no sudo user found: add yourself with 'sudo usermod -aG asus-power <user>'"
fi

echo "1. Installing udev rule (/etc/udev/rules.d/98-asus-power.rules)..."
cp "$DOTFILES_DIR/common/udev/98-asus-power.rules" /etc/udev/rules.d/98-asus-power.rules

echo "2. Installing tmpfiles config (/etc/tmpfiles.d/asus-power.conf)..."
cp "$DOTFILES_DIR/common/tmpfiles/asus-power.conf" /etc/tmpfiles.d/asus-power.conf

echo "3. Installing systemd boot service (/etc/systemd/system/asus-power-permissions.service)..."
cp "$DOTFILES_DIR/common/systemd/system/asus-power-permissions.service" /etc/systemd/system/asus-power-permissions.service
systemctl daemon-reload
systemctl enable --now asus-power-permissions.service >/dev/null 2>&1 || true

echo "4. Removing the legacy polkit rule, if an earlier run installed it..."
# It allowed any wheel user to run an arbitrary pkexec bash command containing
# the platform_profile path as root. The sysfs nodes are writable directly now.
rm -f /etc/polkit-1/rules.d/90-asus-power.rules

echo "5. Reloading udev rules & applying permissions..."
udevadm control --reload
udevadm trigger --subsystem-match=power_supply || true
udevadm trigger --subsystem-match=platform || true
systemd-tmpfiles --create /etc/tmpfiles.d/asus-power.conf || true

# Explicitly ensure ownership and mode right now
for node in /sys/class/power_supply/BAT0/charge_control_end_threshold /sys/firmware/acpi/platform_profile /sys/devices/platform/asus-nb-wmi/throttle_thermal_policy; do
    chgrp asus-power "$node" 2>/dev/null || true
    chmod 0664 "$node" 2>/dev/null || true
done
echo 80 > /sys/class/power_supply/BAT0/charge_control_end_threshold 2>/dev/null || true

echo "---"
echo "Setup successfully completed!"
echo "Battery Limit : $(cat /sys/class/power_supply/BAT0/charge_control_end_threshold 2>/dev/null || echo 'N/A')%"
echo "Power Profile : $(cat /sys/firmware/acpi/platform_profile 2>/dev/null || echo 'N/A')"
