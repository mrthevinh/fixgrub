#!/bin/bash
set -e

echo "======================================"
echo "[*] Ubuntu Auto GRUB Repair v2 (UEFI)"
echo "======================================"

# --- Detect partitions ---
ROOT_LV=$(lsblk -lpno NAME,FSTYPE | grep ext4 | grep mapper | awk '{print $1}' | head -n 1)
EFI_PART=$(lsblk -lpno NAME,FSTYPE | grep vfat | grep -v cdrom | awk '{print $1}' | head -n 1)

if [[ -z "$ROOT_LV" || -z "$EFI_PART" ]]; then
  echo "[!] Không tìm thấy phân vùng root hoặc EFI!"
  lsblk -f
  exit 1
fi

echo "[i] Root LV : $ROOT_LV"
echo "[i] EFI part: $EFI_PART"
sleep 2

# --- Prepare mount points ---
MNT=/mnt/repair
echo "[*] Mounting system..."
sudo umount -R $MNT 2>/dev/null || true
sudo mkdir -p $MNT/boot/efi
sudo mount $ROOT_LV $MNT
sudo mount $EFI_PART $MNT/boot/efi

# --- Bind essential system dirs ---
echo "[*] Binding system dirs..."
for d in dev dev/pts proc sys run; do
  sudo mkdir -p $MNT/$d
  sudo mount --bind /$d $MNT/$d || sudo mount -t devpts devpts $MNT/$d || true
done

# --- Enter chroot and repair GRUB ---
echo "[*] Entering chroot..."
sudo chroot $MNT /bin/bash -c "
set -e
echo '[+] Installing GRUB...'
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ubuntu --recheck
echo '[+] Updating initramfs...'
update-initramfs -u -k all
echo '[+] Updating grub menu...'
update-grub
"

# --- Cleanup ---
echo "[*] Unmounting..."
sudo umount -R $MNT || true
echo "[✓] GRUB repair completed!"
echo "======================================"
echo "Now remove USB and reboot the system."
