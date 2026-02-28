# Then backup
cd /mnt/two/backups/sable-system

# EFI - dd (512MB, fast)
sudo dd if=/dev/sda1 bs=4M status=progress | gzip > sable-efi.img.gz

# Boot - dd (2GB, fast)
sudo dd if=/dev/sda2 bs=4M status=progress | gzip > sable-boot.img.gz

# Root - partclone (only used blocks, fast)
sudo partclone.ext4 -c -s /dev/sda3 | gzip > sable-root.img.gz

# Verify
ls -lh /mnt/two/backups/sable-system/
