# Z890 SableLinux Waybar Polish — 2026-07-09

## Context

The Z890 SableLinux install had an older, text-oriented Waybar profile. The newer live USB environment appeared visually better.

## Investigation

The Z890 install had only DejaVu fonts available for Waybar icon rendering. The mounted live USB outer filesystem did not contain the root filesystem directly; the actual live root was inside `live/filesystem.squashfs`.

Inspection of the USB squashfs found Font Awesome 6 fonts under:

- `/usr/share/fonts/truetype/fontawesome/Font Awesome 6 Brands-Regular-400.otf`
- `/usr/share/fonts/truetype/fontawesome/Font Awesome 6 Free-Regular-400.otf`
- `/usr/share/fonts/truetype/fontawesome/Font Awesome 6 Free-Solid-900.otf`

These were copied into the Z890 Sable install.

## Result

`fc-cache -fv` on SableLinux confirmed Font Awesome 6 was detected.

Waybar was updated to:

- remove unsupported `tray` module
- use Font Awesome icons
- add boxed module styling
- preserve the Sable dark/purple theme

The resulting bar is visually suitable for the Z890 flagship reference install.

## Remaining Notes

Non-blocking Waybar messages observed:

- `Unable to receive desktop appearance` from missing xdg-desktop-portal service
- `Mapping is not an object`, likely from keyboard-state formatting
- `Waybar has been built without rfkill support`

These are not blockers for the desktop profile.
