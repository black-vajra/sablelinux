# SableLinux Sway Desktop User Manual

## Desktop philosophy

SableLinux is keyboard-first without being mouse-hostile.

Keyboard and mouse workflows operate on the same Sway
window-management system.

## Upper Waybar

The upper bar displays workspace controls and system indicators.

The redundant active-window title has been removed.

## Bottom application taskbar

The bottom taskbar is always visible.

Current application controls:

- Foot terminal
- Firefox browser

Mouse operations:

- Left-click: hide or restore the application window
- Right-click: focus the application window

Restored windows return to tiled layout.

The initial window-control helper supports one window per
application. General multiwindow handling remains future work.

## Fullscreen and window controls

Sway's existing keyboard shortcuts remain available.

Fullscreen: Super+f

Other bindings must be verified against the installed Sway
configuration before being added to this manual.

## Taskbar auto-hide

Auto-hide is deferred.

Experiments using Waybar native hide mode and opacity-based
hover behavior did not provide acceptable mouse interaction.

The accepted release design uses an always-visible bottom bar.

## Configuration and deployment

Repository-managed configuration:

- configs/desktop/sway/config
- configs/desktop/waybar/config
- configs/desktop/waybar/bottom-config
- configs/desktop/waybar/bottom-style.css
- configs/desktop/waybar/sable-window-control

The canonical live-root generator installs these files into
the release-owned home.

The release-home security validator checks the approved
files, content, ownership and permissions.

## Release considerations

Firefox icon rendering currently references the installed
Firefox icon under /opt/firefox.

We should not copy an arbitrary icon from the host as an
untracked release input.

Validate icon provenance and availability in generated rootfs.

Reboot persistence and physical hardware behavior must be
verified before the desktop receives release approval.
