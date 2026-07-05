# USB SanDisk Boot/SquashFS Analysis — 2026-07-02

Thu Jul  2 11:49:16 AM EDT 2026

## USB block identity
NAME   RM   SIZE FSTYPE LABEL      UUID                                 MODEL           SERIAL                                                                                                                   MOUNTPOINTS
sdc     1 114.6G                                                        SanDisk 3.2Gen1 040114997484dd91867594c3905f3e1947fde5978bb0a5a2bbf1fe67bbd1f024558100000000000000000000752460d2ff8408189155810784ad3bd5 
├─sdc1  1   100M vfat   EFI        5CF9-CEE9                                                                                                                                                                     /mnt/inspect-usb1/efi
└─sdc2  1  14.5G ext4   SABLELINUX ad38f580-763e-49cc-aa40-7316afd804c0                                                                                                                                          /mnt/inspect-usb1/root

## Core boot artifacts
2026-05-03 22:58:58.000000000 -0400 3289088 /mnt/inspect-usb1/efi/EFI/BOOT/BOOTX64.EFI
2026-06-12 13:55:28.179315731 -0400 14119936 /mnt/inspect-usb1/root/boot/vmlinuz
2026-05-05 21:33:37.930167671 -0400 6137089 /mnt/inspect-usb1/root/boot/initramfs-live.img
2026-06-18 17:55:50.659840155 -0400 7527149568 /mnt/inspect-usb1/root/live/filesystem.squashfs

## File type identification
/mnt/inspect-usb1/efi/EFI/BOOT/BOOTX64.EFI:      PE32+ executable for EFI (application), x86-64 (stripped to external PDB), 4 sections
/mnt/inspect-usb1/root/boot/vmlinuz:             Linux kernel x86 boot executable, bzImage, version 6.16.1-sable-compat (root@SableLinux) #13 SMP PREEMPT_DYNAMIC Sun May 24 20:02:07 EDT 2026, RO-rootFS, Normal VGA, setup size 512*39, syssize 0xd7240, jump 0x26c 0x8cd88ec0fc8cd239 instruction, protocol 2.15, from protected-mode code at offset 0x2c4 0xd6172c bytes gzip compressed, relocatable, handover offset 0xd6ec90, legacy 64-bit entry point, can be above 4G, 32-bit EFI handoff entry point, 64-bit EFI handoff entry point, EFI kexec boot support, xloadflags bit 5, max cmdline size 2047, init_size 0x2a72000
/mnt/inspect-usb1/root/boot/initramfs-live.img:  gzip compressed data, max compression, from Unix, original size modulo 2^32 10651136
/mnt/inspect-usb1/root/live/filesystem.squashfs: Squashfs filesystem, little endian, version 4.0, xz compressed, 7527146837 bytes, 357727 inodes, blocksize: 131072 bytes, created: Thu Jun 18 21:55:50 2026

## EFI bootloader strings: grub/config/path clues
grub_disk_read(): Maximum recursion depth exceeded
grub_mod_init
grub_mod_fini
prefix
Could not malloc memory to remember EFI allocation. Exiting GRUB won't free all memory.
prohibited by secure boot policy
Disabled
SecureBoot
UEFI Secure Boot state: %s
disable
prefix
grub rescue> 
verifier %s said GRUB_VERIFY_FLAGS_DEFER_AUTH
grub_abort
grub_acpi_find_fadt
grub_acpi_find_table
grub_byte_checksum
grub_calloc
grub_command_list
grub_current_context
grub_debug_enabled
grub_device_close
grub_device_iterate
grub_device_open
grub_disk_cache_table
grub_disk_close
grub_disk_dev_list
grub_disk_dev_register
grub_disk_dev_unregister
grub_disk_firmware_fini
grub_disk_firmware_is_tainted
grub_disk_native_sectors
grub_disk_open
grub_disk_read
grub_disk_write_weak
grub_divmod64
grub_dl_head
grub_dl_load
grub_dl_load_core_noinit
grub_dl_ref
grub_dl_ref_count
grub_dl_unload
grub_dl_unref
grub_dma_free
grub_dma_get_phys
grub_dma_get_virt
grub_efi_allocate_any_pages
grub_efi_allocate_fixed
grub_efi_allocate_pages_real
grub_efi_close_protocol
grub_efi_compare_device_paths
grub_efi_duplicate_device_path
grub_efi_find_configuration_table
grub_efi_find_last_device_path
grub_efi_find_mmap_size
grub_efi_finish_boot_services
grub_efi_free_pages
grub_efi_get_device_path
grub_efi_get_filename
grub_efi_get_loaded_image
grub_efi_get_memory_map
grub_efi_get_secureboot
grub_efi_get_variable
grub_efi_get_variable_with_attributes
grub_efi_image_handle
grub_efi_is_finished
grub_efi_load_image
grub_efi_locate_handle
grub_efi_locate_protocol
grub_efi_net_config
grub_efi_open_protocol
grub_efi_print_device_path
grub_efi_register_loader
grub_efi_set_text_mode
grub_efi_set_variable
grub_efi_set_variable_to_string
grub_efi_set_variable_with_attributes
grub_efi_set_virtual_address_map
grub_efi_stall
grub_efi_start_image
grub_efi_system_table
grub_efi_unload_image
grub_efi_unregister_loader
grub_efidisk_get_device_handle
grub_efidisk_get_device_name
grub_env_export
grub_env_get
grub_env_get_bool
grub_env_set
grub_env_unset
grub_env_update_get_sorted
grub_err_printed_errors
grub_errmsg
grub_errno
grub_error
grub_error_pop
grub_error_push
grub_exit
grub_fatal
grub_file_close
grub_file_filters
grub_file_get_device_name
grub_file_open
grub_file_progress_hook
grub_file_read
grub_file_seek
grub_file_verifiers
grub_free
grub_fs_autoload_hook
grub_fs_list
grub_fs_probe
grub_get_time_ms
grub_getkey
grub_getkey_noblock
grub_getkeystatus
grub_gettext
grub_is_lockdown
grub_isspace
grub_key_is_interrupt
grub_list_push
grub_list_remove
grub_lockdown
grub_machine_acpi_get_rsdpv1
grub_machine_acpi_get_rsdpv2
grub_machine_fini
grub_malloc
grub_memalign
grub_memalign_dma32
grub_memcmp
grub_memmove
grub_memset
grub_millisleep
grub_mm_add_region_fn
grub_mm_base
grub_modbase
grub_named_list_find
grub_net_open
grub_net_poll_cards_idle
grub_parser_cmdline_state
grub_parser_split_cmdline
grub_partition_get_name
grub_partition_iterate
grub_partition_map_list
grub_partition_probe
grub_pci_find_capability
grub_pci_iterate
grub_pci_make_address
grub_pmtimer_wait_count_tsc
grub_print_error
grub_printf
grub_printf_
grub_printf_fmt_check
grub_puts_
grub_real_dprintf
grub_realloc
grub_reboot
grub_refresh
grub_register_command_lockdown
grub_register_command_prio
grub_register_variable_hook
grub_snprintf
grub_strchr
grub_strcmp
grub_strcpy
grub_strdup
grub_strlen
grub_strncmp
grub_strndup
grub_strrchr
grub_strtoul
grub_strtoull
grub_strword
grub_term_highlight_color
grub_term_inputs
grub_term_inputs_disabled
grub_term_normal_color
grub_term_outputs
grub_term_outputs_disabled
grub_term_poll_usb
grub_tsc_rate
grub_unregister_command
grub_utf8_to_utf16_alloc
grub_verify_string
grub_vprintf
grub_vsnprintf
grub_xasprintf
grub_xputs
grub_xvasprintf
grub_zalloc
grub_mod_init
grub_mod_fini
grub_partition_map_list
grub_disk_read
grub_errno
grub_gpt_partition_map_iterate
grub_real_dprintf
grub_error
grub_list_remove
grub_list_push
grub_memcmp

## Search for configs on mounted USB

## Squashfs tool availability
/usr/local/bin/unsquashfs
/usr/local/bin/sqfstar

## Squashfs superblock
Found a valid SQUASHFS 4:0 superblock on /mnt/inspect-usb1/root/live/filesystem.squashfs.
Creation or last append time Thu Jun 18 17:55:50 2026
Filesystem size 7527146837 bytes (7350729.33 Kbytes / 7178.45 Mbytes)
Compression xz
Block size 131072
Filesystem is exportable via NFS
Inodes are compressed
Data is compressed
Uids/Gids (Id table) are compressed
Fragments are compressed
Always-use-fragments option is not specified
Xattrs are not stored
Duplicates are removed
Number of fragments 24753
Number of inodes 357727
Number of ids 15

## Squashfs key files
lrwxrwxrwx root/root                21 2026-02-22 14:59 squashfs-root/etc/os-release -> ../usr/lib/os-release
-rw-r--r-- root/root               193 2026-06-18 12:40 squashfs-root/etc/pam.d/system-auth
-rw-r--r-- root/root               283 2026-06-18 12:36 squashfs-root/etc/pam.d/system-session
-rw-r--r-- root/root                92 2026-06-18 12:36 squashfs-root/etc/security/limits.d/99-filedesc.conf
drwxr-xr-x sable/sable              87 2026-05-03 21:14 squashfs-root/home/sable/.config
drwxr-xr-x sable/sable              31 2026-05-02 13:20 squashfs-root/home/sable/.config/foot
-rw-r--r-- sable/sable              93 2026-05-02 13:20 squashfs-root/home/sable/.config/foot/foot.ini
drwxr-xr-x sable/sable              68 2026-06-18 16:10 squashfs-root/home/sable/.config/sway
-rwxr-xr-x sable/sable              68 2026-06-12 19:34 squashfs-root/home/sable/.config/sway/audio-init.sh
-rw-r--r-- sable/sable            5089 2026-06-18 16:10 squashfs-root/home/sable/.config/sway/config
drwxr-xr-x sable/sable              42 2026-05-02 13:20 squashfs-root/home/sable/.config/sway/wallpapers
-rw-r--r-- sable/sable          797686 2026-05-02 16:18 squashfs-root/home/sable/.config/sway/wallpapers/sable-wallpaper.png
drwxr-xr-x sable/sable              27 2026-05-03 21:13 squashfs-root/home/sable/.config/systemd
drwxr-xr-x sable/sable              43 2026-05-03 21:13 squashfs-root/home/sable/.config/systemd/user
drwxr-xr-x sable/sable              96 2026-05-03 21:13 squashfs-root/home/sable/.config/systemd/user/default.target.wants
lrwxrwxrwx sable/sable              44 2026-05-03 21:13 squashfs-root/home/sable/.config/systemd/user/default.target.wants/pipewire-pulse.service -> /usr/lib/systemd/user/pipewire-pulse.service
lrwxrwxrwx sable/sable              38 2026-05-03 21:13 squashfs-root/home/sable/.config/systemd/user/default.target.wants/pipewire.service -> /usr/lib/systemd/user/pipewire.service
lrwxrwxrwx sable/sable              41 2026-05-03 21:13 squashfs-root/home/sable/.config/systemd/user/default.target.wants/wireplumber.service -> /usr/lib/systemd/user/wireplumber.service
drwxr-xr-x sable/sable               3 2026-06-18 16:29 squashfs-root/home/sable/.config/waybar
drwxr-xr-x sable/sable              41 2026-05-03 21:14 squashfs-root/home/sable/.config/wireplumber
drwxr-xr-x sable/sable              45 2026-05-03 21:14 squashfs-root/home/sable/.config/wireplumber/wireplumber.conf.d
-rw-r--r-- sable/sable             240 2026-05-03 21:14 squashfs-root/home/sable/.config/wireplumber/wireplumber.conf.d/99-volume-default.conf
-rwxr-xr-x root/root            721408 2026-06-12 17:56 squashfs-root/usr/bin/sway
-rwxr-xr-x root/root            192096 2026-03-07 00:09 squashfs-root/usr/bin/swaybar
-rwxr-xr-x root/root             51280 2026-03-07 12:53 squashfs-root/usr/bin/swaybg
-rwxr-xr-x root/root             77696 2026-03-10 14:41 squashfs-root/usr/bin/swayidle
-rwsr-xr-x root/root            198784 2026-03-10 16:30 squashfs-root/usr/bin/swaylock
-rwxr-xr-x root/root             53840 2026-03-07 00:09 squashfs-root/usr/bin/swaymsg
-rwxr-xr-x root/root            116504 2026-03-07 00:09 squashfs-root/usr/bin/swaynag
-rwxr-xr-x root/root           3954112 2026-03-10 15:12 squashfs-root/usr/bin/waybar
drwxr-xr-x pepper/pepper          8095 2026-05-24 20:57 squashfs-root/usr/lib/firmware
-rw-r--r-- pepper/pepper           108 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.codespell.cfg
-rw-r--r-- pepper/pepper           321 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.editorconfig
drwxr-xr-x pepper/pepper           230 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git
-rw-r--r-- root/root               131 2026-05-24 21:01 squashfs-root/usr/lib/firmware/.git/FETCH_HEAD
-rw-r--r-- pepper/pepper            21 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.git/HEAD
-rw-r--r-- root/root                41 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/ORIG_HEAD
-rw-r--r-- pepper/pepper           302 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.git/config
-rw-r--r-- pepper/pepper            73 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/description
drwxr-xr-x pepper/pepper           405 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks
-rwxr-xr-x pepper/pepper           478 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks/applypatch-msg.sample
-rwxr-xr-x pepper/pepper           896 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks/commit-msg.sample
-rwxr-xr-x pepper/pepper          4726 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks/fsmonitor-watchman.sample
-rwxr-xr-x pepper/pepper           189 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks/post-update.sample
-rwxr-xr-x pepper/pepper           424 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks/pre-applypatch.sample
-rwxr-xr-x pepper/pepper          1649 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks/pre-commit.sample
-rwxr-xr-x pepper/pepper           416 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks/pre-merge-commit.sample
-rwxr-xr-x pepper/pepper          1374 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks/pre-push.sample
-rwxr-xr-x pepper/pepper          4898 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks/pre-rebase.sample
-rwxr-xr-x pepper/pepper           544 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks/pre-receive.sample
-rwxr-xr-x pepper/pepper          1492 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks/prepare-commit-msg.sample
-rwxr-xr-x pepper/pepper          2783 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks/push-to-checkout.sample
-rwxr-xr-x pepper/pepper          2308 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks/sendemail-validate.sample
-rwxr-xr-x pepper/pepper          3650 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks/update.sample
-rw-r--r-- root/root            476049 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/index
drwxr-xr-x pepper/pepper            30 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/info
-rw-r--r-- pepper/pepper           240 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/info/exclude
drwxr-xr-x pepper/pepper            51 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.git/logs
-rw-r--r-- pepper/pepper           375 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/logs/HEAD
drwxr-xr-x pepper/pepper            43 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.git/logs/refs
drwxr-xr-x pepper/pepper            27 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.git/logs/refs/heads
-rw-r--r-- pepper/pepper           375 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/logs/refs/heads/main
drwxr-xr-x pepper/pepper            29 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.git/logs/refs/remotes
drwxr-xr-x pepper/pepper            39 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/logs/refs/remotes/origin
-rw-r--r-- pepper/pepper           226 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.git/logs/refs/remotes/origin/HEAD
-rw-r--r-- root/root               149 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/logs/refs/remotes/origin/main
drwxr-xr-x pepper/pepper            51 2026-05-24 21:01 squashfs-root/usr/lib/firmware/.git/objects
drwxr-xr-x pepper/pepper             3 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/objects/info
drwxr-xr-x pepper/pepper           371 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/objects/pack
-r--r--r-- root/root             30360 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/objects/pack/pack-5a70bd8b5c92e632f7b1c53feaf1bfedfedcd234.idx
-r--r--r-- root/root          99296674 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/objects/pack/pack-5a70bd8b5c92e632f7b1c53feaf1bfedfedcd234.pack
-r--r--r-- root/root              4236 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/objects/pack/pack-5a70bd8b5c92e632f7b1c53feaf1bfedfedcd234.rev
-r--r--r-- pepper/pepper        124664 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.git/objects/pack/pack-db0234c88efed90eab37bcf79b04f57dfec678a4.idx
-r--r--r-- pepper/pepper     766777623 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.git/objects/pack/pack-db0234c88efed90eab37bcf79b04f57dfec678a4.pack
-r--r--r-- pepper/pepper         17708 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.git/objects/pack/pack-db0234c88efed90eab37bcf79b04f57dfec678a4.rev
-rw-r--r-- pepper/pepper           112 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.git/packed-refs
drwxr-xr-x pepper/pepper            55 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.git/refs
drwxr-xr-x pepper/pepper            27 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/refs/heads
-rw-r--r-- root/root                41 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/refs/heads/main
drwxr-xr-x pepper/pepper            29 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.git/refs/remotes
drwxr-xr-x pepper/pepper            39 2026-05-24 21:01 squashfs-root/usr/lib/firmware/.git/refs/remotes/origin
-rw-r--r-- pepper/pepper            30 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.git/refs/remotes/origin/HEAD
-rw-r--r-- root/root                41 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/refs/remotes/origin/main
drwxr-xr-x pepper/pepper            31 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/refs/tags
-rw-r--r-- root/root                41 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/refs/tags/20260519
-rw-r--r-- pepper/pepper            41 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/shallow
-rw-r--r-- pepper/pepper           100 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.gitignore
-rw-r--r-- pepper/pepper          1565 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.gitlab-ci.yml
-rw-r--r-- pepper/pepper           767 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.pre-commit-config.yaml
drwxr-xr-x pepper/pepper            34 2026-04-13 17:45 squashfs-root/usr/lib/firmware/3com
-rw-r--r-- pepper/pepper         44548 2026-04-13 17:45 squashfs-root/usr/lib/firmware/3com/typhoon.bin
-rw-r--r-- pepper/pepper         11358 2026-04-13 17:45 squashfs-root/usr/lib/firmware/Apache-2
-rw-r--r-- pepper/pepper           362 2026-04-13 17:45 squashfs-root/usr/lib/firmware/Dockerfile
-rw-r--r-- pepper/pepper         18092 2026-04-13 17:45 squashfs-root/usr/lib/firmware/GPL-2
-rw-r--r-- pepper/pepper         35068 2026-04-13 17:45 squashfs-root/usr/lib/firmware/GPL-3
drwxr-xr-x pepper/pepper            26 2026-04-13 17:45 squashfs-root/usr/lib/firmware/HP
drwxr-xr-x pepper/pepper            92 2026-05-24 20:57 squashfs-root/usr/lib/firmware/HP/ish
-rw-r--r-- pepper/pepper        862720 2026-04-13 17:45 squashfs-root/usr/lib/firmware/HP/ish/ish_lnlm_12128606_f9751b71.bin
-rw-r--r-- root/root            883200 2026-05-24 20:57 squashfs-root/usr/lib/firmware/HP/ish/ish_ptl_12128606_581.7779.0.bin
drwxr-xr-x pepper/pepper            26 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LENOVO
drwxr-xr-x pepper/pepper           206 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LENOVO/ish
-rw-r--r-- pepper/pepper        637440 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LENOVO/ish/ish_lnlm_lenovo_X1_2025_5.8.4.7720.bin
-rw-r--r-- pepper/pepper        875008 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LENOVO/ish/ish_lnlm_lenovo_X9-14_2025_5.8.36.09092.bin
-rw-r--r-- pepper/pepper        825856 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LENOVO/ish/ish_lnlm_lenovo_x9-15_2025_5.8.0.7720.bin
-rw-r--r-- pepper/pepper        858624 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LENOVO/ish/ish_ptl_lenovo_X1_2026_5.8.1.7782.bin
-rw-r--r-- pepper/pepper          1071 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.Abilis
-rw-r--r-- pepper/pepper          1306 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.HP
-rw-r--r-- pepper/pepper          2041 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.IntcSST2
-rw-r--r-- pepper/pepper          1152 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.Marvell
-rw-r--r-- pepper/pepper          1131 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.NXP
-rw-r--r-- pepper/pepper          3624 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.Netronome
-rw-r--r-- pepper/pepper          1777 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.OLPC
-rw-r--r-- pepper/pepper         48362 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.adsp_sst
-rw-r--r-- pepper/pepper           341 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.advansys
-rw-r--r-- pepper/pepper          3539 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.agere
-rw-r--r-- pepper/pepper           572 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.alacritech
-rw-r--r-- pepper/pepper          1946 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.atheros_firmware
-rw-r--r-- pepper/pepper           292 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.bnx2
-rw-r--r-- pepper/pepper           336 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.bnx2x
-rw-r--r-- pepper/pepper          4178 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.broadcom_bcm43xx
-rw-r--r-- pepper/pepper          2494 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.ca0132
-rw-r--r-- pepper/pepper          2870 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.cadence
-rw-r--r-- pepper/pepper          3711 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.cavium
-rw-r--r-- pepper/pepper          4000 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.cavium_liquidio
-rw-r--r-- pepper/pepper          1485 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.chelsio_firmware
-rw-r--r-- pepper/pepper          2055 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.cnm
-rw-r--r-- pepper/pepper          1954 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.cw1200
-rw-r--r-- pepper/pepper           509 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.cw1200-sdd
-rw-r--r-- pepper/pepper           213 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.cxgb3
-rw-r--r-- pepper/pepper          8914 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.cypress
-rw-r--r-- pepper/pepper           245 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.dabusb
-rw-r--r-- pepper/pepper          1492 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.e100
-rw-r--r-- pepper/pepper           798 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.emi26
-rw-r--r-- pepper/pepper           738 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.ene_firmware
-rw-r--r-- pepper/pepper          1892 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.fw_sst_0f28
-rw-r--r-- pepper/pepper         20217 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.go7007
-rw-r--r-- pepper/pepper          2040 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.ibt_firmware
-rw-r--r-- pepper/pepper           268 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.inside-secure
-rw-r--r-- pepper/pepper           851 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.it913x
-rw-r--r-- pepper/pepper          2046 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.iwlwifi_firmware
-rw-r--r-- pepper/pepper          1599 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.kaweth
-rw-r--r-- pepper/pepper           802 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.keyspan
-rw-r--r-- pepper/pepper          2527 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.lenovo
-rw-r--r-- pepper/pepper          1609 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.linaro
-rw-r--r-- pepper/pepper          9690 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.mali_csffw
-rw-r--r-- pepper/pepper           561 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.mediatek
-rw-r--r-- pepper/pepper          2336 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.microchip
-rw-r--r-- pepper/pepper           892 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.moxa
-rw-r--r-- pepper/pepper           151 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.multitech
-rw-r--r-- pepper/pepper          1450 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.myri10ge_firmware
-rw-r--r-- pepper/pepper          6212 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.nvidia
-rw-r--r-- pepper/pepper          9409 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.open-ath9k-htc-firmware
-rw-r--r-- pepper/pepper          1873 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.phanfw
-rw-r--r-- pepper/pepper          1878 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.qat_firmware
-rw-r--r-- pepper/pepper          1387 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.qla1280
-rw-r--r-- pepper/pepper          1843 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.qla2xxx
-rw-r--r-- pepper/pepper          1542 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.r8a779g_pcie_phy
-rw-r--r-- pepper/pepper          1451 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.r8a779x_usb3
-rw-r--r-- pepper/pepper          2103 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.ralink-firmware.txt
-rw-r--r-- pepper/pepper          2100 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.ralink_a_mediatek_company_firmware
-rw-r--r-- pepper/pepper          2106 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.rockchip
-rw-r--r-- pepper/pepper          2115 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.rtlwifi_firmware.txt
-rw-r--r-- pepper/pepper           458 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.sensoray
-rw-r--r-- pepper/pepper          1449 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.siano
-rw-r--r-- pepper/pepper          2918 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.ti-connectivity
-rw-r--r-- pepper/pepper          2913 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.ti-keystone
-rw-r--r-- pepper/pepper          2145 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.ti-tspa
-rw-r--r-- pepper/pepper           257 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.tigon
-rw-r--r-- pepper/pepper          1790 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.typhoon
-rw-r--r-- pepper/pepper           437 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.ueagle
-rw-r--r-- pepper/pepper          2052 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.ueagle-atm4-firmware
-rw-r--r-- pepper/pepper          1256 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.via_vt6656
-rw-r--r-- pepper/pepper          2903 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.wl1251
-rw-r--r-- pepper/pepper          1187 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.xc4000
-rw-r--r-- pepper/pepper          1179 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.xc5000
-rw-r--r-- pepper/pepper          1227 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.xc5000c
-rw-r--r-- pepper/pepper            96 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE
-rw-r--r-- pepper/pepper           558 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.Lontium
-rw-r--r-- pepper/pepper          2708 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.QualcommAtheros_ar3k
-rw-r--r-- pepper/pepper          2713 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.QualcommAtheros_ath10k
-rw-r--r-- pepper/pepper           620 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.aeonsemi
-rw-r--r-- pepper/pepper           556 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.airoha
-rw-r--r-- pepper/pepper          3760 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.amd-sev
-rw-r--r-- pepper/pepper          3758 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.amd-ucode
-rw-r--r-- pepper/pepper          2938 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.amd_pmf
-rw-r--r-- pepper/pepper          2938 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.amdgpu
-rw-r--r-- pepper/pepper          8462 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.amdisp
-rw-r--r-- pepper/pepper          1186 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.amdnpu
-rw-r--r-- pepper/pepper           752 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.amlogic
-rw-r--r-- pepper/pepper           756 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.amlogic_vdec
-rw-r--r-- pepper/pepper          2644 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.amphion_vpu
-rw-r--r-- pepper/pepper          2103 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.atmel
-rw-r--r-- pepper/pepper           814 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.bfa
-rw-r--r-- pepper/pepper          1505 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.bmi260
-rw-r--r-- pepper/pepper         26746 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.cirrus
-rw-r--r-- pepper/pepper           458 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.conexant
-rw-r--r-- pepper/pepper          6819 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.dell
-rw-r--r-- pepper/pepper          1039 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.dib0700
-rw-r--r-- pepper/pepper           457 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.drxk
-rw-r--r-- pepper/pepper          1905 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.hfi1_firmware
-rw-r--r-- pepper/pepper          2080 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.i915
-rw-r--r-- pepper/pepper          1347 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.ib_qib
-rw-r--r-- pepper/pepper          2041 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.ice
-rw-r--r-- pepper/pepper          2082 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.ice_enhanced
-rw-r--r-- pepper/pepper          1859 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.intel
-rw-r--r-- pepper/pepper          2041 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.intel_vpu
-rw-r--r-- pepper/pepper          1870 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.ipu3_firmware
-rw-r--r-- pepper/pepper          2014 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.ivsc
-rw-r--r-- pepper/pepper          1890 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.ixp4xx
-rw-r--r-- pepper/pepper          1605 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.mellanox
-rw-r--r-- pepper/pepper          1097 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.mga
-rw-r--r-- pepper/pepper          3755 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.montage
-rw-r--r-- pepper/pepper          5196 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.nxp
-rw-r--r-- pepper/pepper          7259 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.nxp_mc_firmware
-rw-r--r-- pepper/pepper          2190 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.powervr
-rw-r--r-- pepper/pepper         13962 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.qcom
-rw-r--r-- pepper/pepper         14417 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.qcom-2
-rw-r--r-- pepper/pepper          1540 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.qcom_yamato
-rw-r--r-- pepper/pepper           288 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.qed
-rw-r--r-- pepper/pepper           219 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.r8169
-rw-r--r-- pepper/pepper          2943 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.radeon
-rw-r--r-- pepper/pepper           495 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.rp2
-rw-r--r-- pepper/pepper           271 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.rsi
-rw-r--r-- pepper/pepper           214 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.rt1320
-rw-r--r-- pepper/pepper           475 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.s5p-mfc
-rw-r--r-- pepper/pepper          2602 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.sdma_firmware
-rw-r--r-- pepper/pepper           201 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.tehuti
-rw-r--r-- pepper/pepper           483 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.tlg2300
-rw-r--r-- pepper/pepper           281 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.vxge
-rw-r--r-- pepper/pepper          2041 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.xe
drwxr-xr-x root/root               108 2026-05-24 20:57 squashfs-root/usr/lib/firmware/Lontium
-rw-r--r-- root/root             30735 2026-05-24 20:57 squashfs-root/usr/lib/firmware/Lontium/lt7911exc_fw.bin
-rw-r--r-- root/root            145976 2026-05-24 20:57 squashfs-root/usr/lib/firmware/Lontium/lt8713sx_fw.bin
-rw-r--r-- root/root             36090 2026-05-24 20:57 squashfs-root/usr/lib/firmware/Lontium/lt9611c_fw.bin
-rw-r--r-- root/root             17932 2026-05-24 20:57 squashfs-root/usr/lib/firmware/Lontium/lt9611uxc_fw.bin
-rw-r--r-- pepper/pepper          1096 2026-04-13 17:45 squashfs-root/usr/lib/firmware/MIT
-rw-r--r-- pepper/pepper          1368 2026-04-13 17:45 squashfs-root/usr/lib/firmware/Makefile
-rw-r--r-- pepper/pepper          2704 2026-04-13 17:45 squashfs-root/usr/lib/firmware/README.md
-rw-r--r-- root/root            442668 2026-05-24 20:57 squashfs-root/usr/lib/firmware/WHENCE
drwxr-xr-x pepper/pepper            45 2026-04-13 17:45 squashfs-root/usr/lib/firmware/acenic
-rw-r--r-- pepper/pepper         73116 2026-04-13 17:45 squashfs-root/usr/lib/firmware/acenic/tg1.bin
-rw-r--r-- pepper/pepper         77452 2026-04-13 17:45 squashfs-root/usr/lib/firmware/acenic/tg2.bin
drwxr-xr-x pepper/pepper            61 2026-04-13 17:45 squashfs-root/usr/lib/firmware/adaptec
-rw-r--r-- pepper/pepper           832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/adaptec/starfire_rx.bin
-rw-r--r-- pepper/pepper           832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/adaptec/starfire_tx.bin
drwxr-xr-x pepper/pepper            86 2026-04-13 17:45 squashfs-root/usr/lib/firmware/advansys
-rw-r--r-- pepper/pepper          5026 2026-04-13 17:45 squashfs-root/usr/lib/firmware/advansys/3550.bin
-rw-r--r-- pepper/pepper          5340 2026-04-13 17:45 squashfs-root/usr/lib/firmware/advansys/38C0800.bin
-rw-r--r-- pepper/pepper          6334 2026-04-13 17:45 squashfs-root/usr/lib/firmware/advansys/38C1600.bin
-rw-r--r-- pepper/pepper          2308 2026-04-13 17:45 squashfs-root/usr/lib/firmware/advansys/mcode.bin
drwxr-xr-x pepper/pepper            37 2026-04-13 17:45 squashfs-root/usr/lib/firmware/aeonsemi
-rw-r--r-- pepper/pepper        290272 2026-04-13 17:45 squashfs-root/usr/lib/firmware/aeonsemi/as21x1x_fw.bin
-rw-r--r-- pepper/pepper         50698 2026-04-13 17:45 squashfs-root/usr/lib/firmware/agere_ap_fw.bin
-rw-r--r-- pepper/pepper         65046 2026-04-13 17:45 squashfs-root/usr/lib/firmware/agere_sta_fw.bin
drwxr-xr-x pepper/pepper           252 2026-04-13 17:45 squashfs-root/usr/lib/firmware/airoha
-rw-r--r-- pepper/pepper        131072 2026-04-13 17:45 squashfs-root/usr/lib/firmware/airoha/EthMD32.DSP.bin
-rw-r--r-- pepper/pepper         16384 2026-04-13 17:45 squashfs-root/usr/lib/firmware/airoha/EthMD32.dm.bin
-rw-r--r-- pepper/pepper          3260 2026-04-13 17:45 squashfs-root/usr/lib/firmware/airoha/an7583_npu_data.bin
-rw-r--r-- pepper/pepper        106032 2026-04-13 17:45 squashfs-root/usr/lib/firmware/airoha/an7583_npu_rv32.bin
drwxr-xr-x pepper/pepper            68 2026-04-13 17:45 squashfs-root/usr/lib/firmware/airoha/an8811hb
-rw-r--r-- pepper/pepper         32768 2026-04-13 17:45 squashfs-root/usr/lib/firmware/airoha/an8811hb/EthMD32_CRC.DM.bin
-rw-r--r-- pepper/pepper        131072 2026-04-13 17:45 squashfs-root/usr/lib/firmware/airoha/an8811hb/EthMD32_CRC.DSP.bin
-rw-r--r-- pepper/pepper          3084 2026-04-13 17:45 squashfs-root/usr/lib/firmware/airoha/en7581_MT7996_npu_data.bin
-rw-r--r-- pepper/pepper        122336 2026-04-13 17:45 squashfs-root/usr/lib/firmware/airoha/en7581_MT7996_npu_rv32.bin
-rw-r--r-- pepper/pepper          3100 2026-04-13 17:45 squashfs-root/usr/lib/firmware/airoha/en7581_npu_data.bin
-rw-r--r-- pepper/pepper        120272 2026-04-13 17:45 squashfs-root/usr/lib/firmware/airoha/en7581_npu_rv32.bin
drwxr-xr-x pepper/pepper           231 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd
-rw-r--r-- pepper/pepper         33728 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd/amd_sev_fam17h_model0xh.sbin
-rw-r--r-- pepper/pepper         45504 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd/amd_sev_fam17h_model3xh.sbin
-rw-r--r-- pepper/pepper         97408 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd/amd_sev_fam19h_model0xh.sbin
-rw-r--r-- pepper/pepper        105536 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd/amd_sev_fam19h_model1xh.sbin
-rw-r--r-- pepper/pepper        105536 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd/amd_sev_fam19h_modelaxh.sbin
-rw-r--r-- pepper/pepper        233984 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd/amd_sev_fam1ah_model0xh.sbin
drwxr-xr-x pepper/pepper           423 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amd-ucode
-rw-r--r-- root/root              7580 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amd-ucode/README
-rw-r--r-- pepper/pepper         12684 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd-ucode/microcode_amd.bin
-rw-r--r-- pepper/pepper           490 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd-ucode/microcode_amd.bin.asc
-rw-r--r-- pepper/pepper          7876 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd-ucode/microcode_amd_fam15h.bin
-rw-r--r-- pepper/pepper           473 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd-ucode/microcode_amd_fam15h.bin.asc
-rw-r--r-- pepper/pepper          3510 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd-ucode/microcode_amd_fam16h.bin
-rw-r--r-- pepper/pepper           473 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd-ucode/microcode_amd_fam16h.bin.asc
-rw-r--r-- pepper/pepper         22596 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd-ucode/microcode_amd_fam17h.bin
-rw-r--r-- pepper/pepper           488 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd-ucode/microcode_amd_fam17h.bin.asc
-rw-r--r-- pepper/pepper        128644 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd-ucode/microcode_amd_fam19h.bin
-rw-r--r-- pepper/pepper           488 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd-ucode/microcode_amd_fam19h.bin.asc
-rw-r--r-- root/root            129556 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amd-ucode/microcode_amd_fam1ah.bin
-rw-r--r-- root/root               488 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amd-ucode/microcode_amd_fam1ah.bin.asc
drwxr-xr-x pepper/pepper         16821 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu
-rw-r--r-- pepper/pepper           732 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/aldebaran_ip_discovery.bin
-rw-r--r-- root/root            268736 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/aldebaran_mec.bin
-rw-r--r-- root/root            268736 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/aldebaran_mec2.bin
-rw-r--r-- pepper/pepper         46060 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/aldebaran_rlc.bin
-rw-r--r-- pepper/pepper         34304 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/aldebaran_sdma.bin
-rw-r--r-- root/root            268736 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/aldebaran_sjt_mec.bin
-rw-r--r-- root/root            268736 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/aldebaran_sjt_mec2.bin
-rw-r--r-- root/root            242688 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/aldebaran_smc.bin
-rw-r--r-- root/root            446208 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/aldebaran_sos.bin
-rw-r--r-- pepper/pepper        140288 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/aldebaran_ta.bin
-rw-r--r-- pepper/pepper        422656 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/aldebaran_vcn.bin
-rw-r--r-- pepper/pepper        168448 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/arcturus_asd.bin
-rw-r--r-- pepper/pepper           316 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/arcturus_gpu_info.bin
-rw-r--r-- pepper/pepper           936 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/arcturus_ip_discovery.bin
-rw-r--r-- pepper/pepper        268576 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/arcturus_mec.bin
-rw-r--r-- pepper/pepper        268576 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/arcturus_mec2.bin
-rw-r--r-- pepper/pepper         48044 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/arcturus_rlc.bin
-rw-r--r-- pepper/pepper         17664 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/arcturus_sdma.bin
-rw-r--r-- pepper/pepper        270698 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/arcturus_smc.bin
-rw-r--r-- pepper/pepper        199248 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/arcturus_sos.bin
-rw-r--r-- pepper/pepper        127744 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/arcturus_ta.bin
-rw-r--r-- pepper/pepper        420736 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/arcturus_vcn.bin
-rw-r--r-- pepper/pepper         61932 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/banks_k_2_smc.bin
-rw-r--r-- root/root            263296 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/beige_goby_ce.bin
-rw-r--r-- pepper/pepper        114036 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/beige_goby_dmcub.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/beige_goby_me.bin
-rw-r--r-- root/root            268160 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/beige_goby_mec.bin
-rw-r--r-- root/root            268160 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/beige_goby_mec2.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/beige_goby_pfp.bin
-rw-r--r-- pepper/pepper        130472 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/beige_goby_rlc.bin
-rw-r--r-- pepper/pepper         34048 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/beige_goby_sdma.bin
-rw-r--r-- pepper/pepper        244934 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/beige_goby_smc.bin
-rw-r--r-- pepper/pepper        205984 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/beige_goby_sos.bin
-rw-r--r-- root/root            259328 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/beige_goby_ta.bin
-rw-r--r-- root/root            580240 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/beige_goby_vcn.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/bonaire_ce.bin
-rw-r--r-- pepper/pepper        130796 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/bonaire_k_smc.bin
-rw-r--r-- pepper/pepper         32336 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/bonaire_mc.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/bonaire_me.bin
-rw-r--r-- pepper/pepper         17024 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/bonaire_mec.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/bonaire_pfp.bin
-rw-r--r-- pepper/pepper          8448 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/bonaire_rlc.bin
-rw-r--r-- pepper/pepper          4456 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/bonaire_sdma.bin
-rw-r--r-- pepper/pepper          4456 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/bonaire_sdma1.bin
-rw-r--r-- pepper/pepper        130796 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/bonaire_smc.bin
-rw-r--r-- pepper/pepper        232752 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/bonaire_uvd.bin
-rw-r--r-- pepper/pepper        101072 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/bonaire_vce.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/carrizo_ce.bin
-rw-r--r-- pepper/pepper         17024 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/carrizo_me.bin
-rw-r--r-- pepper/pepper        262784 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/carrizo_mec.bin
-rw-r--r-- pepper/pepper        262784 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/carrizo_mec2.bin
-rw-r--r-- pepper/pepper         17024 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/carrizo_pfp.bin
-rw-r--r-- pepper/pepper         18836 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/carrizo_rlc.bin
-rw-r--r-- pepper/pepper         10624 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/carrizo_sdma.bin
-rw-r--r-- pepper/pepper         10624 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/carrizo_sdma1.bin
-rw-r--r-- pepper/pepper        271712 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/carrizo_uvd.bin
-rw-r--r-- pepper/pepper        175840 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/carrizo_vce.bin
-rw-r--r-- pepper/pepper        263296 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/cyan_skillfish2_ce.bin
-rw-r--r-- pepper/pepper        263424 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/cyan_skillfish2_me.bin
-rw-r--r-- pepper/pepper        268592 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/cyan_skillfish2_mec.bin
-rw-r--r-- pepper/pepper        268592 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/cyan_skillfish2_mec2.bin
-rw-r--r-- pepper/pepper        263424 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/cyan_skillfish2_pfp.bin
-rw-r--r-- pepper/pepper         25344 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/cyan_skillfish2_rlc.bin
-rw-r--r-- pepper/pepper         33792 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/cyan_skillfish2_sdma.bin
-rw-r--r-- pepper/pepper         33792 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/cyan_skillfish2_sdma1.bin
-rw-r--r-- root/root            350752 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/dcn_3_1_4_dmcub.bin
-rw-r--r-- pepper/pepper        242208 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/dcn_3_1_5_dmcub.bin
-rw-r--r-- pepper/pepper        215568 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/dcn_3_1_6_dmcub.bin
-rw-r--r-- root/root            284432 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/dcn_3_2_0_dmcub.bin
-rw-r--r-- root/root            232480 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/dcn_3_2_1_dmcub.bin
-rw-r--r-- root/root            522016 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/dcn_3_5_1_dmcub.bin
-rw-r--r-- root/root            522144 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/dcn_3_5_dmcub.bin
-rw-r--r-- root/root            535456 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/dcn_3_6_dmcub.bin
-rw-r--r-- root/root            368032 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/dcn_4_0_1_dmcub.bin
-rw-r--r-- root/root            263296 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/dimgrey_cavefish_ce.bin
-rw-r--r-- pepper/pepper        114036 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/dimgrey_cavefish_dmcub.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/dimgrey_cavefish_me.bin
-rw-r--r-- root/root            268160 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/dimgrey_cavefish_mec.bin
-rw-r--r-- root/root            268160 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/dimgrey_cavefish_mec2.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/dimgrey_cavefish_pfp.bin
-rw-r--r-- pepper/pepper        137232 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/dimgrey_cavefish_rlc.bin
-rw-r--r-- pepper/pepper         34048 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/dimgrey_cavefish_sdma.bin
-rw-r--r-- pepper/pepper        244902 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/dimgrey_cavefish_smc.bin
-rw-r--r-- pepper/pepper        210416 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/dimgrey_cavefish_sos.bin
-rw-r--r-- root/root            259328 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/dimgrey_cavefish_ta.bin
-rw-r--r-- root/root            580240 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/dimgrey_cavefish_vcn.bin
-rw-r--r-- pepper/pepper          8852 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/fiji_ce.bin
-rw-r--r-- pepper/pepper         16028 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/fiji_mc.bin
-rw-r--r-- pepper/pepper         17044 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/fiji_me.bin
-rw-r--r-- pepper/pepper        262824 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/fiji_mec.bin
-rw-r--r-- pepper/pepper        262824 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/fiji_mec2.bin
-rw-r--r-- pepper/pepper         17044 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/fiji_pfp.bin
-rw-r--r-- pepper/pepper         16636 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/fiji_rlc.bin
-rw-r--r-- pepper/pepper         10644 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/fiji_sdma.bin
-rw-r--r-- pepper/pepper         10644 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/fiji_sdma1.bin
-rw-r--r-- pepper/pepper        129604 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/fiji_smc.bin
-rw-r--r-- pepper/pepper        266768 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/fiji_uvd.bin
-rw-r--r-- pepper/pepper        161024 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/fiji_vce.bin
-rw-r--r-- root/root            263296 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_10_3_6_ce.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_10_3_6_me.bin
-rw-r--r-- root/root            268592 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_10_3_6_mec.bin
-rw-r--r-- root/root            268592 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_10_3_6_mec2.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_10_3_6_pfp.bin
-rw-r--r-- pepper/pepper        177104 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_10_3_6_rlc.bin
-rw-r--r-- pepper/pepper        263296 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_10_3_7_ce.bin
-rw-r--r-- pepper/pepper        263424 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_10_3_7_me.bin
-rw-r--r-- pepper/pepper        268160 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_10_3_7_mec.bin
-rw-r--r-- pepper/pepper        268160 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_10_3_7_mec2.bin
-rw-r--r-- pepper/pepper        263424 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_10_3_7_pfp.bin
-rw-r--r-- pepper/pepper        177088 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_10_3_7_rlc.bin
-rw-r--r-- pepper/pepper        132352 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_0_imu.bin
-rw-r--r-- pepper/pepper        132352 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_0_imu_kicker.bin
-rw-r--r-- pepper/pepper        315120 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_0_me.bin
-rw-r--r-- pepper/pepper        406528 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_0_mec.bin
-rw-r--r-- pepper/pepper        286336 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_0_mes.bin
-rw-r--r-- root/root            220480 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_0_mes1.bin
-rw-r--r-- root/root            260624 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_0_mes_2.bin
-rw-r--r-- pepper/pepper        232096 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_0_pfp.bin
-rw-r--r-- pepper/pepper        185376 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_0_rlc.bin
-rw-r--r-- pepper/pepper        185248 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_0_rlc_1.bin
-rw-r--r-- pepper/pepper        185376 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_0_rlc_kicker.bin
-rw-r--r-- pepper/pepper        132352 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_1_imu.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_1_me.bin
-rw-r--r-- root/root            268160 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_1_mec.bin
-rw-r--r-- pepper/pepper        287712 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_1_mes.bin
-rw-r--r-- root/root            235312 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_1_mes1.bin
-rw-r--r-- root/root            263616 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_1_mes_2.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_1_pfp.bin
-rw-r--r-- root/root            157040 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_1_rlc.bin
-rw-r--r-- pepper/pepper        132352 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_2_imu.bin
-rw-r--r-- pepper/pepper        315120 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_2_me.bin
-rw-r--r-- pepper/pepper        406528 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_2_mec.bin
-rw-r--r-- pepper/pepper        286336 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_2_mes.bin
-rw-r--r-- pepper/pepper        218560 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_2_mes1.bin
-rw-r--r-- root/root            260624 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_2_mes_2.bin
-rw-r--r-- pepper/pepper        232112 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_2_pfp.bin
-rw-r--r-- pepper/pepper        178848 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_2_rlc.bin
-rw-r--r-- pepper/pepper        132352 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_3_imu.bin
-rw-r--r-- pepper/pepper        315136 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_3_me.bin
-rw-r--r-- pepper/pepper        406528 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_3_mec.bin
-rw-r--r-- pepper/pepper        220544 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_3_mes1.bin
-rw-r--r-- root/root            260688 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_3_mes_2.bin
-rw-r--r-- pepper/pepper        232112 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_3_pfp.bin
-rw-r--r-- root/root            179104 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_3_rlc.bin
-rw-r--r-- pepper/pepper        132352 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_4_imu.bin
-rw-r--r-- pepper/pepper        263424 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_4_me.bin
-rw-r--r-- pepper/pepper        268160 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_4_mec.bin
-rw-r--r-- pepper/pepper        287712 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_4_mes.bin
-rw-r--r-- pepper/pepper        234640 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_4_mes1.bin
-rw-r--r-- root/root            257760 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_4_mes_2.bin
-rw-r--r-- pepper/pepper        263424 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_4_pfp.bin
-rw-r--r-- pepper/pepper        159152 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_4_rlc.bin
-rw-r--r-- pepper/pepper        132352 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_0_imu.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_0_me.bin
-rw-r--r-- root/root            268160 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_0_mec.bin
-rw-r--r-- pepper/pepper        238128 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_0_mes1.bin
-rw-r--r-- root/root            258208 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_0_mes_2.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_0_pfp.bin
-rw-r--r-- pepper/pepper        166528 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_0_rlc.bin
-rw-r--r-- pepper/pepper        132352 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_1_imu.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_1_me.bin
-rw-r--r-- root/root            268160 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_1_mec.bin
-rw-r--r-- pepper/pepper        238320 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_1_mes1.bin
-rw-r--r-- root/root            258496 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_1_mes_2.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_1_pfp.bin
-rw-r--r-- pepper/pepper        161040 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_1_rlc.bin
-rw-r--r-- pepper/pepper        132352 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_2_imu.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_2_me.bin
-rw-r--r-- root/root            268160 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_2_mec.bin
-rw-r--r-- pepper/pepper        237776 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_2_mes1.bin
-rw-r--r-- root/root            260560 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_2_mes_2.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_2_pfp.bin
-rw-r--r-- pepper/pepper        162096 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_2_rlc.bin
-rw-r--r-- pepper/pepper        132352 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_3_imu.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_3_me.bin
-rw-r--r-- root/root            268160 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_3_mec.bin
-rw-r--r-- pepper/pepper        237776 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_3_mes1.bin
-rw-r--r-- root/root            260560 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_3_mes_2.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_3_pfp.bin
-rw-r--r-- pepper/pepper        162064 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_3_rlc.bin
-rw-r--r-- pepper/pepper        132352 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_0_imu.bin
-rw-r--r-- root/root            459840 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_0_me.bin
-rw-r--r-- root/root            455648 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_0_mec.bin
-rw-r--r-- pepper/pepper        636048 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_0_mes.bin
-rw-r--r-- pepper/pepper        609840 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_0_mes1.bin
-rw-r--r-- root/root            353536 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_0_pfp.bin
-rw-r--r-- pepper/pepper        150704 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_0_rlc.bin
-rw-r--r-- pepper/pepper          2048 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_0_toc.bin
-rw-r--r-- root/root            727680 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_0_uni_mes.bin
-rw-r--r-- pepper/pepper        132352 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_1_imu.bin
-rw-r--r-- pepper/pepper        132352 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_1_imu_kicker.bin
-rw-r--r-- root/root            459840 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_1_me.bin
-rw-r--r-- root/root            455648 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_1_mec.bin
-rw-r--r-- pepper/pepper        643536 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_1_mes.bin
-rw-r--r-- pepper/pepper        611920 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_1_mes1.bin
-rw-r--r-- root/root            353536 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_1_pfp.bin
-rw-r--r-- pepper/pepper        150848 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_1_rlc.bin
-rw-r--r-- pepper/pepper        150848 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_1_rlc_kicker.bin
-rw-r--r-- pepper/pepper          2048 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_1_toc.bin
-rw-r--r-- root/root            727680 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_1_uni_mes.bin
-rw-r--r-- root/root            268736 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_9_4_3_mec.bin
-rw-r--r-- root/root             38708 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_9_4_3_rlc.bin
-rw-r--r-- root/root            268736 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_9_4_3_sjt_mec.bin
-rw-r--r-- pepper/pepper        268736 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_9_4_4_mec.bin
-rw-r--r-- pepper/pepper         43388 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_9_4_4_rlc.bin
-rw-r--r-- pepper/pepper        268736 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_9_4_4_sjt_mec.bin
-rw-r--r-- root/root            268736 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_9_5_0_mec.bin
-rw-r--r-- pepper/pepper         38700 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_9_5_0_rlc.bin
-rw-r--r-- root/root            268736 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_9_5_0_sjt_mec.bin
-rw-r--r-- root/root                 0 2026-03-06 11:35 squashfs-root/usr/lib/firmware/amdgpu/gfx1201_ce.bin
-rw-r--r-- root/root                 0 2026-03-06 11:35 squashfs-root/usr/lib/firmware/amdgpu/gfx1201_me.bin
-rw-r--r-- root/root                 0 2026-03-06 11:35 squashfs-root/usr/lib/firmware/amdgpu/gfx1201_mec.bin

## Squashfs installer/config candidates
-rwxr-xr-x root/root              1174 2026-02-21 11:47 squashfs-root/etc/grub.d/30_uefi-firmware
-rw-r--r-- root/root               193 2026-06-18 12:40 squashfs-root/etc/pam.d/system-auth
-rw-r--r-- root/root               283 2026-06-18 12:36 squashfs-root/etc/pam.d/system-session
-rw-r--r-- root/root                92 2026-06-18 12:36 squashfs-root/etc/security/limits.d/99-filedesc.conf
lrwxrwxrwx root/root                49 2026-03-06 14:56 squashfs-root/etc/ssl/certs/01419da9.0 -> Microsoft_ECC_Root_Certificate_Authority_2017.pem
lrwxrwxrwx root/root                49 2026-03-06 14:56 squashfs-root/etc/ssl/certs/8d89cda1.0 -> Microsoft_ECC_Root_Certificate_Authority_2017.pem
lrwxrwxrwx root/root                49 2026-03-06 14:56 squashfs-root/etc/ssl/certs/9591a472.0 -> Microsoft_RSA_Root_Certificate_Authority_2017.pem
-r--r--r-- root/root               972 2026-03-06 14:56 squashfs-root/etc/ssl/certs/Microsoft_ECC_Root_Certificate_Authority_2017.pem
-r--r--r-- root/root              2122 2026-03-06 14:56 squashfs-root/etc/ssl/certs/Microsoft_RSA_Root_Certificate_Authority_2017.pem
lrwxrwxrwx root/root                49 2026-03-06 14:56 squashfs-root/etc/ssl/certs/bf53fb88.0 -> Microsoft_RSA_Root_Certificate_Authority_2017.pem
drwxr-xr-x root/root                52 2026-03-10 15:12 squashfs-root/etc/xdg/waybar
-rw-r--r-- root/root              1263 2026-06-18 17:50 squashfs-root/etc/xdg/waybar/config.jsonc
-rw-r--r-- root/root              5319 2024-09-13 03:51 squashfs-root/etc/xdg/waybar/style.css
drwxr-xr-x sable/sable               3 2026-06-18 16:29 squashfs-root/home/sable/.config/waybar
-rwxr-xr-x pepper/pepper        397168 2026-04-30 11:38 squashfs-root/opt/firefox/libsoftokn3.so
-rw-r--r-- root/root              8973 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/Base/ghidra_scripts/FindRunsOfPointersScript.java
-rw-r--r-- root/root              2151 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/Base/ghidra_scripts/GenerateLotsOfProgramsScript.java
-rw-r--r-- root/root              2957 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/FileFormats/ghidra_scripts/SplitExtensibleFirmwareInterfaceScript.java
drwxr-xr-x root/root               126 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/MicrosoftCodeAnalyzer
-rw-r--r-- root/root               320 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/MicrosoftCodeAnalyzer/LICENSE.txt
-rw-r--r-- root/root                 0 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/MicrosoftCodeAnalyzer/Module.manifest
-rw-r--r-- root/root               143 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/MicrosoftCodeAnalyzer/README.html
-rw-r--r-- root/root                24 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/MicrosoftCodeAnalyzer/README.md
drwxr-xr-x root/root               112 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/MicrosoftCodeAnalyzer/ghidra_scripts
-rw-r--r-- root/root             23921 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/MicrosoftCodeAnalyzer/ghidra_scripts/FixUpRttiAnalysisScript.java
-rw-r--r-- root/root              1880 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/MicrosoftCodeAnalyzer/ghidra_scripts/IdPeRttiScript.java
-rw-r--r-- root/root              1205 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/MicrosoftCodeAnalyzer/ghidra_scripts/RunRttiAnalyzerScript.java
drwxr-xr-x root/root                85 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/MicrosoftCodeAnalyzer/lib
-rw-r--r-- root/root            105581 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/MicrosoftCodeAnalyzer/lib/MicrosoftCodeAnalyzer-src.zip
-rw-r--r-- root/root            137761 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/MicrosoftCodeAnalyzer/lib/MicrosoftCodeAnalyzer.jar
drwxr-xr-x root/root               104 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/MicrosoftDemangler
-rw-r--r-- root/root               320 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/MicrosoftDemangler/LICENSE.txt
-rw-r--r-- root/root                 0 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/MicrosoftDemangler/Module.manifest
-rw-r--r-- root/root               137 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/MicrosoftDemangler/README.html
-rw-r--r-- root/root                21 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/MicrosoftDemangler/README.md
drwxr-xr-x root/root                79 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/MicrosoftDemangler/lib
-rw-r--r-- root/root             15795 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/MicrosoftDemangler/lib/MicrosoftDemangler-src.zip
-rw-r--r-- root/root             19393 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/MicrosoftDemangler/lib/MicrosoftDemangler.jar
drwxr-xr-x root/root               104 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/MicrosoftDmang
-rw-r--r-- root/root               320 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/MicrosoftDmang/LICENSE.txt
-rw-r--r-- root/root                 0 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/MicrosoftDmang/Module.manifest
-rw-r--r-- root/root               129 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/MicrosoftDmang/README.html
-rw-r--r-- root/root                17 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/MicrosoftDmang/README.md
drwxr-xr-x root/root                71 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/MicrosoftDmang/lib
-rw-r--r-- root/root            185583 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/MicrosoftDmang/lib/MicrosoftDmang-src.zip
-rw-r--r-- root/root            175110 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Features/MicrosoftDmang/lib/MicrosoftDmang.jar
drwxr-xr-x root/root               116 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Framework/SoftwareModeling
-rw-r--r-- root/root               598 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Framework/SoftwareModeling/LICENSE.txt
-rw-r--r-- root/root               368 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Framework/SoftwareModeling/Module.manifest
-rw-r--r-- root/root               133 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Framework/SoftwareModeling/README.html
-rw-r--r-- root/root                19 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Framework/SoftwareModeling/README.md
drwxr-xr-x root/root               128 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Framework/SoftwareModeling/data
-rw-r--r-- root/root                75 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Framework/SoftwareModeling/data/ExtensionPoint.manifest
-rw-r--r-- root/root              1036 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Framework/SoftwareModeling/data/charset_info.xml
drwxr-xr-x root/root               152 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Framework/SoftwareModeling/data/languages
-rw-r--r-- root/root             17952 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Framework/SoftwareModeling/data/languages/compiler_spec.rxg
-rw-r--r-- root/root               891 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Framework/SoftwareModeling/data/languages/format_opinions.rxg
-rw-r--r-- root/root              7269 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Framework/SoftwareModeling/data/languages/language_common.rxg
-rw-r--r-- root/root              2127 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Framework/SoftwareModeling/data/languages/language_definitions.rxg
-rw-r--r-- root/root              6036 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Framework/SoftwareModeling/data/languages/processor_spec.rxg
-rw-r--r-- root/root               186 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Framework/SoftwareModeling/data/softwaremodeling.theme.properties
drwxr-xr-x root/root               222 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Framework/SoftwareModeling/lib
-rw-r--r-- root/root           3380835 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Framework/SoftwareModeling/lib/SoftwareModeling-src.zip
-rw-r--r-- root/root           4669290 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Framework/SoftwareModeling/lib/SoftwareModeling.jar
-rw-r--r-- root/root            167761 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Framework/SoftwareModeling/lib/antlr-runtime-3.5.2.jar
-rw-r--r-- root/root            192602 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Framework/SoftwareModeling/lib/isorelax-20050913.jar
-rw-r--r-- root/root            667496 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Framework/SoftwareModeling/lib/msv-20050913.jar
-rw-r--r-- root/root             19097 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Framework/SoftwareModeling/lib/relaxngDatatype-20050913.jar
-rw-r--r-- root/root            146996 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/Ghidra/Framework/SoftwareModeling/lib/xsdlib-20050913.jar
-rw-r--r-- root/root             56372 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/docs/ghidra_stubs/pypredef/ghidra.app.util.datatype.microsoft.pypredef
drwxr-xr-x root/root                35 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/docs/ghidra_stubs/typestubs/ghidra-stubs/app/util/datatype/microsoft
-rw-r--r-- root/root             56372 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/docs/ghidra_stubs/typestubs/ghidra-stubs/app/util/datatype/microsoft/__init__.pyi
-rw-r--r-- root/root             13935 2026-03-09 21:07 squashfs-root/opt/ghidra_12.0.4_PUBLIC/licenses/Python_Software_Foundation_License.txt
-rwxr-xr-x pepper/pepper          8544 2026-03-08 21:10 squashfs-root/opt/metasploit-framework/data/exploits/CVE-2013-3906/word/embeddings/Microsoft_Office_Excel_Worksheet1.xlsx
-rwxr-xr-x pepper/pepper          8543 2026-03-08 21:10 squashfs-root/opt/metasploit-framework/data/exploits/CVE-2013-3906/word/embeddings/Microsoft_Office_Excel_Worksheet2.xlsx
-rwxr-xr-x pepper/pepper          8544 2026-03-08 21:10 squashfs-root/opt/metasploit-framework/data/exploits/CVE-2013-3906/word/embeddings/Microsoft_Office_Excel_Worksheet3.xlsx
-rwxr-xr-x pepper/pepper          8543 2026-03-08 21:10 squashfs-root/opt/metasploit-framework/data/exploits/CVE-2013-3906/word/embeddings/Microsoft_Office_Excel_Worksheet4.xlsx
-rwxr-xr-x pepper/pepper          8542 2026-03-08 21:10 squashfs-root/opt/metasploit-framework/data/exploits/CVE-2013-3906/word/embeddings/Microsoft_Office_Excel_Worksheet5.xlsx
-rwxr-xr-x pepper/pepper          8543 2026-03-08 21:10 squashfs-root/opt/metasploit-framework/data/exploits/CVE-2013-3906/word/embeddings/Microsoft_Office_Excel_Worksheet6.xlsx
-rwxr-xr-x pepper/pepper           619 2026-03-08 21:10 squashfs-root/opt/metasploit-framework/data/exploits/capture/http/forms/microsoft.com.txt
-rwxr-xr-x pepper/pepper          1731 2026-03-08 21:10 squashfs-root/opt/metasploit-framework/data/exploits/capture/http/forms/softonic.com.txt
-rwxr-xr-x pepper/pepper           277 2026-03-08 21:10 squashfs-root/opt/metasploit-framework/data/exploits/capture/http/forms/softpedia.com.txt
-rw-r--r-- pepper/pepper          4148 2026-03-08 21:10 squashfs-root/opt/metasploit-framework/docs/metasploit-framework.wiki/How-to-check-Microsoft-patch-levels-for-your-exploit.md
-rw-r--r-- pepper/pepper          3935 2026-03-08 21:10 squashfs-root/opt/metasploit-framework/docs/metasploit-framework.wiki/Nightly-Installers.md
-rw-r--r-- pepper/pepper          6068 2026-03-08 21:10 squashfs-root/opt/metasploit-framework/documentation/modules/auxiliary/scanner/http/softing_sis_login.md
-rw-r--r-- pepper/pepper          6403 2026-03-08 21:10 squashfs-root/opt/metasploit-framework/documentation/modules/exploit/linux/http/eyesofnetwork_autodiscovery_rce.md
-rw-r--r-- pepper/pepper          1712 2026-03-08 21:10 squashfs-root/opt/metasploit-framework/documentation/modules/exploit/multi/http/oscommerce_installer_unauth_code_exec.md
-rw-r--r-- pepper/pepper          2502 2026-03-08 21:10 squashfs-root/opt/metasploit-framework/documentation/modules/exploit/unix/http/freepbx_firmware_file_upload.md
-rw-r--r-- pepper/pepper          2901 2026-03-08 21:10 squashfs-root/opt/metasploit-framework/documentation/modules/exploit/windows/fileformat/microsoft_windows_contact.md
-rw-r--r-- pepper/pepper          6550 2026-03-08 21:10 squashfs-root/opt/metasploit-framework/documentation/modules/exploit/windows/http/softing_sis_rce.md
drwxr-xr-x pepper/pepper            43 2026-03-08 21:10 squashfs-root/opt/metasploit-framework/documentation/modules/exploit/windows/nimsoft
-rw-r--r-- pepper/pepper          4453 2026-03-08 21:10 squashfs-root/opt/metasploit-framework/documentation/modules/exploit/windows/nimsoft/nimcontroller_bof.md
-rw-r--r-- pepper/pepper          2443 2026-03-08 21:10 squashfs-root/opt/metasploit-framework/documentation/modules/post/multi/gather/enum_software_versions.md
-rwxr-xr-x pepper/pepper          7122 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/external/source/exploits/cve-2015-0016/dll/src/ShimsInstaller.cpp
-rwxr-xr-x pepper/pepper            88 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/external/source/exploits/cve-2015-0016/dll/src/ShimsInstaller.h
-rw-r--r-- pepper/pepper          6531 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/lib/metasploit/framework/login_scanner/softing_sis.rb
-rw-r--r-- pepper/pepper          8440 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/modules/auxiliary/admin/http/typo3_winstaller_default_enc_keys.rb
-rw-r--r-- pepper/pepper          3579 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/modules/auxiliary/scanner/http/softing_sis_login.rb
-rw-r--r-- pepper/pepper          2878 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/modules/auxiliary/scanner/scada/indusoft_ntwebserver_fileaccess.rb
drwxr-xr-x pepper/pepper            44 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/modules/exploits/bsdi/softcart
-rw-r--r-- pepper/pepper          2844 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/modules/exploits/bsdi/softcart/mercantec_softcart.rb
-rw-r--r-- pepper/pepper         14919 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/modules/exploits/linux/http/eyesofnetwork_autodiscovery_rce.rb
-rw-r--r-- pepper/pepper          3017 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/modules/exploits/multi/http/oscommerce_installer_unauth_code_exec.rb
-rw-r--r-- pepper/pepper          4787 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/modules/exploits/osx/browser/software_update.rb
-rw-r--r-- pepper/pepper          5341 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/modules/exploits/unix/http/freepbx_firmware_file_upload.rb
-rw-r--r-- pepper/pepper          2761 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/modules/exploits/unix/webapp/wp_infusionsoft_upload.rb
-rw-r--r-- pepper/pepper          4607 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/modules/exploits/windows/browser/awingsoft_web3d_bof.rb
-rw-r--r-- pepper/pepper          2724 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/modules/exploits/windows/browser/awingsoft_winds3d_sceneurl.rb
-rw-r--r-- pepper/pepper          3621 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/modules/exploits/windows/browser/creative_software_cachefolder.rb
-rw-r--r-- pepper/pepper         10070 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/modules/exploits/windows/browser/indusoft_issymbol_internationalseparator.rb
-rw-r--r-- pepper/pepper          3870 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/modules/exploits/windows/browser/real_arcade_installerdlg.rb
-rw-r--r-- pepper/pepper          3764 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/modules/exploits/windows/browser/softartisans_getdrivename.rb
-rw-r--r-- pepper/pepper         13294 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/modules/exploits/windows/browser/ubisoft_uplay_cmd_exec.rb
-rw-r--r-- pepper/pepper          5142 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/modules/exploits/windows/fileformat/aviosoft_plf_buf.rb
-rw-r--r-- pepper/pepper          5456 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/modules/exploits/windows/fileformat/microsoft_windows_contact.rb
-rw-r--r-- pepper/pepper         10180 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/modules/exploits/windows/fileformat/safenet_softremote_groupname.rb
-rw-r--r-- pepper/pepper         14601 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/modules/exploits/windows/fileformat/ursoft_w32dasm.rb
-rw-r--r-- pepper/pepper         11847 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/modules/exploits/windows/http/softing_sis_rce.rb
drwxr-xr-x pepper/pepper            43 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/modules/exploits/windows/nimsoft
-rw-r--r-- pepper/pepper         15445 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/modules/exploits/windows/nimsoft/nimcontroller_bof.rb
-rw-r--r-- pepper/pepper          5880 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/modules/exploits/windows/scada/indusoft_webstudio_exec.rb
-rw-r--r-- pepper/pepper          3638 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/modules/exploits/windows/telnet/gamsoft_telsrv_username.rb
-rw-r--r-- pepper/pepper          2498 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/modules/exploits/windows/tftp/futuresoft_transfermode.rb
-rw-r--r-- pepper/pepper          7949 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/modules/post/multi/gather/enum_software_versions.rb
-rw-r--r-- pepper/pepper           101 2026-03-08 21:19 squashfs-root/opt/metasploit-framework/vendor/bundle/ruby/3.3.0/gems/simplecov-html-0.13.1/public/images/ui-bg_highlight-soft_75_cccccc_1x100.png
-rw-r--r-- pepper/pepper         12159 2026-03-08 21:19 squashfs-root/opt/metasploit-framework/vendor/bundle/ruby/3.3.0/gems/tzinfo-data-1.2025.1/lib/tzinfo/data/definitions/Europe/Sofia.rb
-rwxr-xr-x root/root             38000 2026-03-07 01:46 squashfs-root/usr/bin/amdgpu-arch
-rwxr-xr-x root/root            192096 2026-03-07 00:09 squashfs-root/usr/bin/swaybar
-rwxr-xr-x root/root           3954112 2026-03-10 15:12 squashfs-root/usr/bin/waybar
lrwxrwxrwx root/root                 7 2026-04-11 12:23 squashfs-root/usr/bin/xorrisofs -> xorriso
-rw-r--r-- root/root               848 2025-01-14 04:41 squashfs-root/usr/include/clang/Basic/AMDGPUTypes.def
-rw-r--r-- root/root             34306 2025-01-14 04:41 squashfs-root/usr/include/clang/Basic/BuiltinsAMDGPU.def
-rw-r--r-- root/root              2764 2025-01-14 04:41 squashfs-root/usr/include/clang/Sema/SemaAMDGPU.h
-rw-r--r-- root/root             51066 2026-02-20 14:20 squashfs-root/usr/include/drm/amdgpu_drm.h
-rw-r--r-- root/root             59223 2024-12-04 13:30 squashfs-root/usr/include/libdrm/amdgpu.h
-rw-r--r-- root/root             40342 2024-12-04 13:30 squashfs-root/usr/include/libdrm/amdgpu_drm.h
-rw-r--r-- root/root              2736 2025-01-14 04:41 squashfs-root/usr/include/llvm/BinaryFormat/AMDGPUMetadataVerifier.h
-rw-r--r-- root/root               593 2025-01-14 04:41 squashfs-root/usr/include/llvm/BinaryFormat/ELFRelocs/AMDGPU.def
-rw-r--r-- root/root             11029 2025-01-14 04:41 squashfs-root/usr/include/llvm/Demangle/MicrosoftDemangle.h
-rw-r--r-- root/root             18341 2025-01-14 04:41 squashfs-root/usr/include/llvm/Demangle/MicrosoftDemangleNodes.h
-rw-r--r-- root/root            100276 2026-03-07 01:34 squashfs-root/usr/include/llvm/IR/IntrinsicsAMDGPU.h
-rw-r--r-- root/root            143754 2025-01-14 04:41 squashfs-root/usr/include/llvm/IR/IntrinsicsAMDGPU.td
-rw-r--r-- root/root              3059 2025-01-14 04:41 squashfs-root/usr/include/llvm/Support/AMDGPUAddrSpace.h
-rw-r--r-- root/root             19007 2025-01-14 04:41 squashfs-root/usr/include/llvm/Support/AMDGPUMetadata.h
-rw-r--r-- root/root               909 2025-01-14 04:41 squashfs-root/usr/include/llvm/Transforms/Utils/AMDGPUEmitPrintf.h
drwxr-xr-x root/root                72 2026-02-20 14:20 squashfs-root/usr/include/sound/sof
-rw-r--r-- root/root              2118 2026-02-20 14:20 squashfs-root/usr/include/sound/sof/abi.h
-rw-r--r-- root/root              2245 2026-02-20 14:20 squashfs-root/usr/include/sound/sof/fw.h
-rw-r--r-- root/root              1890 2026-02-20 14:20 squashfs-root/usr/include/sound/sof/header.h
-rw-r--r-- root/root              7110 2026-02-20 14:20 squashfs-root/usr/include/sound/sof/tokens.h
drwxr-xr-x pepper/pepper          8095 2026-05-24 20:57 squashfs-root/usr/lib/firmware
-rw-r--r-- pepper/pepper           108 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.codespell.cfg
-rw-r--r-- pepper/pepper           321 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.editorconfig
drwxr-xr-x pepper/pepper           230 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git
-rw-r--r-- root/root               131 2026-05-24 21:01 squashfs-root/usr/lib/firmware/.git/FETCH_HEAD
-rw-r--r-- pepper/pepper            21 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.git/HEAD
-rw-r--r-- root/root                41 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/ORIG_HEAD
-rw-r--r-- pepper/pepper           302 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.git/config
-rw-r--r-- pepper/pepper            73 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/description
drwxr-xr-x pepper/pepper           405 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks
-rwxr-xr-x pepper/pepper           478 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks/applypatch-msg.sample
-rwxr-xr-x pepper/pepper           896 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks/commit-msg.sample
-rwxr-xr-x pepper/pepper          4726 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks/fsmonitor-watchman.sample
-rwxr-xr-x pepper/pepper           189 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks/post-update.sample
-rwxr-xr-x pepper/pepper           424 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks/pre-applypatch.sample
-rwxr-xr-x pepper/pepper          1649 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks/pre-commit.sample
-rwxr-xr-x pepper/pepper           416 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks/pre-merge-commit.sample
-rwxr-xr-x pepper/pepper          1374 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks/pre-push.sample
-rwxr-xr-x pepper/pepper          4898 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks/pre-rebase.sample
-rwxr-xr-x pepper/pepper           544 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks/pre-receive.sample
-rwxr-xr-x pepper/pepper          1492 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks/prepare-commit-msg.sample
-rwxr-xr-x pepper/pepper          2783 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks/push-to-checkout.sample
-rwxr-xr-x pepper/pepper          2308 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks/sendemail-validate.sample
-rwxr-xr-x pepper/pepper          3650 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/hooks/update.sample
-rw-r--r-- root/root            476049 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/index
drwxr-xr-x pepper/pepper            30 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/info
-rw-r--r-- pepper/pepper           240 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/info/exclude
drwxr-xr-x pepper/pepper            51 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.git/logs
-rw-r--r-- pepper/pepper           375 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/logs/HEAD
drwxr-xr-x pepper/pepper            43 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.git/logs/refs
drwxr-xr-x pepper/pepper            27 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.git/logs/refs/heads
-rw-r--r-- pepper/pepper           375 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/logs/refs/heads/main
drwxr-xr-x pepper/pepper            29 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.git/logs/refs/remotes
drwxr-xr-x pepper/pepper            39 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/logs/refs/remotes/origin
-rw-r--r-- pepper/pepper           226 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.git/logs/refs/remotes/origin/HEAD
-rw-r--r-- root/root               149 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/logs/refs/remotes/origin/main
drwxr-xr-x pepper/pepper            51 2026-05-24 21:01 squashfs-root/usr/lib/firmware/.git/objects
drwxr-xr-x pepper/pepper             3 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/objects/info
drwxr-xr-x pepper/pepper           371 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/objects/pack
-r--r--r-- root/root             30360 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/objects/pack/pack-5a70bd8b5c92e632f7b1c53feaf1bfedfedcd234.idx
-r--r--r-- root/root          99296674 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/objects/pack/pack-5a70bd8b5c92e632f7b1c53feaf1bfedfedcd234.pack
-r--r--r-- root/root              4236 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/objects/pack/pack-5a70bd8b5c92e632f7b1c53feaf1bfedfedcd234.rev
-r--r--r-- pepper/pepper        124664 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.git/objects/pack/pack-db0234c88efed90eab37bcf79b04f57dfec678a4.idx
-r--r--r-- pepper/pepper     766777623 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.git/objects/pack/pack-db0234c88efed90eab37bcf79b04f57dfec678a4.pack
-r--r--r-- pepper/pepper         17708 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.git/objects/pack/pack-db0234c88efed90eab37bcf79b04f57dfec678a4.rev
-rw-r--r-- pepper/pepper           112 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.git/packed-refs
drwxr-xr-x pepper/pepper            55 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.git/refs
drwxr-xr-x pepper/pepper            27 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/refs/heads
-rw-r--r-- root/root                41 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/refs/heads/main
drwxr-xr-x pepper/pepper            29 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.git/refs/remotes
drwxr-xr-x pepper/pepper            39 2026-05-24 21:01 squashfs-root/usr/lib/firmware/.git/refs/remotes/origin
-rw-r--r-- pepper/pepper            30 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.git/refs/remotes/origin/HEAD
-rw-r--r-- root/root                41 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/refs/remotes/origin/main
drwxr-xr-x pepper/pepper            31 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/refs/tags
-rw-r--r-- root/root                41 2026-05-24 20:57 squashfs-root/usr/lib/firmware/.git/refs/tags/20260519
-rw-r--r-- pepper/pepper            41 2026-04-13 17:44 squashfs-root/usr/lib/firmware/.git/shallow
-rw-r--r-- pepper/pepper           100 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.gitignore
-rw-r--r-- pepper/pepper          1565 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.gitlab-ci.yml
-rw-r--r-- pepper/pepper           767 2026-04-13 17:45 squashfs-root/usr/lib/firmware/.pre-commit-config.yaml
drwxr-xr-x pepper/pepper            34 2026-04-13 17:45 squashfs-root/usr/lib/firmware/3com
-rw-r--r-- pepper/pepper         44548 2026-04-13 17:45 squashfs-root/usr/lib/firmware/3com/typhoon.bin
-rw-r--r-- pepper/pepper         11358 2026-04-13 17:45 squashfs-root/usr/lib/firmware/Apache-2
-rw-r--r-- pepper/pepper           362 2026-04-13 17:45 squashfs-root/usr/lib/firmware/Dockerfile
-rw-r--r-- pepper/pepper         18092 2026-04-13 17:45 squashfs-root/usr/lib/firmware/GPL-2
-rw-r--r-- pepper/pepper         35068 2026-04-13 17:45 squashfs-root/usr/lib/firmware/GPL-3
drwxr-xr-x pepper/pepper            26 2026-04-13 17:45 squashfs-root/usr/lib/firmware/HP
drwxr-xr-x pepper/pepper            92 2026-05-24 20:57 squashfs-root/usr/lib/firmware/HP/ish
-rw-r--r-- pepper/pepper        862720 2026-04-13 17:45 squashfs-root/usr/lib/firmware/HP/ish/ish_lnlm_12128606_f9751b71.bin
-rw-r--r-- root/root            883200 2026-05-24 20:57 squashfs-root/usr/lib/firmware/HP/ish/ish_ptl_12128606_581.7779.0.bin
drwxr-xr-x pepper/pepper            26 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LENOVO
drwxr-xr-x pepper/pepper           206 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LENOVO/ish
-rw-r--r-- pepper/pepper        637440 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LENOVO/ish/ish_lnlm_lenovo_X1_2025_5.8.4.7720.bin
-rw-r--r-- pepper/pepper        875008 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LENOVO/ish/ish_lnlm_lenovo_X9-14_2025_5.8.36.09092.bin
-rw-r--r-- pepper/pepper        825856 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LENOVO/ish/ish_lnlm_lenovo_x9-15_2025_5.8.0.7720.bin
-rw-r--r-- pepper/pepper        858624 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LENOVO/ish/ish_ptl_lenovo_X1_2026_5.8.1.7782.bin
-rw-r--r-- pepper/pepper          1071 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.Abilis
-rw-r--r-- pepper/pepper          1306 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.HP
-rw-r--r-- pepper/pepper          2041 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.IntcSST2
-rw-r--r-- pepper/pepper          1152 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.Marvell
-rw-r--r-- pepper/pepper          1131 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.NXP
-rw-r--r-- pepper/pepper          3624 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.Netronome
-rw-r--r-- pepper/pepper          1777 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.OLPC
-rw-r--r-- pepper/pepper         48362 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.adsp_sst
-rw-r--r-- pepper/pepper           341 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.advansys
-rw-r--r-- pepper/pepper          3539 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.agere
-rw-r--r-- pepper/pepper           572 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.alacritech
-rw-r--r-- pepper/pepper          1946 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.atheros_firmware
-rw-r--r-- pepper/pepper           292 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.bnx2
-rw-r--r-- pepper/pepper           336 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.bnx2x
-rw-r--r-- pepper/pepper          4178 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.broadcom_bcm43xx
-rw-r--r-- pepper/pepper          2494 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.ca0132
-rw-r--r-- pepper/pepper          2870 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.cadence
-rw-r--r-- pepper/pepper          3711 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.cavium
-rw-r--r-- pepper/pepper          4000 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.cavium_liquidio
-rw-r--r-- pepper/pepper          1485 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.chelsio_firmware
-rw-r--r-- pepper/pepper          2055 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.cnm
-rw-r--r-- pepper/pepper          1954 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.cw1200
-rw-r--r-- pepper/pepper           509 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.cw1200-sdd
-rw-r--r-- pepper/pepper           213 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.cxgb3
-rw-r--r-- pepper/pepper          8914 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.cypress
-rw-r--r-- pepper/pepper           245 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.dabusb
-rw-r--r-- pepper/pepper          1492 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.e100
-rw-r--r-- pepper/pepper           798 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.emi26
-rw-r--r-- pepper/pepper           738 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.ene_firmware
-rw-r--r-- pepper/pepper          1892 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.fw_sst_0f28
-rw-r--r-- pepper/pepper         20217 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.go7007
-rw-r--r-- pepper/pepper          2040 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.ibt_firmware
-rw-r--r-- pepper/pepper           268 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.inside-secure
-rw-r--r-- pepper/pepper           851 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.it913x
-rw-r--r-- pepper/pepper          2046 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.iwlwifi_firmware
-rw-r--r-- pepper/pepper          1599 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.kaweth
-rw-r--r-- pepper/pepper           802 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.keyspan
-rw-r--r-- pepper/pepper          2527 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.lenovo
-rw-r--r-- pepper/pepper          1609 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.linaro
-rw-r--r-- pepper/pepper          9690 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.mali_csffw
-rw-r--r-- pepper/pepper           561 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.mediatek
-rw-r--r-- pepper/pepper          2336 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.microchip
-rw-r--r-- pepper/pepper           892 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.moxa
-rw-r--r-- pepper/pepper           151 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.multitech
-rw-r--r-- pepper/pepper          1450 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.myri10ge_firmware
-rw-r--r-- pepper/pepper          6212 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.nvidia
-rw-r--r-- pepper/pepper          9409 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.open-ath9k-htc-firmware
-rw-r--r-- pepper/pepper          1873 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.phanfw
-rw-r--r-- pepper/pepper          1878 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.qat_firmware
-rw-r--r-- pepper/pepper          1387 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.qla1280
-rw-r--r-- pepper/pepper          1843 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.qla2xxx
-rw-r--r-- pepper/pepper          1542 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.r8a779g_pcie_phy
-rw-r--r-- pepper/pepper          1451 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.r8a779x_usb3
-rw-r--r-- pepper/pepper          2103 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.ralink-firmware.txt
-rw-r--r-- pepper/pepper          2100 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.ralink_a_mediatek_company_firmware
-rw-r--r-- pepper/pepper          2106 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.rockchip
-rw-r--r-- pepper/pepper          2115 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.rtlwifi_firmware.txt
-rw-r--r-- pepper/pepper           458 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.sensoray
-rw-r--r-- pepper/pepper          1449 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.siano
-rw-r--r-- pepper/pepper          2918 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.ti-connectivity
-rw-r--r-- pepper/pepper          2913 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.ti-keystone
-rw-r--r-- pepper/pepper          2145 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.ti-tspa
-rw-r--r-- pepper/pepper           257 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.tigon
-rw-r--r-- pepper/pepper          1790 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.typhoon
-rw-r--r-- pepper/pepper           437 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.ueagle
-rw-r--r-- pepper/pepper          2052 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.ueagle-atm4-firmware
-rw-r--r-- pepper/pepper          1256 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.via_vt6656
-rw-r--r-- pepper/pepper          2903 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.wl1251
-rw-r--r-- pepper/pepper          1187 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.xc4000
-rw-r--r-- pepper/pepper          1179 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.xc5000
-rw-r--r-- pepper/pepper          1227 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENCE.xc5000c
-rw-r--r-- pepper/pepper            96 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE
-rw-r--r-- pepper/pepper           558 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.Lontium
-rw-r--r-- pepper/pepper          2708 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.QualcommAtheros_ar3k
-rw-r--r-- pepper/pepper          2713 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.QualcommAtheros_ath10k
-rw-r--r-- pepper/pepper           620 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.aeonsemi
-rw-r--r-- pepper/pepper           556 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.airoha
-rw-r--r-- pepper/pepper          3760 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.amd-sev
-rw-r--r-- pepper/pepper          3758 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.amd-ucode
-rw-r--r-- pepper/pepper          2938 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.amd_pmf
-rw-r--r-- pepper/pepper          2938 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.amdgpu
-rw-r--r-- pepper/pepper          8462 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.amdisp
-rw-r--r-- pepper/pepper          1186 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.amdnpu
-rw-r--r-- pepper/pepper           752 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.amlogic
-rw-r--r-- pepper/pepper           756 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.amlogic_vdec
-rw-r--r-- pepper/pepper          2644 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.amphion_vpu
-rw-r--r-- pepper/pepper          2103 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.atmel
-rw-r--r-- pepper/pepper           814 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.bfa
-rw-r--r-- pepper/pepper          1505 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.bmi260
-rw-r--r-- pepper/pepper         26746 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.cirrus
-rw-r--r-- pepper/pepper           458 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.conexant
-rw-r--r-- pepper/pepper          6819 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.dell
-rw-r--r-- pepper/pepper          1039 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.dib0700
-rw-r--r-- pepper/pepper           457 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.drxk
-rw-r--r-- pepper/pepper          1905 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.hfi1_firmware
-rw-r--r-- pepper/pepper          2080 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.i915
-rw-r--r-- pepper/pepper          1347 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.ib_qib
-rw-r--r-- pepper/pepper          2041 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.ice
-rw-r--r-- pepper/pepper          2082 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.ice_enhanced
-rw-r--r-- pepper/pepper          1859 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.intel
-rw-r--r-- pepper/pepper          2041 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.intel_vpu
-rw-r--r-- pepper/pepper          1870 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.ipu3_firmware
-rw-r--r-- pepper/pepper          2014 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.ivsc
-rw-r--r-- pepper/pepper          1890 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.ixp4xx
-rw-r--r-- pepper/pepper          1605 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.mellanox
-rw-r--r-- pepper/pepper          1097 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.mga
-rw-r--r-- pepper/pepper          3755 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.montage
-rw-r--r-- pepper/pepper          5196 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.nxp
-rw-r--r-- pepper/pepper          7259 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.nxp_mc_firmware
-rw-r--r-- pepper/pepper          2190 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.powervr
-rw-r--r-- pepper/pepper         13962 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.qcom
-rw-r--r-- pepper/pepper         14417 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.qcom-2
-rw-r--r-- pepper/pepper          1540 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.qcom_yamato
-rw-r--r-- pepper/pepper           288 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.qed
-rw-r--r-- pepper/pepper           219 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.r8169
-rw-r--r-- pepper/pepper          2943 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.radeon
-rw-r--r-- pepper/pepper           495 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.rp2
-rw-r--r-- pepper/pepper           271 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.rsi
-rw-r--r-- pepper/pepper           214 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.rt1320
-rw-r--r-- pepper/pepper           475 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.s5p-mfc
-rw-r--r-- pepper/pepper          2602 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.sdma_firmware
-rw-r--r-- pepper/pepper           201 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.tehuti
-rw-r--r-- pepper/pepper           483 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.tlg2300
-rw-r--r-- pepper/pepper           281 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.vxge
-rw-r--r-- pepper/pepper          2041 2026-04-13 17:45 squashfs-root/usr/lib/firmware/LICENSE.xe
drwxr-xr-x root/root               108 2026-05-24 20:57 squashfs-root/usr/lib/firmware/Lontium
-rw-r--r-- root/root             30735 2026-05-24 20:57 squashfs-root/usr/lib/firmware/Lontium/lt7911exc_fw.bin
-rw-r--r-- root/root            145976 2026-05-24 20:57 squashfs-root/usr/lib/firmware/Lontium/lt8713sx_fw.bin
-rw-r--r-- root/root             36090 2026-05-24 20:57 squashfs-root/usr/lib/firmware/Lontium/lt9611c_fw.bin
-rw-r--r-- root/root             17932 2026-05-24 20:57 squashfs-root/usr/lib/firmware/Lontium/lt9611uxc_fw.bin
-rw-r--r-- pepper/pepper          1096 2026-04-13 17:45 squashfs-root/usr/lib/firmware/MIT
-rw-r--r-- pepper/pepper          1368 2026-04-13 17:45 squashfs-root/usr/lib/firmware/Makefile
-rw-r--r-- pepper/pepper          2704 2026-04-13 17:45 squashfs-root/usr/lib/firmware/README.md
-rw-r--r-- root/root            442668 2026-05-24 20:57 squashfs-root/usr/lib/firmware/WHENCE
drwxr-xr-x pepper/pepper            45 2026-04-13 17:45 squashfs-root/usr/lib/firmware/acenic
-rw-r--r-- pepper/pepper         73116 2026-04-13 17:45 squashfs-root/usr/lib/firmware/acenic/tg1.bin
-rw-r--r-- pepper/pepper         77452 2026-04-13 17:45 squashfs-root/usr/lib/firmware/acenic/tg2.bin
drwxr-xr-x pepper/pepper            61 2026-04-13 17:45 squashfs-root/usr/lib/firmware/adaptec
-rw-r--r-- pepper/pepper           832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/adaptec/starfire_rx.bin
-rw-r--r-- pepper/pepper           832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/adaptec/starfire_tx.bin
drwxr-xr-x pepper/pepper            86 2026-04-13 17:45 squashfs-root/usr/lib/firmware/advansys
-rw-r--r-- pepper/pepper          5026 2026-04-13 17:45 squashfs-root/usr/lib/firmware/advansys/3550.bin
-rw-r--r-- pepper/pepper          5340 2026-04-13 17:45 squashfs-root/usr/lib/firmware/advansys/38C0800.bin
-rw-r--r-- pepper/pepper          6334 2026-04-13 17:45 squashfs-root/usr/lib/firmware/advansys/38C1600.bin
-rw-r--r-- pepper/pepper          2308 2026-04-13 17:45 squashfs-root/usr/lib/firmware/advansys/mcode.bin
drwxr-xr-x pepper/pepper            37 2026-04-13 17:45 squashfs-root/usr/lib/firmware/aeonsemi
-rw-r--r-- pepper/pepper        290272 2026-04-13 17:45 squashfs-root/usr/lib/firmware/aeonsemi/as21x1x_fw.bin
-rw-r--r-- pepper/pepper         50698 2026-04-13 17:45 squashfs-root/usr/lib/firmware/agere_ap_fw.bin
-rw-r--r-- pepper/pepper         65046 2026-04-13 17:45 squashfs-root/usr/lib/firmware/agere_sta_fw.bin
drwxr-xr-x pepper/pepper           252 2026-04-13 17:45 squashfs-root/usr/lib/firmware/airoha
-rw-r--r-- pepper/pepper        131072 2026-04-13 17:45 squashfs-root/usr/lib/firmware/airoha/EthMD32.DSP.bin
-rw-r--r-- pepper/pepper         16384 2026-04-13 17:45 squashfs-root/usr/lib/firmware/airoha/EthMD32.dm.bin
-rw-r--r-- pepper/pepper          3260 2026-04-13 17:45 squashfs-root/usr/lib/firmware/airoha/an7583_npu_data.bin
-rw-r--r-- pepper/pepper        106032 2026-04-13 17:45 squashfs-root/usr/lib/firmware/airoha/an7583_npu_rv32.bin
drwxr-xr-x pepper/pepper            68 2026-04-13 17:45 squashfs-root/usr/lib/firmware/airoha/an8811hb
-rw-r--r-- pepper/pepper         32768 2026-04-13 17:45 squashfs-root/usr/lib/firmware/airoha/an8811hb/EthMD32_CRC.DM.bin
-rw-r--r-- pepper/pepper        131072 2026-04-13 17:45 squashfs-root/usr/lib/firmware/airoha/an8811hb/EthMD32_CRC.DSP.bin
-rw-r--r-- pepper/pepper          3084 2026-04-13 17:45 squashfs-root/usr/lib/firmware/airoha/en7581_MT7996_npu_data.bin
-rw-r--r-- pepper/pepper        122336 2026-04-13 17:45 squashfs-root/usr/lib/firmware/airoha/en7581_MT7996_npu_rv32.bin
-rw-r--r-- pepper/pepper          3100 2026-04-13 17:45 squashfs-root/usr/lib/firmware/airoha/en7581_npu_data.bin
-rw-r--r-- pepper/pepper        120272 2026-04-13 17:45 squashfs-root/usr/lib/firmware/airoha/en7581_npu_rv32.bin
drwxr-xr-x pepper/pepper           231 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd
-rw-r--r-- pepper/pepper         33728 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd/amd_sev_fam17h_model0xh.sbin
-rw-r--r-- pepper/pepper         45504 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd/amd_sev_fam17h_model3xh.sbin
-rw-r--r-- pepper/pepper         97408 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd/amd_sev_fam19h_model0xh.sbin
-rw-r--r-- pepper/pepper        105536 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd/amd_sev_fam19h_model1xh.sbin
-rw-r--r-- pepper/pepper        105536 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd/amd_sev_fam19h_modelaxh.sbin
-rw-r--r-- pepper/pepper        233984 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd/amd_sev_fam1ah_model0xh.sbin
drwxr-xr-x pepper/pepper           423 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amd-ucode
-rw-r--r-- root/root              7580 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amd-ucode/README
-rw-r--r-- pepper/pepper         12684 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd-ucode/microcode_amd.bin
-rw-r--r-- pepper/pepper           490 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd-ucode/microcode_amd.bin.asc
-rw-r--r-- pepper/pepper          7876 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd-ucode/microcode_amd_fam15h.bin
-rw-r--r-- pepper/pepper           473 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd-ucode/microcode_amd_fam15h.bin.asc
-rw-r--r-- pepper/pepper          3510 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd-ucode/microcode_amd_fam16h.bin
-rw-r--r-- pepper/pepper           473 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd-ucode/microcode_amd_fam16h.bin.asc
-rw-r--r-- pepper/pepper         22596 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd-ucode/microcode_amd_fam17h.bin
-rw-r--r-- pepper/pepper           488 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd-ucode/microcode_amd_fam17h.bin.asc
-rw-r--r-- pepper/pepper        128644 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd-ucode/microcode_amd_fam19h.bin
-rw-r--r-- pepper/pepper           488 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amd-ucode/microcode_amd_fam19h.bin.asc
-rw-r--r-- root/root            129556 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amd-ucode/microcode_amd_fam1ah.bin
-rw-r--r-- root/root               488 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amd-ucode/microcode_amd_fam1ah.bin.asc
drwxr-xr-x pepper/pepper         16821 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu
-rw-r--r-- pepper/pepper           732 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/aldebaran_ip_discovery.bin
-rw-r--r-- root/root            268736 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/aldebaran_mec.bin
-rw-r--r-- root/root            268736 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/aldebaran_mec2.bin
-rw-r--r-- pepper/pepper         46060 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/aldebaran_rlc.bin
-rw-r--r-- pepper/pepper         34304 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/aldebaran_sdma.bin
-rw-r--r-- root/root            268736 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/aldebaran_sjt_mec.bin
-rw-r--r-- root/root            268736 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/aldebaran_sjt_mec2.bin
-rw-r--r-- root/root            242688 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/aldebaran_smc.bin
-rw-r--r-- root/root            446208 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/aldebaran_sos.bin
-rw-r--r-- pepper/pepper        140288 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/aldebaran_ta.bin
-rw-r--r-- pepper/pepper        422656 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/aldebaran_vcn.bin
-rw-r--r-- pepper/pepper        168448 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/arcturus_asd.bin
-rw-r--r-- pepper/pepper           316 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/arcturus_gpu_info.bin
-rw-r--r-- pepper/pepper           936 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/arcturus_ip_discovery.bin
-rw-r--r-- pepper/pepper        268576 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/arcturus_mec.bin
-rw-r--r-- pepper/pepper        268576 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/arcturus_mec2.bin
-rw-r--r-- pepper/pepper         48044 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/arcturus_rlc.bin
-rw-r--r-- pepper/pepper         17664 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/arcturus_sdma.bin
-rw-r--r-- pepper/pepper        270698 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/arcturus_smc.bin
-rw-r--r-- pepper/pepper        199248 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/arcturus_sos.bin
-rw-r--r-- pepper/pepper        127744 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/arcturus_ta.bin
-rw-r--r-- pepper/pepper        420736 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/arcturus_vcn.bin
-rw-r--r-- pepper/pepper         61932 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/banks_k_2_smc.bin
-rw-r--r-- root/root            263296 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/beige_goby_ce.bin
-rw-r--r-- pepper/pepper        114036 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/beige_goby_dmcub.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/beige_goby_me.bin
-rw-r--r-- root/root            268160 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/beige_goby_mec.bin
-rw-r--r-- root/root            268160 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/beige_goby_mec2.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/beige_goby_pfp.bin
-rw-r--r-- pepper/pepper        130472 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/beige_goby_rlc.bin
-rw-r--r-- pepper/pepper         34048 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/beige_goby_sdma.bin
-rw-r--r-- pepper/pepper        244934 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/beige_goby_smc.bin
-rw-r--r-- pepper/pepper        205984 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/beige_goby_sos.bin
-rw-r--r-- root/root            259328 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/beige_goby_ta.bin
-rw-r--r-- root/root            580240 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/beige_goby_vcn.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/bonaire_ce.bin
-rw-r--r-- pepper/pepper        130796 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/bonaire_k_smc.bin
-rw-r--r-- pepper/pepper         32336 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/bonaire_mc.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/bonaire_me.bin
-rw-r--r-- pepper/pepper         17024 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/bonaire_mec.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/bonaire_pfp.bin
-rw-r--r-- pepper/pepper          8448 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/bonaire_rlc.bin
-rw-r--r-- pepper/pepper          4456 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/bonaire_sdma.bin
-rw-r--r-- pepper/pepper          4456 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/bonaire_sdma1.bin
-rw-r--r-- pepper/pepper        130796 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/bonaire_smc.bin
-rw-r--r-- pepper/pepper        232752 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/bonaire_uvd.bin
-rw-r--r-- pepper/pepper        101072 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/bonaire_vce.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/carrizo_ce.bin
-rw-r--r-- pepper/pepper         17024 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/carrizo_me.bin
-rw-r--r-- pepper/pepper        262784 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/carrizo_mec.bin
-rw-r--r-- pepper/pepper        262784 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/carrizo_mec2.bin
-rw-r--r-- pepper/pepper         17024 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/carrizo_pfp.bin
-rw-r--r-- pepper/pepper         18836 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/carrizo_rlc.bin
-rw-r--r-- pepper/pepper         10624 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/carrizo_sdma.bin
-rw-r--r-- pepper/pepper         10624 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/carrizo_sdma1.bin
-rw-r--r-- pepper/pepper        271712 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/carrizo_uvd.bin
-rw-r--r-- pepper/pepper        175840 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/carrizo_vce.bin
-rw-r--r-- pepper/pepper        263296 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/cyan_skillfish2_ce.bin
-rw-r--r-- pepper/pepper        263424 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/cyan_skillfish2_me.bin
-rw-r--r-- pepper/pepper        268592 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/cyan_skillfish2_mec.bin
-rw-r--r-- pepper/pepper        268592 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/cyan_skillfish2_mec2.bin
-rw-r--r-- pepper/pepper        263424 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/cyan_skillfish2_pfp.bin
-rw-r--r-- pepper/pepper         25344 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/cyan_skillfish2_rlc.bin
-rw-r--r-- pepper/pepper         33792 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/cyan_skillfish2_sdma.bin
-rw-r--r-- pepper/pepper         33792 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/cyan_skillfish2_sdma1.bin
-rw-r--r-- root/root            350752 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/dcn_3_1_4_dmcub.bin
-rw-r--r-- pepper/pepper        242208 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/dcn_3_1_5_dmcub.bin
-rw-r--r-- pepper/pepper        215568 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/dcn_3_1_6_dmcub.bin
-rw-r--r-- root/root            284432 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/dcn_3_2_0_dmcub.bin
-rw-r--r-- root/root            232480 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/dcn_3_2_1_dmcub.bin
-rw-r--r-- root/root            522016 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/dcn_3_5_1_dmcub.bin
-rw-r--r-- root/root            522144 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/dcn_3_5_dmcub.bin
-rw-r--r-- root/root            535456 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/dcn_3_6_dmcub.bin
-rw-r--r-- root/root            368032 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/dcn_4_0_1_dmcub.bin
-rw-r--r-- root/root            263296 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/dimgrey_cavefish_ce.bin
-rw-r--r-- pepper/pepper        114036 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/dimgrey_cavefish_dmcub.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/dimgrey_cavefish_me.bin
-rw-r--r-- root/root            268160 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/dimgrey_cavefish_mec.bin
-rw-r--r-- root/root            268160 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/dimgrey_cavefish_mec2.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/dimgrey_cavefish_pfp.bin
-rw-r--r-- pepper/pepper        137232 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/dimgrey_cavefish_rlc.bin
-rw-r--r-- pepper/pepper         34048 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/dimgrey_cavefish_sdma.bin
-rw-r--r-- pepper/pepper        244902 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/dimgrey_cavefish_smc.bin
-rw-r--r-- pepper/pepper        210416 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/dimgrey_cavefish_sos.bin
-rw-r--r-- root/root            259328 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/dimgrey_cavefish_ta.bin
-rw-r--r-- root/root            580240 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/dimgrey_cavefish_vcn.bin
-rw-r--r-- pepper/pepper          8852 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/fiji_ce.bin
-rw-r--r-- pepper/pepper         16028 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/fiji_mc.bin
-rw-r--r-- pepper/pepper         17044 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/fiji_me.bin
-rw-r--r-- pepper/pepper        262824 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/fiji_mec.bin
-rw-r--r-- pepper/pepper        262824 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/fiji_mec2.bin
-rw-r--r-- pepper/pepper         17044 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/fiji_pfp.bin
-rw-r--r-- pepper/pepper         16636 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/fiji_rlc.bin
-rw-r--r-- pepper/pepper         10644 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/fiji_sdma.bin
-rw-r--r-- pepper/pepper         10644 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/fiji_sdma1.bin
-rw-r--r-- pepper/pepper        129604 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/fiji_smc.bin
-rw-r--r-- pepper/pepper        266768 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/fiji_uvd.bin
-rw-r--r-- pepper/pepper        161024 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/fiji_vce.bin
-rw-r--r-- root/root            263296 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_10_3_6_ce.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_10_3_6_me.bin
-rw-r--r-- root/root            268592 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_10_3_6_mec.bin
-rw-r--r-- root/root            268592 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_10_3_6_mec2.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_10_3_6_pfp.bin
-rw-r--r-- pepper/pepper        177104 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_10_3_6_rlc.bin
-rw-r--r-- pepper/pepper        263296 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_10_3_7_ce.bin
-rw-r--r-- pepper/pepper        263424 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_10_3_7_me.bin
-rw-r--r-- pepper/pepper        268160 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_10_3_7_mec.bin
-rw-r--r-- pepper/pepper        268160 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_10_3_7_mec2.bin
-rw-r--r-- pepper/pepper        263424 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_10_3_7_pfp.bin
-rw-r--r-- pepper/pepper        177088 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_10_3_7_rlc.bin
-rw-r--r-- pepper/pepper        132352 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_0_imu.bin
-rw-r--r-- pepper/pepper        132352 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_0_imu_kicker.bin
-rw-r--r-- pepper/pepper        315120 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_0_me.bin
-rw-r--r-- pepper/pepper        406528 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_0_mec.bin
-rw-r--r-- pepper/pepper        286336 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_0_mes.bin
-rw-r--r-- root/root            220480 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_0_mes1.bin
-rw-r--r-- root/root            260624 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_0_mes_2.bin
-rw-r--r-- pepper/pepper        232096 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_0_pfp.bin
-rw-r--r-- pepper/pepper        185376 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_0_rlc.bin
-rw-r--r-- pepper/pepper        185248 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_0_rlc_1.bin
-rw-r--r-- pepper/pepper        185376 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_0_rlc_kicker.bin
-rw-r--r-- pepper/pepper        132352 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_1_imu.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_1_me.bin
-rw-r--r-- root/root            268160 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_1_mec.bin
-rw-r--r-- pepper/pepper        287712 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_1_mes.bin
-rw-r--r-- root/root            235312 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_1_mes1.bin
-rw-r--r-- root/root            263616 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_1_mes_2.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_1_pfp.bin
-rw-r--r-- root/root            157040 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_1_rlc.bin
-rw-r--r-- pepper/pepper        132352 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_2_imu.bin
-rw-r--r-- pepper/pepper        315120 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_2_me.bin
-rw-r--r-- pepper/pepper        406528 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_2_mec.bin
-rw-r--r-- pepper/pepper        286336 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_2_mes.bin
-rw-r--r-- pepper/pepper        218560 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_2_mes1.bin
-rw-r--r-- root/root            260624 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_2_mes_2.bin
-rw-r--r-- pepper/pepper        232112 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_2_pfp.bin
-rw-r--r-- pepper/pepper        178848 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_2_rlc.bin
-rw-r--r-- pepper/pepper        132352 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_3_imu.bin
-rw-r--r-- pepper/pepper        315136 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_3_me.bin
-rw-r--r-- pepper/pepper        406528 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_3_mec.bin
-rw-r--r-- pepper/pepper        220544 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_3_mes1.bin
-rw-r--r-- root/root            260688 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_3_mes_2.bin
-rw-r--r-- pepper/pepper        232112 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_3_pfp.bin
-rw-r--r-- root/root            179104 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_3_rlc.bin
-rw-r--r-- pepper/pepper        132352 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_4_imu.bin
-rw-r--r-- pepper/pepper        263424 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_4_me.bin
-rw-r--r-- pepper/pepper        268160 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_4_mec.bin
-rw-r--r-- pepper/pepper        287712 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_4_mes.bin
-rw-r--r-- pepper/pepper        234640 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_4_mes1.bin
-rw-r--r-- root/root            257760 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_4_mes_2.bin
-rw-r--r-- pepper/pepper        263424 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_4_pfp.bin
-rw-r--r-- pepper/pepper        159152 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_0_4_rlc.bin
-rw-r--r-- pepper/pepper        132352 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_0_imu.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_0_me.bin
-rw-r--r-- root/root            268160 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_0_mec.bin
-rw-r--r-- pepper/pepper        238128 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_0_mes1.bin
-rw-r--r-- root/root            258208 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_0_mes_2.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_0_pfp.bin
-rw-r--r-- pepper/pepper        166528 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_0_rlc.bin
-rw-r--r-- pepper/pepper        132352 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_1_imu.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_1_me.bin
-rw-r--r-- root/root            268160 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_1_mec.bin
-rw-r--r-- pepper/pepper        238320 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_1_mes1.bin
-rw-r--r-- root/root            258496 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_1_mes_2.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_1_pfp.bin
-rw-r--r-- pepper/pepper        161040 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_1_rlc.bin
-rw-r--r-- pepper/pepper        132352 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_2_imu.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_2_me.bin
-rw-r--r-- root/root            268160 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_2_mec.bin
-rw-r--r-- pepper/pepper        237776 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_2_mes1.bin
-rw-r--r-- root/root            260560 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_2_mes_2.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_2_pfp.bin
-rw-r--r-- pepper/pepper        162096 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_2_rlc.bin
-rw-r--r-- pepper/pepper        132352 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_3_imu.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_3_me.bin
-rw-r--r-- root/root            268160 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_3_mec.bin
-rw-r--r-- pepper/pepper        237776 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_3_mes1.bin
-rw-r--r-- root/root            260560 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_3_mes_2.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_3_pfp.bin
-rw-r--r-- pepper/pepper        162064 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_11_5_3_rlc.bin
-rw-r--r-- pepper/pepper        132352 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_0_imu.bin
-rw-r--r-- root/root            459840 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_0_me.bin
-rw-r--r-- root/root            455648 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_0_mec.bin
-rw-r--r-- pepper/pepper        636048 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_0_mes.bin
-rw-r--r-- pepper/pepper        609840 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_0_mes1.bin
-rw-r--r-- root/root            353536 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_0_pfp.bin
-rw-r--r-- pepper/pepper        150704 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_0_rlc.bin
-rw-r--r-- pepper/pepper          2048 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_0_toc.bin
-rw-r--r-- root/root            727680 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_0_uni_mes.bin
-rw-r--r-- pepper/pepper        132352 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_1_imu.bin
-rw-r--r-- pepper/pepper        132352 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_1_imu_kicker.bin
-rw-r--r-- root/root            459840 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_1_me.bin
-rw-r--r-- root/root            455648 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_1_mec.bin
-rw-r--r-- pepper/pepper        643536 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_1_mes.bin
-rw-r--r-- pepper/pepper        611920 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_1_mes1.bin
-rw-r--r-- root/root            353536 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_1_pfp.bin
-rw-r--r-- pepper/pepper        150848 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_1_rlc.bin
-rw-r--r-- pepper/pepper        150848 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_1_rlc_kicker.bin
-rw-r--r-- pepper/pepper          2048 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_1_toc.bin
-rw-r--r-- root/root            727680 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_12_0_1_uni_mes.bin
-rw-r--r-- root/root            268736 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_9_4_3_mec.bin
-rw-r--r-- root/root             38708 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_9_4_3_rlc.bin
-rw-r--r-- root/root            268736 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_9_4_3_sjt_mec.bin
-rw-r--r-- pepper/pepper        268736 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_9_4_4_mec.bin
-rw-r--r-- pepper/pepper         43388 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_9_4_4_rlc.bin
-rw-r--r-- pepper/pepper        268736 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_9_4_4_sjt_mec.bin
-rw-r--r-- root/root            268736 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_9_5_0_mec.bin
-rw-r--r-- pepper/pepper         38700 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/gc_9_5_0_rlc.bin
-rw-r--r-- root/root            268736 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/gc_9_5_0_sjt_mec.bin
-rw-r--r-- root/root                 0 2026-03-06 11:35 squashfs-root/usr/lib/firmware/amdgpu/gfx1201_ce.bin
-rw-r--r-- root/root                 0 2026-03-06 11:35 squashfs-root/usr/lib/firmware/amdgpu/gfx1201_me.bin
-rw-r--r-- root/root                 0 2026-03-06 11:35 squashfs-root/usr/lib/firmware/amdgpu/gfx1201_mec.bin
-rw-r--r-- root/root                 0 2026-03-06 11:35 squashfs-root/usr/lib/firmware/amdgpu/gfx1201_pfp.bin
-rw-r--r-- root/root                 0 2026-03-06 11:35 squashfs-root/usr/lib/firmware/amdgpu/gfx1201_rlc.bin
-rw-r--r-- root/root            209408 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/green_sardine_asd.bin
-rw-r--r-- root/root             36608 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/green_sardine_ce.bin
-rw-r--r-- pepper/pepper        121608 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/green_sardine_dmcub.bin
-rw-r--r-- root/root             69376 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/green_sardine_me.bin
-rw-r--r-- root/root            268224 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/green_sardine_mec.bin
-rw-r--r-- root/root            268224 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/green_sardine_mec2.bin
-rw-r--r-- root/root             85760 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/green_sardine_pfp.bin
-rw-r--r-- pepper/pepper         39928 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/green_sardine_rlc.bin
-rw-r--r-- pepper/pepper         17408 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/green_sardine_sdma.bin
-rw-r--r-- root/root             37632 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/green_sardine_ta.bin
-rw-r--r-- pepper/pepper        404544 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/green_sardine_vcn.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/hainan_ce.bin
-rw-r--r-- pepper/pepper         61876 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/hainan_k_smc.bin
-rw-r--r-- pepper/pepper         31996 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/hainan_mc.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/hainan_me.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/hainan_pfp.bin
-rw-r--r-- pepper/pepper          8448 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/hainan_rlc.bin
-rw-r--r-- pepper/pepper         61444 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/hainan_smc.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/hawaii_ce.bin
-rw-r--r-- pepper/pepper        130796 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/hawaii_k_smc.bin
-rw-r--r-- pepper/pepper         32796 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/hawaii_mc.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/hawaii_me.bin
-rw-r--r-- pepper/pepper         17024 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/hawaii_mec.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/hawaii_pfp.bin
-rw-r--r-- pepper/pepper          8448 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/hawaii_rlc.bin
-rw-r--r-- pepper/pepper          4456 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/hawaii_sdma.bin
-rw-r--r-- pepper/pepper          4456 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/hawaii_sdma1.bin
-rw-r--r-- pepper/pepper        130796 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/hawaii_smc.bin
-rw-r--r-- pepper/pepper        232752 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/hawaii_uvd.bin
-rw-r--r-- pepper/pepper        101072 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/hawaii_vce.bin
-rw-r--r-- pepper/pepper       3859408 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/isp_4_1_1.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/kabini_ce.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/kabini_me.bin
-rw-r--r-- pepper/pepper         17024 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/kabini_mec.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/kabini_pfp.bin
-rw-r--r-- pepper/pepper         10496 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/kabini_rlc.bin
-rw-r--r-- pepper/pepper          4456 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/kabini_sdma.bin
-rw-r--r-- pepper/pepper          4456 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/kabini_sdma1.bin
-rw-r--r-- pepper/pepper        232752 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/kabini_uvd.bin
-rw-r--r-- pepper/pepper        101072 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/kabini_vce.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/kaveri_ce.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/kaveri_me.bin
-rw-r--r-- pepper/pepper         17024 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/kaveri_mec.bin
-rw-r--r-- pepper/pepper         17024 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/kaveri_mec2.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/kaveri_pfp.bin
-rw-r--r-- pepper/pepper         10496 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/kaveri_rlc.bin
-rw-r--r-- pepper/pepper          4456 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/kaveri_sdma.bin
-rw-r--r-- pepper/pepper          4456 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/kaveri_sdma1.bin
-rw-r--r-- pepper/pepper        232752 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/kaveri_uvd.bin
-rw-r--r-- pepper/pepper        101072 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/kaveri_vce.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/mullins_ce.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/mullins_me.bin
-rw-r--r-- pepper/pepper         17024 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/mullins_mec.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/mullins_pfp.bin
-rw-r--r-- pepper/pepper         10496 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/mullins_rlc.bin
-rw-r--r-- pepper/pepper          4456 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/mullins_sdma.bin
-rw-r--r-- pepper/pepper          4456 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/mullins_sdma1.bin
-rw-r--r-- pepper/pepper        232752 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/mullins_uvd.bin
-rw-r--r-- pepper/pepper        101072 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/mullins_vce.bin
-rw-r--r-- root/root            209408 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/navi10_asd.bin
-rw-r--r-- root/root            263296 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/navi10_ce.bin
-rw-r--r-- pepper/pepper           772 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navi10_gpu_info.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/navi10_me.bin
-rw-r--r-- root/root            268160 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/navi10_mec.bin
-rw-r--r-- root/root            268160 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/navi10_mec2.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/navi10_pfp.bin
-rw-r--r-- pepper/pepper         43952 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navi10_rlc.bin
-rw-r--r-- pepper/pepper         33792 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navi10_sdma.bin
-rw-r--r-- pepper/pepper         33792 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navi10_sdma1.bin
-rw-r--r-- pepper/pepper        267970 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navi10_smc.bin
-rw-r--r-- pepper/pepper        184512 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navi10_sos.bin
-rw-r--r-- root/root             37632 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/navi10_ta.bin
-rw-r--r-- pepper/pepper        404544 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navi10_vcn.bin
-rw-r--r-- root/root            209408 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/navi12_asd.bin
-rw-r--r-- root/root            263296 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/navi12_ce.bin
-rw-r--r-- pepper/pepper         23904 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navi12_dmcu.bin
-rw-r--r-- pepper/pepper           772 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navi12_gpu_info.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/navi12_me.bin
-rw-r--r-- root/root            268160 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/navi12_mec.bin
-rw-r--r-- root/root            268160 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/navi12_mec2.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/navi12_pfp.bin
-rw-r--r-- pepper/pepper         43720 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navi12_rlc.bin
-rw-r--r-- pepper/pepper         33792 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navi12_sdma.bin
-rw-r--r-- pepper/pepper         33792 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navi12_sdma1.bin
-rw-r--r-- pepper/pepper        264586 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navi12_smc.bin
-rw-r--r-- pepper/pepper        204656 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navi12_sos.bin
-rw-r--r-- root/root             37632 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/navi12_ta.bin
-rw-r--r-- pepper/pepper        404544 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navi12_vcn.bin
-rw-r--r-- root/root            209408 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/navi14_asd.bin
-rw-r--r-- root/root            263296 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/navi14_ce.bin
-rw-r--r-- pepper/pepper        263296 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navi14_ce_wks.bin
-rw-r--r-- pepper/pepper           772 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navi14_gpu_info.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/navi14_me.bin
-rw-r--r-- pepper/pepper        263424 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navi14_me_wks.bin
-rw-r--r-- root/root            268160 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/navi14_mec.bin
-rw-r--r-- root/root            268160 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/navi14_mec2.bin
-rw-r--r-- pepper/pepper        268160 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navi14_mec2_wks.bin
-rw-r--r-- pepper/pepper        268160 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navi14_mec_wks.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/navi14_pfp.bin
-rw-r--r-- pepper/pepper        263424 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navi14_pfp_wks.bin
-rw-r--r-- pepper/pepper         42856 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navi14_rlc.bin
-rw-r--r-- pepper/pepper         33792 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navi14_sdma.bin
-rw-r--r-- pepper/pepper         33792 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navi14_sdma1.bin
-rw-r--r-- pepper/pepper        264586 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navi14_smc.bin
-rw-r--r-- pepper/pepper        184176 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navi14_sos.bin
-rw-r--r-- root/root             37632 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/navi14_ta.bin
-rw-r--r-- pepper/pepper        404544 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navi14_vcn.bin
-rw-r--r-- root/root            263296 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/navy_flounder_ce.bin
-rw-r--r-- pepper/pepper        114036 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navy_flounder_dmcub.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/navy_flounder_me.bin
-rw-r--r-- root/root            268160 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/navy_flounder_mec.bin
-rw-r--r-- root/root            268160 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/navy_flounder_mec2.bin
-rw-r--r-- root/root            263424 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/navy_flounder_pfp.bin
-rw-r--r-- pepper/pepper        137336 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navy_flounder_rlc.bin
-rw-r--r-- pepper/pepper         34048 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navy_flounder_sdma.bin
-rw-r--r-- pepper/pepper        244902 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navy_flounder_smc.bin
-rw-r--r-- pepper/pepper        218608 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/navy_flounder_sos.bin
-rw-r--r-- root/root            259328 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/navy_flounder_ta.bin
-rw-r--r-- root/root            580240 2026-05-24 20:57 squashfs-root/usr/lib/firmware/amdgpu/navy_flounder_vcn.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/oland_ce.bin
-rw-r--r-- pepper/pepper         62692 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/oland_k_smc.bin
-rw-r--r-- pepper/pepper         31996 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/oland_mc.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/oland_me.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/oland_pfp.bin
-rw-r--r-- pepper/pepper          8448 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/oland_rlc.bin
-rw-r--r-- pepper/pepper         62260 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/oland_smc.bin
-rw-r--r-- pepper/pepper        219928 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/oland_uvd.bin
-rw-r--r-- pepper/pepper        197120 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/picasso_asd.bin
-rw-r--r-- pepper/pepper          9344 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/picasso_ce.bin
-rw-r--r-- pepper/pepper           316 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/picasso_gpu_info.bin
-rw-r--r-- pepper/pepper           628 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/picasso_ip_discovery.bin
-rw-r--r-- pepper/pepper         17536 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/picasso_me.bin
-rw-r--r-- pepper/pepper        268064 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/picasso_mec.bin
-rw-r--r-- pepper/pepper        268064 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/picasso_mec2.bin
-rw-r--r-- pepper/pepper         21632 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/picasso_pfp.bin
-rw-r--r-- pepper/pepper         39140 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/picasso_rlc.bin
-rw-r--r-- pepper/pepper         39140 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/picasso_rlc_am4.bin
-rw-r--r-- pepper/pepper         17408 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/picasso_sdma.bin
-rw-r--r-- pepper/pepper         46080 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/picasso_ta.bin
-rw-r--r-- pepper/pepper        366560 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/picasso_vcn.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/pitcairn_ce.bin
-rw-r--r-- pepper/pepper         61712 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/pitcairn_k_smc.bin
-rw-r--r-- pepper/pepper         31644 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/pitcairn_mc.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/pitcairn_me.bin
-rw-r--r-- pepper/pepper          8832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/pitcairn_pfp.bin
-rw-r--r-- pepper/pepper          8448 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/pitcairn_rlc.bin
-rw-r--r-- pepper/pepper         61280 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/pitcairn_smc.bin
-rw-r--r-- pepper/pepper        219928 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/pitcairn_uvd.bin
-rw-r--r-- pepper/pepper          8852 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris10_ce.bin
-rw-r--r-- pepper/pepper          8852 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris10_ce_2.bin
-rw-r--r-- pepper/pepper        130228 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris10_k2_smc.bin
-rw-r--r-- pepper/pepper         32832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris10_k_mc.bin
-rw-r--r-- pepper/pepper        130244 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris10_k_smc.bin
-rw-r--r-- pepper/pepper         32732 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris10_mc.bin
-rw-r--r-- pepper/pepper         17044 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris10_me.bin
-rw-r--r-- pepper/pepper         17044 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris10_me_2.bin
-rw-r--r-- pepper/pepper        262824 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris10_mec.bin
-rw-r--r-- pepper/pepper        262824 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris10_mec2.bin
-rw-r--r-- pepper/pepper        262824 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris10_mec2_2.bin
-rw-r--r-- pepper/pepper        262824 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris10_mec_2.bin
-rw-r--r-- pepper/pepper         17044 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris10_pfp.bin
-rw-r--r-- pepper/pepper         17044 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris10_pfp_2.bin
-rw-r--r-- pepper/pepper         23488 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris10_rlc.bin
-rw-r--r-- pepper/pepper         12692 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris10_sdma.bin
-rw-r--r-- pepper/pepper         12692 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris10_sdma1.bin
-rw-r--r-- pepper/pepper        130216 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris10_smc.bin
-rw-r--r-- pepper/pepper        130196 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris10_smc_sk.bin
-rw-r--r-- pepper/pepper        375424 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris10_uvd.bin
-rw-r--r-- pepper/pepper        166816 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris10_vce.bin
-rw-r--r-- pepper/pepper          8852 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris11_ce.bin
-rw-r--r-- pepper/pepper          8852 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris11_ce_2.bin
-rw-r--r-- pepper/pepper        130228 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris11_k2_smc.bin
-rw-r--r-- pepper/pepper         32832 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris11_k_mc.bin
-rw-r--r-- pepper/pepper        130228 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris11_k_smc.bin
-rw-r--r-- pepper/pepper         33104 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris11_mc.bin
-rw-r--r-- pepper/pepper         17044 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris11_me.bin
-rw-r--r-- pepper/pepper         17044 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris11_me_2.bin
-rw-r--r-- pepper/pepper        262824 2026-04-13 17:45 squashfs-root/usr/lib/firmware/amdgpu/polaris11_mec.bin
