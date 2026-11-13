# EliteBook dual-boot installer milestone — 2026-11-13

- QEMU verified partition planning, deployment to the selected root partition,
  boot from the installed disk with the ISO detached, and chainloading to a
  second EFI loader. The QEMU installer run used a temporary workaround for
  the missing SecureBoot variable.
- On the HP EliteBook 645 G9, the installer replaced the SableLinux root
  and reused its separate /boot and the shared EFI System Partition.
- Both installed SableLinux and Kubuntu booted from the new GRUB menu.
  The SableLinux Test firmware entry was registered manually after
  installation. F9 reaches that entry. Automatic power-on boot remains
  unresolved.
- The portable AMD GPIO test kernel restored the EliteBook touchpad in
  live boot. Workspace labeling was verified in QEMU.
- The ISO's Install entry still opens a test console. Automatic installer
  launch and firmware registration need work before migrating the Z890
  canonical installation. ASUS and HP Pavilion validation are pending.
