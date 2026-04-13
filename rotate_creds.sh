#!/bin/bash
# rotate_creds.sh - run on red team workstation only

# change cyberrange password
echo "cyberrange:delta_team123#321" | sudo chpasswd
echo "[+] cyberrange password rotated to delta_team123#321"

# ensure cyberrange is in sudo/wheel group
usermod -aG sudo cyberrange 2>/dev/null
usermod -aG wheel cyberrange 2>/dev/null

# ensure passwordless sudo
if ! grep -q "cyberrange" /etc/sudoers; then
    echo "cyberrange ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi

echo "[+] cyberrange confirmed sudo/wheel member"
echo "[+] done"