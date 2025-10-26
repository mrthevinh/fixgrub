#!/bin/bash
set -e

echo "======================================"
echo "[*] Auto GRUB Repair for Ubuntu (UEFI)"
echo "======================================"
sleep 2

ROOT_DEV=$(lsblk -lpno NAME,FSTYPE | grep ext4 | awk '{print $1}' | head -n 1)
EFI_PART=$(lsblk -lpno NAME,FSTYPE | grep vfat | awk '{print $1}' | head -n 1)

echo "[i] Root device  : $ROOT_DEV"
echo "[i] EFI partition: $EFI_PART"

if [[ -z "$ROOT_DEV" || -z "$EFI_PART" ]]; then
  echo "[!] Không tìm thấy phân vùng Ubuntu hoặc EFI!"
  echo "Vui lòng chạy 'lsblk -f' để kiểm tra thủ công."
  exit 1
fi

MNT=/mnt/repair
mkdir -p $MNT

echo "[*] Mounting system..."
mount $ROOT_DEV $MNT
mount $EFI_PART $MNT/boot/efi

for d in /dev /proc /sys /run; do
  mount --bind $d $MNT$d
done

echo "[*] Installing GRUB..."
chroot $MNT /bin/bash -c "
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ubuntu --recheck;
update-initramfs -u -k all;
update-grub;
"

echo "[*] Cleaning up..."
umount -R $MNT

echo "======================================"
echo "[✓] GRUB fixed successfully!"
echo "Now reboot and remove the USB."
echo "======================================"
