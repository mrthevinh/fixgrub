#!/bin/bash
set -e
echo "[*] Cloning and running auto GRUB fix..."
TMPDIR=$(mktemp -d)
git clone https://github.com/mrthevinh/fixgrub.git "$TMPDIR"
cd "$TMPDIR"
sudo bash fix-grub-ubuntu.sh
