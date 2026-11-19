# SableLinux Asus live session idle recovery failure

Observed November 9, 2026 on the ASUS Q503UA, booted from the SanDisk in UEFI mode.

- Build ID `20261109T182839Z-3b312d6-k6.16.1-sable-asus-test1`
- Commit `3b312d625d232438eb406a595279379d1b6e1abe`
- Symptom after an idle period. The screen turned red and no recovery or unlock prompt was visible.
- The operator described the machine as going to sleep. System suspend, display power management, and session locking have yet to be distinguished.
- Recovery and cause remain undiagnosed. No journal or compositor logs were captured for this incident.

Earlier in the same live session, the desktop boot and Wi-Fi with Ethernet disconnected were verified. The built-in touchpad did not work, a separate observation.

For a future reproduction, record the idle duration, the display state, whether a virtual terminal is reachable, and journal entries around the event before rebooting if possible.
