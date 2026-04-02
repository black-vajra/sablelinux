#!/bin/bash
# SableLinux — KDE Plasma 6 Build Script
# Generated from live build session 2026-04-01
# Target: KDE Plasma 6.3.4 on SableLinux (LFS 12.4-systemd base)
# Compiler: GCC 15.2.0 | Qt: 6.8.2 | KF6: 6.11.0 | Plasma: 6.3.4

set -e

JOBS=14
SOURCES=/sources
QT_VER=6.8.2
KF6_VER=6.11.0
PLASMA_VER=6.3.4

CMAKE_COMMON="-DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF"

log() { echo -e "\n\033[1;35m>>> $1\033[0m\n"; }
die() { echo -e "\n\033[1;31mERROR: $1\033[0m\n"; exit 1; }

cd $SOURCES

# ============================================================
# PHASE 1: XCB DEPENDENCIES
# Required for Qt6 xcb platform plugin
# ============================================================

log "Building xcb-util"
wget -nc https://xcb.freedesktop.org/dist/xcb-util-0.4.1.tar.xz
tar xf xcb-util-0.4.1.tar.xz && cd xcb-util-0.4.1
./configure --prefix=/usr --disable-static && make -j$JOBS && sudo make install
cd $SOURCES

log "Building xcb-util-image"
wget -nc https://xcb.freedesktop.org/dist/xcb-util-image-0.4.1.tar.xz
tar xf xcb-util-image-0.4.1.tar.xz && cd xcb-util-image-0.4.1
sudo chown -R $(whoami) .
./configure --prefix=/usr --disable-static && make -j$JOBS && sudo make install
cd $SOURCES

log "Building xcb-util-renderutil"
wget -nc https://xcb.freedesktop.org/dist/xcb-util-renderutil-0.3.10.tar.xz
tar xf xcb-util-renderutil-0.3.10.tar.xz && cd xcb-util-renderutil-0.3.10
./configure --prefix=/usr --disable-static && make -j$JOBS && sudo make install
cd $SOURCES

log "Building xcb-util-wm"
wget -nc https://xcb.freedesktop.org/dist/xcb-util-wm-0.4.2.tar.xz
tar xf xcb-util-wm-0.4.2.tar.xz && cd xcb-util-wm-0.4.2
sudo chown -R $(whoami) .
./configure --prefix=/usr --disable-static && make -j$JOBS && sudo make install
cd $SOURCES

log "Building xcb-util-keysyms"
wget -nc https://xcb.freedesktop.org/dist/xcb-util-keysyms-0.4.1.tar.xz
tar xf xcb-util-keysyms-0.4.1.tar.xz && cd xcb-util-keysyms-0.4.1
./configure --prefix=/usr --disable-static && make -j$JOBS && sudo make install
cd $SOURCES

log "Building xcb-util-cursor"
wget -nc https://xcb.freedesktop.org/dist/xcb-util-cursor-0.1.4.tar.xz
tar xf xcb-util-cursor-0.1.4.tar.xz && cd xcb-util-cursor-0.1.4
./configure --prefix=/usr --disable-static && make -j$JOBS && sudo make install
cd $SOURCES

# ============================================================
# PHASE 2: Qt6 MODULES
# NOTE: qtbase must be built with xcb AFTER xcb-util-* are installed
# GCC 15 fix: -DCMAKE_CXX_FLAGS="-include cstdint" for qtshadertools
# Use /usr/bin/qt-cmake (not cmake) for all Qt modules after qtbase
# ============================================================

log "Building Qt6 base (with xcb support)"
wget -nc https://download.qt.io/official_releases/qt/6.8/$QT_VER/submodules/qtbase-everywhere-src-$QT_VER.tar.xz
tar xf qtbase-everywhere-src-$QT_VER.tar.xz && cd qtbase-everywhere-src-$QT_VER
rm -rf build && mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DQT_BUILD_TESTS=OFF \
    -DQT_BUILD_EXAMPLES=OFF \
    -DFEATURE_dbus=ON \
    -DFEATURE_openssl=ON \
    -DFEATURE_xcb=ON \
    -DFEATURE_xcb_xlib=ON \
    -DFEATURE_system_harfbuzz=ON \
    -DFEATURE_system_freetype=ON \
    -DFEATURE_system_zlib=ON
cmake --build . --parallel $JOBS && sudo cmake --install .
cd $SOURCES

log "Building qtshadertools (GCC 15: needs -include cstdint)"
wget -nc https://download.qt.io/official_releases/qt/6.8/$QT_VER/submodules/qtshadertools-everywhere-src-$QT_VER.tar.xz
tar xf qtshadertools-everywhere-src-$QT_VER.tar.xz && cd qtshadertools-everywhere-src-$QT_VER
rm -rf build && mkdir build && cd build
/usr/bin/qt-cmake .. -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_FLAGS="-include cstdint"
cmake --build . --parallel $JOBS && sudo cmake --install .
cd $SOURCES

for mod in qtdeclarative qtwayland qtsvg qttools qt5compat qtimageformats qtmultimedia qtspeech qtsensors qtpositioning qtwebsockets; do
    log "Building $mod"
    wget -nc https://download.qt.io/official_releases/qt/6.8/$QT_VER/submodules/${mod}-everywhere-src-$QT_VER.tar.xz
    tar xf ${mod}-everywhere-src-$QT_VER.tar.xz && cd ${mod}-everywhere-src-$QT_VER
    rm -rf build && mkdir build && cd build
    /usr/bin/qt-cmake .. -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release \
        -DQT_BUILD_TESTS=OFF -DQT_BUILD_EXAMPLES=OFF \
        -DCMAKE_CXX_FLAGS="-include cstdint"
    cmake --build . --parallel $JOBS && sudo cmake --install .
    cd $SOURCES
done

# ============================================================
# PHASE 3: MISC DEPENDENCIES
# ============================================================

log "Building libogg"
wget -nc https://downloads.xiph.org/releases/ogg/libogg-1.3.5.tar.xz
tar xf libogg-1.3.5.tar.xz && cd libogg-1.3.5
./configure --prefix=/usr --disable-static && make -j$JOBS && sudo make install
cd $SOURCES

log "Building libvorbis"
wget -nc https://downloads.xiph.org/releases/vorbis/libvorbis-1.3.7.tar.xz
tar xf libvorbis-1.3.7.tar.xz && cd libvorbis-1.3.7
./configure --prefix=/usr --disable-static && make -j$JOBS && sudo make install
cd $SOURCES

log "Building libcanberra"
wget -nc http://0pointer.de/lennart/projects/libcanberra/libcanberra-0.30.tar.xz
tar xf libcanberra-0.30.tar.xz && cd libcanberra-0.30
./configure --prefix=/usr --disable-static --enable-pulse --disable-oss
make -j$JOBS && sudo make install
cd $SOURCES

log "Building hunspell (spellcheck backend for Sonnet)"
wget -nc https://github.com/hunspell/hunspell/releases/download/v1.7.2/hunspell-1.7.2.tar.gz
tar xf hunspell-1.7.2.tar.gz && cd hunspell-1.7.2
autoreconf -fi && ./configure --prefix=/usr --disable-static
make -j$JOBS && sudo make install
cd $SOURCES

log "Building lmdb (Baloo database backend)"
wget -nc https://github.com/LMDB/lmdb/archive/LMDB_0.9.32.tar.gz
tar xf LMDB_0.9.32.tar.gz && cd lmdb-LMDB_0.9.32/libraries/liblmdb
make -j$JOBS && sudo make install prefix=/usr
cd $SOURCES

log "Building boost headers"
wget -nc https://archives.boost.io/release/1.87.0/source/boost_1_87_0.tar.bz2
tar xf boost_1_87_0.tar.bz2 && cd boost_1_87_0
./bootstrap.sh --prefix=/usr && sudo ./b2 install --with-headers
cd $SOURCES

log "Building lcms2 (color management for KWin)"
wget -nc https://github.com/mm2/Little-CMS/releases/download/lcms2.16/lcms2-2.16.tar.gz
tar xf lcms2-2.16.tar.gz && cd lcms2-2.16
./configure --prefix=/usr --disable-static && make -j$JOBS && sudo make install
cd $SOURCES

log "Building libei (input emulation for KWin)"
wget -nc https://gitlab.freedesktop.org/libinput/libei/-/archive/1.3.0/libei-1.3.0.tar.gz
tar xf libei-1.3.0.tar.gz && cd libei-1.3.0
mkdir -p build && cd build
meson setup .. --prefix=/usr --libdir=lib --buildtype=release
ninja && sudo ninja install
cd $SOURCES

log "Building libgudev"
wget -nc https://download.gnome.org/sources/libgudev/238/libgudev-238.tar.xz
tar xf libgudev-238.tar.xz && cd libgudev-238
meson setup build --prefix=/usr --libdir=lib --buildtype=release
ninja -C build && sudo ninja -C build install
cd $SOURCES

log "Building libwacom"
wget -nc https://github.com/linuxwacom/libwacom/releases/download/libwacom-2.12.2/libwacom-2.12.2.tar.xz
tar xf libwacom-2.12.2.tar.xz && cd libwacom-2.12.2
meson setup build --prefix=/usr --libdir=lib --buildtype=release -Dtests=disabled
ninja -C build && sudo ninja -C build install
cd $SOURCES

log "Building lm-sensors"
wget -nc https://github.com/lm-sensors/lm-sensors/archive/refs/tags/V3-6-0.tar.gz
tar xf V3-6-0.tar.gz && cd lm-sensors-3-6-0
make -j$JOBS && sudo make install PREFIX=/usr
cd $SOURCES

log "Building ICU"
wget -nc https://github.com/unicode-org/icu/releases/download/release-76-1/icu4c-76_1-src.tgz
tar xf icu4c-76_1-src.tgz && cd icu/source
./configure --prefix=/usr && make -j$JOBS && sudo make install
cd $SOURCES

log "Building libqalculate"
wget -nc https://github.com/Qalculate/libqalculate/releases/download/v5.5.0/libqalculate-5.5.0.tar.gz
tar xf libqalculate-5.5.0.tar.gz && cd libqalculate-5.5.0
./configure --prefix=/usr --disable-static && make -j$JOBS && sudo make install
cd $SOURCES

log "Building libpulse-mainloop-glib (for Phonon)"
# Rebuild pulseaudio client libs with GLib mainloop support
# NOTE: pulseaudio 17.0 source must already be present in /sources
cd pulseaudio-17.0
cp /sources/pulseaudio-17.0/src/pulse/glib-mainloop.h /usr/include/pulse/ 2>/dev/null || true
meson setup build-glib --prefix=/usr --libdir=lib \
    -Ddaemon=false -Dglib=enabled -Dtests=false -Ddoxygen=false --reconfigure 2>/dev/null || \
meson setup build-glib --prefix=/usr --libdir=lib \
    -Ddaemon=false -Dglib=enabled -Dtests=false -Ddoxygen=false
ninja -C build-glib && sudo ninja -C build-glib install
# Manual install of mainloop-glib if ninja didn't install it
sudo cp build-glib/src/pulse/libpulse-mainloop-glib.so* /usr/lib/ 2>/dev/null || true
sudo cp build-glib/libpulse-mainloop-glib.pc /usr/lib/pkgconfig/ 2>/dev/null || true
sudo cp src/pulse/glib-mainloop.h /usr/include/pulse/
sudo ldconfig
cd $SOURCES

log "Building Phonon (Qt6)"
wget -nc https://download.kde.org/stable/phonon/4.12.0/phonon-4.12.0.tar.xz
tar xf phonon-4.12.0.tar.xz && cd phonon-4.12.0
rm -rf build && mkdir build && cd build
cmake .. $CMAKE_COMMON -DPHONON_BUILD_QT5=OFF -DPHONON_BUILD_QT6=ON
make -j$JOBS && sudo make install
cd $SOURCES

log "Building QCoro"
wget -nc https://github.com/qcoro/qcoro/archive/refs/tags/v0.12.0.tar.gz -O qcoro-0.12.0.tar.gz
tar xf qcoro-0.12.0.tar.gz && cd qcoro-0.12.0
rm -rf build && mkdir build && cd build
cmake .. $CMAKE_COMMON -DBUILD_SHARED_LIBS=ON
make -j$JOBS && sudo make install
cd $SOURCES

log "Building qrencode"
wget -nc https://github.com/fukuchi/libqrencode/archive/v4.1.1.tar.gz -O qrencode-4.1.1.tar.gz
tar xf qrencode-4.1.1.tar.gz && cd libqrencode-4.1.1
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib \
    -DWITH_TOOLS=OFF -DCMAKE_C_FLAGS="-fPIC" -DBUILD_SHARED_LIBS=ON .
make -j$JOBS && sudo make install
cd $SOURCES

log "Creating polkitd user"
sudo groupadd -fg 27 polkitd 2>/dev/null || true
sudo useradd -c "PolicyKit Daemon Owner" -d /etc/polkit-1 -u 27 \
    -g polkitd -s /bin/false polkitd 2>/dev/null || true

log "Building duktape (polkit JS engine)"
wget -nc https://duktape.org/duktape-2.7.0.tar.xz
tar xf duktape-2.7.0.tar.xz && cd duktape-2.7.0
make -f Makefile.sharedlibrary && sudo make -f Makefile.sharedlibrary install INSTALL_PREFIX=/usr
cd $SOURCES

log "Building polkit 126"
wget -nc https://github.com/polkit-org/polkit/archive/126/polkit-126.tar.gz
tar xf polkit-126.tar.gz && cd polkit-126
mkdir -p build && cd build
meson setup .. --prefix=/usr --libdir=lib --buildtype=release \
    -Dman=false -Dtests=false -Dintrospection=false \
    -Dsession_tracking=logind -Dos_type=lfs
ninja && sudo ninja install
cd $SOURCES

log "Building polkit-qt-1 (Qt6, from git)"
[ -d polkit-qt-1 ] || git clone https://github.com/KDE/polkit-qt-1.git
cd polkit-qt-1
rm -rf build && mkdir build && cd build
cmake .. $CMAKE_COMMON -DQT_MAJOR_VERSION=6
make -j$JOBS && sudo make install
cd $SOURCES

log "Installing Perl URI::Escape (for kdoctools)"
sudo cpan URI::Escape

log "Building DocBook XML and XSL"
wget -nc http://www.oasis-open.org/docbook/xml/4.5/docbook-xml-4.5.zip
python3 -c "import zipfile; zipfile.ZipFile('docbook-xml-4.5.zip').extractall('docbook-xml-4.5')"
sudo mkdir -p /usr/share/xml/docbook/xml-dtd-4.5
sudo cp -r docbook-xml-4.5/* /usr/share/xml/docbook/xml-dtd-4.5/

wget -nc https://github.com/docbook/xslt10-stylesheets/releases/download/release/1.79.2/docbook-xsl-nons-1.79.2.tar.bz2
tar xf docbook-xsl-nons-1.79.2.tar.bz2
sudo mkdir -p /usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2
sudo cp -r docbook-xsl-nons-1.79.2/* /usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2/

log "Building libxslt"
wget -nc https://download.gnome.org/sources/libxslt/1.1/libxslt-1.1.42.tar.xz
tar xf libxslt-1.1.42.tar.xz && cd libxslt-1.1.42
./configure --prefix=/usr --disable-static && make -j$JOBS && sudo make install
cd $SOURCES

# ============================================================
# PHASE 4: EXTRA CMAKE MODULES
# ============================================================

log "Building Extra CMake Modules"
wget -nc https://download.kde.org/stable/frameworks/$KF6_VER/extra-cmake-modules-$KF6_VER.tar.xz
tar xf extra-cmake-modules-$KF6_VER.tar.xz && cd extra-cmake-modules-$KF6_VER
mkdir -p build && cd build
cmake .. $CMAKE_COMMON && make -j$JOBS && sudo make install
cd $SOURCES

# ============================================================
# PHASE 5: KDE FRAMEWORKS 6
# Build order matters — dependencies must precede dependents
# ============================================================

kf6_build() {
    local pkg=$1
    local extra="${2:-}"
    log "Building KF6: $pkg"
    wget -nc https://download.kde.org/stable/frameworks/$KF6_VER/${pkg}-$KF6_VER.tar.xz
    tar xf ${pkg}-$KF6_VER.tar.xz && cd ${pkg}-$KF6_VER
    rm -rf build && mkdir build && cd build
    cmake .. $CMAKE_COMMON $extra
    make -j$JOBS && sudo make install
    cd $SOURCES
}

kf6_build kcoreaddons
kf6_build kconfig
kf6_build karchive
kf6_build kdbusaddons
kf6_build kwindowsystem
kf6_build kcrash
kf6_build kguiaddons
kf6_build ki18n
kf6_build kitemviews
kf6_build kcodecs
kf6_build kwidgetsaddons
kf6_build kcolorscheme
kf6_build kconfigwidgets
kf6_build kservice
kf6_build breeze-icons
kf6_build kiconthemes
kf6_build knotifications
kf6_build kglobalaccel
kf6_build kpackage
kf6_build kdeclarative
kf6_build solid
kf6_build kbookmarks
kf6_build kjobwidgets
kf6_build kauth
kf6_build kio
kf6_build attica
kf6_build knewstuff
kf6_build kxmlgui
kf6_build kparts
kf6_build kitemmodels
kf6_build krunner
kf6_build sonnet
kf6_build ktextwidgets
kf6_build kstatusnotifieritem
kf6_build kidletime
kf6_build kfilemetadata
kf6_build baloo
kf6_build ksvg
kf6_build kirigami
kf6_build kcmutils
kf6_build kded
kf6_build knotifyconfig

# kwallet: build without daemon (avoids gpgme/qca deps)
log "Building KF6: kwallet (daemon disabled)"
wget -nc https://download.kde.org/stable/frameworks/$KF6_VER/kwallet-$KF6_VER.tar.xz
tar xf kwallet-$KF6_VER.tar.xz && cd kwallet-$KF6_VER
rm -rf build && mkdir build && cd build
cmake .. $CMAKE_COMMON -DBUILD_KWALLETD=OFF
make -j$JOBS && sudo make install
cd $SOURCES

kf6_build kholidays
kf6_build kuserfeedback
kf6_build kunitconversion
kf6_build ktexteditor   # requires syntax-highlighting first
kf6_build syntax-highlighting

# Rebuild ktexteditor after syntax-highlighting
log "Rebuilding ktexteditor after syntax-highlighting"
cd ktexteditor-$KF6_VER && rm -rf build && mkdir build && cd build
cmake .. $CMAKE_COMMON && make -j$JOBS && sudo make install
cd $SOURCES

# prison: requires qrencode with -fPIC
kf6_build prison

log "Building KF6: kdoctools (requires DocBook + libxslt + URI::Escape)"
wget -nc https://download.kde.org/stable/frameworks/$KF6_VER/kdoctools-$KF6_VER.tar.xz
tar xf kdoctools-$KF6_VER.tar.xz && cd kdoctools-$KF6_VER
rm -rf build && mkdir build && cd build
cmake .. $CMAKE_COMMON && make -j$JOBS && sudo make install
cd $SOURCES

# ============================================================
# PHASE 6: PLASMA WAYLAND PROTOCOLS
# ============================================================

log "Building plasma-wayland-protocols"
wget -nc https://download.kde.org/stable/plasma-wayland-protocols/plasma-wayland-protocols-1.16.0.tar.xz
tar xf plasma-wayland-protocols-1.16.0.tar.xz && cd plasma-wayland-protocols-1.16.0
mkdir -p build && cd build
cmake .. $CMAKE_COMMON && make -j$JOBS && sudo make install
cd $SOURCES

# ============================================================
# PHASE 7: PLASMA PACKAGES
# ============================================================

plasma_build() {
    local pkg=$1
    local extra="${2:-}"
    log "Building Plasma: $pkg"
    wget -nc https://download.kde.org/stable/plasma/$PLASMA_VER/${pkg}-$PLASMA_VER.tar.xz
    tar xf ${pkg}-$PLASMA_VER.tar.xz && cd ${pkg}-$PLASMA_VER
    rm -rf build && mkdir build && cd build
    cmake .. $CMAKE_COMMON $extra
    make -j$JOBS && sudo make install
    cd $SOURCES
}

plasma_build kdecoration
plasma_build libkscreen
plasma_build libksysguard
plasma_build kglobalacceld
plasma_build kwayland
plasma_build layer-shell-qt
plasma_build plasma-activities
plasma_build plasma-activities-stats
plasma_build plasma5support
plasma_build libplasma
plasma_build kscreenlocker

log "Building KWin"
wget -nc https://download.kde.org/stable/plasma/$PLASMA_VER/kwin-$PLASMA_VER.tar.xz
tar xf kwin-$PLASMA_VER.tar.xz && cd kwin-$PLASMA_VER
rm -rf build && mkdir build && cd build
cmake .. $CMAKE_COMMON
make -j$JOBS && sudo make install
cd $SOURCES

log "Building plasma-workspace"
wget -nc https://download.kde.org/stable/plasma/$PLASMA_VER/plasma-workspace-$PLASMA_VER.tar.xz
tar xf plasma-workspace-$PLASMA_VER.tar.xz && cd plasma-workspace-$PLASMA_VER
rm -rf build && mkdir build && cd build
cmake .. $CMAKE_COMMON
make -j$JOBS && sudo make install
cd $SOURCES

log "Building plasma-desktop"
wget -nc https://download.kde.org/stable/plasma/$PLASMA_VER/plasma-desktop-$PLASMA_VER.tar.xz
tar xf plasma-desktop-$PLASMA_VER.tar.xz && cd plasma-desktop-$PLASMA_VER
rm -rf build && mkdir build && cd build
cmake .. $CMAKE_COMMON -DBUILD_KCM_MOUSE_X11=OFF -DBUILD_KCM_TOUCHPAD_X11=OFF
make -j$JOBS && sudo make install
cd $SOURCES

# ============================================================
# PHASE 8: SDDM
# NOTE: Use git master — 0.20.0 has D-Bus XML bug with Qt6
# ============================================================

log "Creating sddm user"
sudo useradd -r -s /bin/false -d /var/lib/sddm -M -c "SDDM Daemon" sddm 2>/dev/null || true
sudo mkdir -p /var/lib/sddm
sudo chown sddm:sddm /var/lib/sddm
sudo chmod 700 /var/lib/sddm

log "Building SDDM (git master)"
[ -d sddm-git ] || git clone --depth=1 https://github.com/sddm/sddm.git sddm-git
cd sddm-git
rm -rf build && mkdir build && cd build
# BUILD_WITH_QT6=ON is the correct flag (not QT_MAJOR_VERSION)
cmake .. $CMAKE_COMMON -DBUILD_MAN_PAGES=OFF -DBUILD_WITH_QT6=ON
make -j$JOBS && sudo make install
cd $SOURCES

log "Enabling SDDM service"
sudo systemctl enable sddm

# ============================================================
# PHASE 9: SESSION FILES
# ============================================================

log "Creating Plasma Wayland session file"
sudo bash -c 'cat > /usr/share/wayland-sessions/plasma.desktop << EOF
[Desktop Entry]
Name=KDE Plasma
Comment=KDE Plasma Desktop Environment
Exec=/usr/bin/startplasma-wayland
TryExec=/usr/bin/startplasma-wayland
Type=Application
DesktopNames=KDE
Keywords=wayland;
EOF'

log "Done! KDE Plasma 6 + SDDM installed."
log "Reboot to start SDDM and select Plasma or Sway at login."
