# Thunar and Fuzzel Integration — November 19, 2026

## Canonical environment

- Host: Z890 / SableLinux
- User: sable
- Repository branch: development
- Starting commit: 1df6a28
- Desktop: Sway with Fuzzel application launcher

## Investigation

The operator initially believed that the canonical SableLinux
installation lacked a graphical file manager because Thunar was
not visible among the initial applications shown by Fuzzel.

Read-only inspection established:

- Thunar 4.20.3 is already installed.
- Executable: /usr/bin/thunar
- Settings executable: /usr/bin/thunar-settings
- GTK3 version: 3.24.43
- Fuzzel version: 1.11.1
- Desktop entry: /usr/share/applications/thunar.desktop
- Desktop entry declares Type=Application and Exec=thunar %U.
- No launcher visibility restrictions were found.
- Fuzzel configuration specifies eight visible application rows.
- Thunar is already recorded in the historical BLFS inventory.
- configs/live/mimeapps.list already associates directories
  with thunar.desktop.

## Resolution

Thunar was confirmed discoverable by typing its name into
Fuzzel, launched with the existing Windows+D shortcut.

The file manager opened successfully.

No Thunar installation, Sway configuration modification,
or Fuzzel configuration modification was necessary.

The operator subsequently adjusted application usage so
Thunar could appear in Fuzzel's initial application list.
The resulting initial-list ordering was not independently
captured as test evidence.

## Release engineering implications

Thunar is an existing canonical desktop component, not
a new package requiring installation.

Future release-rootfs validation should establish:

1. Thunar executable exists and is runnable.
2. Required shared libraries are present.
3. thunar.desktop is installed and valid.
4. The desktop entry references an available executable.
5. Required icons and MIME integration are present.
6. The generated live rootfs contains the expected files.
7. Thunar launches successfully in live desktop testing.

Historical package documentation alone does not prove
that the next generated ISO contains a functional Thunar
installation.

## Verification status

- Installed Thunar: PASS
- Fuzzel application discovery: PASS
- Launch through Fuzzel: PASS
- Initial-list ordering: operator-reported improvement
- Generated-rootfs validation: PENDING
- Live-ISO validation: PENDING

## Release gate

ISO release remains BLOCKED pending completion of
rootfs contamination, account, service, and release
artifact validation.

No release gate was reopened by this desktop investigation.
