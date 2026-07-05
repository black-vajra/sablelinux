#!/bin/bash
# =============================================================================
# kde-plasma-build-v4-archive.sh
# SableLinux — KDE Plasma 6.4.0 Complete Build Script
# Status: ARCHIVE ONLY — DO NOT RUN
#
# This script documents the complete, known-good build sequence for
# KDE Plasma 6.4.0 on LFS 12.4-systemd with GCC 15.2.0 / Qt 6.8.2.
#
# Plasma 6 was abandoned as a SableLinux desktop target after two full
# build cycles failed to produce a working Wayland session under SDDM.
# Root causes documented in BUILDLOG.md (2026-04-03 entry).
#
# This script is preserved as a reference in case:
#   - Hardware changes make source-based ROCm practical and KDE is revisited
#   - SableLinux targets a second "workstation" edition separate from the
#     primary pentest/security edition (Sway)
#   - Someone else wants to run this on an LFS system and benefits from
#     all the GCC 15 / LFS-specific fixes being pre-applied
#
# If you attempt to run this, you will need:
#   - Replace SDDM section with greetd (see bottom of script)
#   - Verify Qt wayland plugin dependencies: ldd /usr/lib/qt6/plugins/platforms/libqwayland-generic.so
#   - Ensure sddm user is in input and seat groups (or just use greetd)
#   - Ensure /etc/vconsole.conf has no FONT= entry
#   - baloo excluded — GCC 15 QString::arg 6-arg overload removed
#
# Hardware target: Intel Core Ultra 5 245K + AMD RX 9070 XT (gfx1201/RDNA4)
# Kernel: 6.16.1-lfs-12.4-systemd
# GCC: 15.2.0 | cmake: 3.31.6 | Qt: 6.8.2 | Plasma: 6.4.0 | KF6: 6.24.0
# =============================================================================

set -e
MAKEFLAGS="-j14"
export MAKEFLAGS
SRCDIR=/sources
LOG=/sources/kde-plasma-build-v4.log

log() { echo ">>> $*" | tee -a "$LOG"; }
die() { echo "FATAL: $*" | tee -a "$LOG"; exit 1; }

exec > >(tee -a "$LOG") 2>&1
log "KDE Plasma 6.4.0 Build — $(date)"

# =============================================================================
# PHASE 1: XCB Utilities (Qt6 xcb platform plugin deps)
# =============================================================================
log "Phase 1: XCB utilities"

build_xcb_util() {
    local name=$1 ver=$2 url=$3
    log "Building $name $ver"
    cd $SRCDIR
    wget -c "$url" -O "${name}-${ver}.tar.xz"
    tar xf "${name}-${ver}.tar.xz"
    cd "${name}-${ver}"
    ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static
    make $MAKEFLAGS && make install
}

build_xcb_util xcb-util          0.4.1   https://xcb.freedesktop.org/dist/xcb-util-0.4.1.tar.xz
build_xcb_util xcb-util-image    0.4.1   https://xcb.freedesktop.org/dist/xcb-util-image-0.4.1.tar.xz
build_xcb_util xcb-util-renderutil 0.3.10 https://xcb.freedesktop.org/dist/xcb-util-renderutil-0.3.10.tar.xz
build_xcb_util xcb-util-wm       0.4.2   https://xcb.freedesktop.org/dist/xcb-util-wm-0.4.2.tar.xz
build_xcb_util xcb-util-keysyms  0.4.1   https://xcb.freedesktop.org/dist/xcb-util-keysyms-0.4.1.tar.xz

# xcb-util-cursor requires xcb-util-render
log "Building xcb-util-cursor 0.1.4"
cd $SRCDIR
wget -c https://xcb.freedesktop.org/dist/xcb-util-cursor-0.1.4.tar.xz
tar xf xcb-util-cursor-0.1.4.tar.xz
cd xcb-util-cursor-0.1.4
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static
make $MAKEFLAGS && make install

# =============================================================================
# PHASE 2: wayland-protocols 1.48
# (meson, no ECM needed — must precede Qt6 and KF6)
# =============================================================================
log "Phase 2: wayland-protocols 1.48"
cd $SRCDIR
wget -c https://gitlab.freedesktop.org/wayland/wayland-protocols/-/releases/1.48/downloads/wayland-protocols-1.48.tar.xz
tar xf wayland-protocols-1.48.tar.xz
cd wayland-protocols-1.48
rm -rf build
meson setup build --prefix=/usr --libdir=lib -Dtests=false
ninja -C build -j14
ninja -C build install

# =============================================================================
# PHASE 3: Qt 6.8.2
# =============================================================================
log "Phase 3: Qt 6.8.2"

QT_VERSION=6.8.2
QT_BASE=https://download.qt.io/official_releases/qt/6.8/${QT_VERSION}/submodules

build_qt_module() {
    local mod=$1
    local extra_flags="${2:-}"
    log "Building Qt $mod"
    cd $SRCDIR
    wget -c "${QT_BASE}/qt${mod}-everywhere-src-${QT_VERSION}.tar.xz"
    tar xf "qt${mod}-everywhere-src-${QT_VERSION}.tar.xz"
    cd "qt${mod}-everywhere-src-${QT_VERSION}"
    rm -rf build && mkdir build && cd build
    cmake .. \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_BUILD_TYPE=Release \
        -DQT_BUILD_TESTS=OFF \
        -DQT_BUILD_EXAMPLES=OFF \
        $extra_flags
    cmake --build . -j14
    cmake --install .
}

# qtbase — xcb platform plugin requires xcb-util-* above
log "Building Qt qtbase $QT_VERSION"
cd $SRCDIR
wget -c "${QT_BASE}/qtbase-everywhere-src-${QT_VERSION}.tar.xz"
tar xf "qtbase-everywhere-src-${QT_VERSION}.tar.xz"
cd "qtbase-everywhere-src-${QT_VERSION}"
rm -rf build && mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DQT_BUILD_TESTS=OFF \
    -DQT_BUILD_EXAMPLES=OFF \
    -DFEATURE_xcb=ON \
    -DFEATURE_xcb_xlib=ON \
    -DFEATURE_xlib=ON
cmake --build . -j14
cmake --install .

# qtshadertools — needs -include cstdint for GCC 15
log "Building Qt qtshadertools $QT_VERSION"
cd $SRCDIR
wget -c "${QT_BASE}/qtshadertools-everywhere-src-${QT_VERSION}.tar.xz"
tar xf "qtshadertools-everywhere-src-${QT_VERSION}.tar.xz"
cd "qtshadertools-everywhere-src-${QT_VERSION}"
rm -rf build && mkdir build && cd build
CXXFLAGS="-include cstdint" cmake .. \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DQT_BUILD_TESTS=OFF \
    -DQT_BUILD_EXAMPLES=OFF
cmake --build . -j14
cmake --install .

# Remaining Qt modules
for mod in declarative wayland svg tools qt5compat imageformats multimedia speech sensors positioning websockets location; do
    build_qt_module "$mod"
done

# =============================================================================
# PHASE 4: Non-ECM misc dependencies
# =============================================================================
log "Phase 4: Non-ECM misc deps"

# libogg
log "Building libogg 1.3.5"
cd $SRCDIR
wget -c https://downloads.xiph.org/releases/ogg/libogg-1.3.5.tar.xz
tar xf libogg-1.3.5.tar.xz && cd libogg-1.3.5
./configure --prefix=/usr --disable-static
make $MAKEFLAGS && make install

# libvorbis
log "Building libvorbis 1.3.7"
cd $SRCDIR
wget -c https://downloads.xiph.org/releases/vorbis/libvorbis-1.3.7.tar.xz
tar xf libvorbis-1.3.7.tar.xz && cd libvorbis-1.3.7
./configure --prefix=/usr --disable-static
make $MAKEFLAGS && make install

# duktape (polkit dep)
log "Building duktape 2.7.0"
cd $SRCDIR
wget -c https://duktape.org/duktape-2.7.0.tar.xz
tar xf duktape-2.7.0.tar.xz && cd duktape-2.7.0
make -f Makefile.sharedlibrary INSTALL_PREFIX=/usr
make -f Makefile.sharedlibrary install INSTALL_PREFIX=/usr

# polkit 126
log "Building polkit 126"
cd $SRCDIR
wget -c https://gitlab.freedesktop.org/polkit/polkit/-/archive/126/polkit-126.tar.gz
tar xf polkit-126.tar.gz && cd polkit-126
rm -rf build
meson setup build \
    --prefix=/usr --libdir=lib \
    -Dsession_tracking=logind \
    -Dman=false -Dintrospection=false \
    -Dtests=false -Dexamples=false \
    -Djs_engine=duktape
ninja -C build -j14
ninja -C build install

# docbook xml + xsl
log "Installing DocBook XML 4.5"
install -dm755 /usr/share/xml/docbook/xml-dtd-4.5
cd $SRCDIR
wget -c https://www.docbook.org/xml/4.5/docbook-xml-4.5.zip
unzip -o docbook-xml-4.5.zip -d /usr/share/xml/docbook/xml-dtd-4.5

log "Installing DocBook XSL 1.79.2"
cd $SRCDIR
wget -c https://prdownloads.sourceforge.net/docbook/docbook-xsl-nons-1.79.2.tar.bz2
tar xf docbook-xsl-nons-1.79.2.tar.bz2
install -dm755 /usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2
cp -R docbook-xsl-nons-1.79.2/* /usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2/

# libxslt
log "Building libxslt 1.1.42"
cd $SRCDIR
wget -c https://download.gnome.org/sources/libxslt/1.1/libxslt-1.1.42.tar.xz
tar xf libxslt-1.1.42.tar.xz && cd libxslt-1.1.42
./configure --prefix=/usr --disable-static --without-python
make $MAKEFLAGS && make install

# =============================================================================
# PHASE 5: ECM — HARD WALL — everything KDE goes after this
# =============================================================================
log "Phase 5: ECM 6.24.0"
cd $SRCDIR
wget -c https://download.kde.org/stable/frameworks/6.24/extra-cmake-modules-6.24.0.tar.xz
tar xf extra-cmake-modules-6.24.0.tar.xz
cd extra-cmake-modules-6.24.0
rm -rf build && mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTING=OFF
cmake --build . -j14 && cmake --install .

# =============================================================================
# PHASE 6: plasma-wayland-protocols (needs ECM)
# =============================================================================
log "Phase 6: plasma-wayland-protocols 1.20.0"
cd $SRCDIR
wget -c https://download.kde.org/stable/plasma/6.4.0/plasma-wayland-protocols-1.20.0.tar.xz
tar xf plasma-wayland-protocols-1.20.0.tar.xz
cd plasma-wayland-protocols-1.20.0
rm -rf build && mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_BUILD_TYPE=Release
cmake --build . -j14 && cmake --install .

# =============================================================================
# PHASE 7: ECM-dependent misc deps (Phonon, QCoro, polkit-qt-1)
# =============================================================================
log "Phase 7: Phonon, QCoro, polkit-qt-1"

log "Building Phonon 4.12.0"
cd $SRCDIR
wget -c https://download.kde.org/stable/phonon/4.12.0/phonon-4.12.0.tar.xz
tar xf phonon-4.12.0.tar.xz && cd phonon-4.12.0
rm -rf build && mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DPHONON_BUILD_QT6=ON \
    -DPHONON_BUILD_QT5=OFF
cmake --build . -j14 && cmake --install .

log "Building QCoro 0.12.0"
cd $SRCDIR
wget -c https://github.com/danvratil/qcoro/archive/refs/tags/v0.12.0.tar.gz -O qcoro-0.12.0.tar.gz
tar xf qcoro-0.12.0.tar.gz && cd qcoro-0.12.0
rm -rf build && mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DQCORO_BUILD_EXAMPLES=OFF \
    -DBUILD_TESTING=OFF
cmake --build . -j14 && cmake --install .

log "Building polkit-qt-1 (git master)"
cd $SRCDIR
[ -d polkit-qt-1 ] && rm -rf polkit-qt-1
git clone --depth=1 https://invent.kde.org/libraries/polkit-qt-1.git
cd polkit-qt-1
rm -rf build && mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DQT_MAJOR_VERSION=6
cmake --build . -j14 && cmake --install .

# =============================================================================
# PHASE 8: KDE Frameworks 6.24.0
# Build order is critical — do not reorder
# =============================================================================
log "Phase 8: KDE Frameworks 6.24.0"

KF_VER=6.24.0
KF_BASE=https://download.kde.org/stable/frameworks/6.24

build_kf() {
    local name=$1
    shift
    local extra_flags="$*"
    log "Building $name $KF_VER"
    cd $SRCDIR
    wget -c "${KF_BASE}/${name}-${KF_VER}.tar.xz"
    tar xf "${name}-${KF_VER}.tar.xz"
    cd "${name}-${KF_VER}"
    rm -rf build && mkdir build && cd build
    cmake .. \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_TESTING=OFF \
        -DBUILD_PYTHON_BINDINGS=OFF \
        $extra_flags
    cmake --build . -j14 && cmake --install .
}

# Tier 1 — no KF deps
build_kf extra-cmake-modules  # already done but harmless
build_kf kcoreaddons
build_kf kguiaddons           -DUSE_DBUS=OFF
build_kf kwidgetsaddons
build_kf kwindowsystem
build_kf karchive
build_kf kcodecs
build_kf kconfig
build_kf ki18n
build_kf kdbusaddons
build_kf kauth
build_kf kcolorscheme

# Tier 2
build_kf kconfigwidgets
build_kf kitemviews
build_kf kcompletion
build_kf kcrash
build_kf kjobwidgets
build_kf kglobalaccel
build_kf knotifications
build_kf sonnet
build_kf kidletime
build_kf kservice
build_kf kpackage
build_kf kio
build_kf solid

# Tier 3
build_kf ktextwidgets
build_kf kxmlgui
build_kf kbookmarks
build_kf kwallet      -DBUILD_KWALLETD=OFF -DBUILD_KSECRETD=OFF -DBUILD_KWALLET_QUERY=OFF
build_kf kparts

# Tier 4
build_kf kiconthemes
build_kf kdoctools   # must precede kio if rebuilding
build_kf kunitconversion
build_kf attica
build_kf knewstuff

# Plasma-specific
build_kf ksvg
build_kf kirigami
build_kf syntax-highlighting
build_kf ktexteditor
build_kf prison       -DWITH_DMTX=OFF -DWITH_ZXING=OFF
build_kf knotifyconfig
build_kf krunner
build_kf kitemmodels
build_kf kcmutils
build_kf kdeclarative
build_kf kstatusnotifieritem
build_kf kpipewire

# =============================================================================
# PHASE 9: Plasma 6.4.0
# =============================================================================
log "Phase 9: Plasma 6.4.0"

PL_VER=6.4.0
PL_BASE=https://download.kde.org/stable/plasma/${PL_VER}

build_plasma() {
    local name=$1
    shift
    local extra_flags="$*"
    log "Building $name $PL_VER"
    cd $SRCDIR
    wget -c "${PL_BASE}/${name}-${PL_VER}.tar.xz"
    tar xf "${name}-${PL_VER}.tar.xz"
    cd "${name}-${PL_VER}"
    rm -rf build && mkdir build && cd build
    cmake .. \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_TESTING=OFF \
        -DBUILD_PYTHON_BINDINGS=OFF \
        $extra_flags
    cmake --build . -j14 && cmake --install .
}

build_plasma kdecoration
build_plasma libkscreen
build_plasma libksysguard
build_plasma kglobalacceld
build_plasma kwayland
build_plasma layer-shell-qt
build_plasma plasma-activities
build_plasma plasma-activities-stats
build_plasma plasma5support
build_plasma libplasma
build_plasma kscreenlocker

# KWin 6.4.0 — GCC 15 patch required
log "Building KWin 6.4.0"
cd $SRCDIR
wget -c "${PL_BASE}/kwin-${PL_VER}.tar.xz"
tar xf "kwin-${PL_VER}.tar.xz"
cd "kwin-${PL_VER}"
# GCC 15: add QVariant include to xdgsession_v1.h
sed -i '/#include <memory>/a #include <QVariant>' src/wayland/xdgsession_v1.h
rm -rf build && mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTING=OFF
cmake --build . -j14 && cmake --install .

build_plasma plasma-workspace
build_plasma plasma-desktop
# NOTE: baloo excluded — GCC 15 breaks QString::arg 6-argument overload
# File indexer is not critical for desktop boot

# =============================================================================
# PHASE 10: Display Manager — greetd + tuigreet
# REPLACES SDDM — SDDM is permanently unsuitable for LFS Wayland sessions
#
# Failure history:
#   - SDDM 0.20.0: D-Bus XML bug with Qt6 (use git master only)
#   - SDDM git: no mouse input (sddm user not in input/seat groups)
#   - SDDM git: startplasma-wayland exits in <1s (Qt wayland plugin missing dep)
#   - SDDM git: input drops ~75% of keystrokes in greeter
#
# greetd is the correct architecture for LFS: minimal, composable,
# no assumptions about session manager state beyond what's in the config.
# =============================================================================
log "Phase 10: greetd + tuigreet"

# greetd (Rust)
log "Building greetd"
cd $SRCDIR
wget -c https://git.sr.ht/~kennylevinsen/greetd/archive/0.10.3.tar.gz -O greetd-0.10.3.tar.gz
tar xf greetd-0.10.3.tar.gz && cd greetd-0.10.3
cargo build --release
install -Dm755 target/release/greetd /usr/sbin/greetd
install -Dm755 target/release/agreety /usr/bin/agreety

# tuigreet (Rust) — TUI greeter
log "Building tuigreet"
cd $SRCDIR
wget -c https://github.com/apognu/tuigreet/releases/download/0.9.1/tuigreet-0.9.1-x86_64.tar.gz
tar xf tuigreet-0.9.1-x86_64.tar.gz
install -Dm755 tuigreet /usr/bin/tuigreet

# greetd PAM config
cat > /etc/pam.d/greetd << 'PAMEOF'
auth       include      system-auth
account    include      system-account
password   include      system-password
session    include      system-session
PAMEOF

# greetd config
useradd -r -s /sbin/nologin -d /var/lib/greeter greeter 2>/dev/null || true
install -dm755 /var/lib/greeter
install -dm755 /etc/greetd

cat > /etc/greetd/config.toml << 'GREETEOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --cmd startplasma-wayland --remember --time --greeting 'SableLinux'"
user = "greeter"
GREETEOF

# greetd systemd service
cat > /usr/lib/systemd/system/greetd.service << 'SVCEOF'
[Unit]
Description=greetd greeter daemon
After=systemd-user-sessions.service

[Service]
Type=idle
ExecStart=/usr/sbin/greetd
Restart=always
StandardInput=tty
StandardOutput=tty
UtmpIdentifier=greetd
TTYPath=/dev/tty1
TTYReset=true
TTYVHangup=true
EnvironmentFile=-/etc/environment

[Install]
Alias=display-manager.service
WantedBy=graphical.target
SVCEOF

systemctl disable sddm 2>/dev/null || true
systemctl enable greetd

# =============================================================================
# PHASE 11: Post-install configuration
# =============================================================================
log "Phase 11: Post-install configuration"

# Remove FONT= from vconsole.conf — missing font will hang boot
sed -i '/^FONT=/d' /etc/vconsole.conf

# Plasma Wayland session file
cat > /usr/share/wayland-sessions/plasmawayland.desktop << 'EOF'
[Desktop Entry]
Name=KDE Plasma (Wayland)
Comment=KDE Plasma desktop environment (Wayland)
Exec=startplasma-wayland
TryExec=startplasma-wayland
Type=Application
DesktopNames=KDE
EOF

# Environment
grep -q 'XCURSOR_THEME' /etc/environment || echo 'XCURSOR_THEME=breeze' >> /etc/environment

ldconfig

log "==================================================================="
log "KDE Plasma 6.4.0 + greetd installed."
log "Reboot to start greetd."
log "greetd launches tuigreet → startplasma-wayland."
log ""
log "If Plasma session fails, check:"
log "  journalctl -u greetd --no-pager | tail -40"
log "  journalctl --user -b --no-pager | tail -40"
log "  ldd /usr/lib/qt6/plugins/platforms/libqwayland-generic.so | grep 'not found'"
log "==================================================================="
