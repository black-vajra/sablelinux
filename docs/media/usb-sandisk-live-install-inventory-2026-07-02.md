# USB Live/Install Disk 1 Inventory — 2026-07-02

Thu Jul  2 11:47:40 AM EDT 2026

## Device identity
NAME   RM   SIZE FSTYPE LABEL      UUID                                 MODEL           SERIAL                                                                                                                   MOUNTPOINTS
sdc     1 114.6G                                                        SanDisk 3.2Gen1 040114997484dd91867594c3905f3e1947fde5978bb0a5a2bbf1fe67bbd1f024558100000000000000000000752460d2ff8408189155810784ad3bd5 
├─sdc1  1   100M vfat   EFI        5CF9-CEE9                                                                                                                                                                     /mnt/inspect-usb1/efi
└─sdc2  1  14.5G ext4   SABLELINUX ad38f580-763e-49cc-aa40-7316afd804c0                                                                                                                                          /mnt/inspect-usb1/root

## By-id identity
lrwxrwxrwx 1 root root  9 Jul  2 11:45 usb-USB_SanDisk_3.2Gen1_040114997484dd91867594c3905f3e1947fde5978bb0a5a2bbf1fe67bbd1f024558100000000000000000000752460d2ff8408189155810784ad3bd5-0:0 -> ../../sdc
lrwxrwxrwx 1 root root 10 Jul  2 11:45 usb-USB_SanDisk_3.2Gen1_040114997484dd91867594c3905f3e1947fde5978bb0a5a2bbf1fe67bbd1f024558100000000000000000000752460d2ff8408189155810784ad3bd5-0:0-part1 -> ../../sdc1
lrwxrwxrwx 1 root root 10 Jul  2 11:45 usb-USB_SanDisk_3.2Gen1_040114997484dd91867594c3905f3e1947fde5978bb0a5a2bbf1fe67bbd1f024558100000000000000000000752460d2ff8408189155810784ad3bd5-0:0-part2 -> ../../sdc2

## Mounted read-only inspection points
TARGET                SOURCE    FSTYPE OPTIONS
/mnt/inspect-usb1/efi /dev/sdc1 vfat   ro,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=iso8859-1,shortname=mixed,errors=remount-ro
TARGET                 SOURCE    FSTYPE OPTIONS
/mnt/inspect-usb1/root /dev/sdc2 ext4   ro,relatime,norecovery

## EFI partition contents
1969-12-31 19:00 512 /mnt/inspect-usb1/efi
2026-05-03 22:35 512 /mnt/inspect-usb1/efi/EFI
2026-05-03 22:35 512 /mnt/inspect-usb1/efi/EFI/BOOT
2026-05-03 22:58 3289088 /mnt/inspect-usb1/efi/EFI/BOOT/BOOTX64.EFI

## Root partition top level
total 32K
drwxr-xr-x 5 root root 4.0K May  3 22:35 .
drwxr-xr-x 4 root root 4.0K Jul  2 11:41 ..
drwxr-xr-x 2 root root 4.0K May  3 22:37 boot
drwxr-xr-x 2 root root 4.0K Jun 18 17:51 live
drwx------ 2 root root  16K May  3 22:30 lost+found

## Root partition directory summary
2026-05-03 22:30 /mnt/inspect-usb1/root/lost+found
2026-05-03 22:35 /mnt/inspect-usb1/root
2026-05-03 22:37 /mnt/inspect-usb1/root/boot
2026-06-18 17:51 /mnt/inspect-usb1/root/live

## Boot files
2026-05-03 22:37 4096 /mnt/inspect-usb1/root/boot
2026-05-05 21:33 6137089 /mnt/inspect-usb1/root/boot/initramfs-live.img
2026-06-12 13:55 14119936 /mnt/inspect-usb1/root/boot/vmlinuz

## Live / ISO / SquashFS candidates
2026-05-05 21:33 6137089 /mnt/inspect-usb1/root/boot/initramfs-live.img
2026-06-12 13:55 14119936 /mnt/inspect-usb1/root/boot/vmlinuz
2026-06-18 17:55 7527149568 /mnt/inspect-usb1/root/live/filesystem.squashfs

## Installer candidates

## GRUB configs

## PAM / limits state on USB root, if present

--- /mnt/inspect-usb1/root/etc/pam.d/system-auth ---
missing

--- /mnt/inspect-usb1/root/etc/pam.d/system-session ---
missing

--- /mnt/inspect-usb1/root/etc/security/limits.conf ---
missing

--- /mnt/inspect-usb1/root/etc/security/limits.d/99-filedesc.conf ---
missing

## Sway / Waybar configs, if present

## sable-install hash comparison if present
No sable-install found on USB root within maxdepth.
