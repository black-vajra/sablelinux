# Synthetic guest deployment and independent EFI boot

Validated on canonical Z890 after the host-assembled EFI checkpoint
at 6b1a98c.

The deployment guest received a read-only source disk and a blank
640 MiB qcow2. It verified the source hashes, created and verified GPT,
wrote prepared FAT and ext4 images to the target partitions, and
verified both writes by hashing the partitions. The ext4 partition
retained the PARTUUID expected by the prepared GRUB configuration.

A separate QEMU launch used fresh OVMF variables and the target disk
alone. GRUB started, Linux mounted /dev/vda2 as writable ext4, and
the guest verified the prior persistence marker before remounting root
read-only and powering off. Both launches exited zero. The final
qcow2 structural check reported no errors.

Result: SABLE_GUEST_DEPLOY_AND_EFI_BOOT_PASS

Evidence: /var/tmp/sable-m112-e2e-FTJenTUh/guest-deploy-zJEYAgUP

This fixture deploys prepared partition images. The next installer
test will create the filesystems and extract the root payload inside
the guest, then boot the resulting disk independently. Release
userspace and metadata preservation remain separate validation gates.
