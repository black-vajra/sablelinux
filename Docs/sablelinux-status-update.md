## Current Status
- **Chapter:** Pre-build / Chapter 2 ready
- **Last completed:** Loop device setup, git repo initialized and scrubbed clean
- **Next step:** Begin LFS Chapter 2 — downloading packages and patches

## Decisions Made
- Loop device file: `/root/lfs.img` (50GB sparse, ext4)
- Mount point: `/mnt/lfs` ($LFS)
- Mount/umount scripts: `/usr/local/bin/lfs-mount` and `/usr/local/bin/lfs-umount`
- GitHub repo: https://github.com/black-vajra/sablelinux (private, branch: development)
- Git credential helper: store (~/.git-credentials)
- Build logs location: `~/sablelinux/build-logs/` (milestones.log, packages.log)

## Session Notes
- `$LFS=/mnt/lfs` added to ~/.bashrc
- `$HOME/.local/bin` added to PATH in ~/.bashrc (for git-filter-repo)
- git history scrubbed clean with git-filter-repo (kate swap file removed)
- .gitignore in place covering *.swp, *.kate-swp, *~, *.tmp, .DS_Store

## At Start of Each Session
1. `sudo lfs-mount` — remount loop device
2. `echo $LFS` — verify /mnt/lfs
3. `export MAKEFLAGS="-j14"` — set parallel jobs
