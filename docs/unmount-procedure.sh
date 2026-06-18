sudo umount /mnt/sable/dev/pts
sudo umount /mnt/sable/dev
sudo umount /mnt/sable/proc
sudo umount /mnt/sable/sys
sudo umount /mnt/sable/run
sudo umount /mnt/sable/boot/efi
sudo umount /mnt/sable/boot
sudo umount /mnt/sable

findmnt | grep sable
