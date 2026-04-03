#!/bin/bash
# SableLinux — KDE Plasma 6 Full Build Script v3
# =============================================================================
# Qt: 6.8.2 | KF6: 6.24.0 | Plasma: 6.4.0
# wayland-protocols: 1.48 | plasma-wayland-protocols: 1.20.0
# Compiler: GCC 15.2.0
#
# PHASE ORDER (critical — do not reorder phases):
#   1. XCB utilities
#   2. wayland-protocols 1.48        (meson, no ECM needed)
#   3. Qt6 modules                   (needs XCB)
#   4. Non-ECM misc deps             (libogg, polkit, docbook, etc.)
#   5. ECM                           (must precede everything KDE)
#   6. plasma-wayland-protocols 1.20 (needs ECM)
#   7. ECM-dependent misc            (Phonon, QCoro — need ECM)
#   8. KDE Frameworks 6.24.0         (correct dependency order)
#   9. Plasma 6.4.0 packages
#  10. SDDM
#  11. Post-install configuration
#
# ALL FIXES vs original script:
#   - plasma-wayland-protocols moved to Phase 6 (after ECM)
#   - ECM moved to Phase 5 (before Phonon, QCoro, all KF6)
#   - Phonon, QCoro moved to Phase 7 (after ECM)
#   - Qt6Location added to Qt modules
#   - KF6 6.24.0: -DBUILD_PYTHON_BINDINGS=OFF globally
#   - kguiaddons: -DUSE_DBUS=OFF
#   - kcompletion: added (missing from original, needed by kio)
#   - kdoctools: moved before kio
#   - kwindowsystem: placed after kguiaddons
#   - kwallet: -DBUILD_KWALLETD=OFF -DBUILD_KSECRETD=OFF -DBUILD_KWALLET_QUERY=OFF
#   - prison: -DWITH_DMTX=OFF -DWITH_ZXING=OFF
#   - syntax-highlighting: built before ktexteditor
#   - kirigami: built before ksvg
#   - KWin: automated GCC 15 patch (xdgsession_v1.h QVariant)
#   - Plasma 6.4.0 (not 6.6.3 which requires Qt 6.10.0)
#   - SDDM PAM: explicit pam_systemd.so for XDG_RUNTIME_DIR
#   - SDDM: tmpfiles.d entry, sddm user in video+input groups
#   - Skip guards on all packages for fast restarts
# =============================================================================

set -e

JOBS=14
SOURCES=/sources
QT_VER=6.8.2
KF6_VER=6.24.0
KF6_DIR=6.24
PLASMA_VER=6.4.0

CMAKE_COMMON="-DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTING=OFF \
    -DBUILD_PYTHON_BINDINGS=OFF"

log()  { echo -e "\n\033[1;35m>>> $*\033[0m\n"; }
skip() { echo -e "\n\033[1;32m--- SKIP: $*\033[0m\n"; }
die()  { echo -e "\n\033[1;31mERROR: $*\033[0m\n"; exit 1; }

has_cmake() { [ -f "/usr/lib/cmake/$1/$1Config.cmake" ] || [ -f "/lib/cmake/$1/$1Config.cmake" ]; }
has_lib()   { ldconfig -p 2>/dev/null | grep -q "$1"; }
has_cmd()   { command -v "$1" &>/dev/null; }
has_pkg()   { pkg-config --exists "$1" 2>/dev/null; }

cd $SOURCES

# =============================================================================
# PHASE 1: XCB UTILITIES
# Required for Qt6 xcb platform plugin
# =============================================================================

xcb_build() {
    local name=$1 lib=$2
    if has_lib "$lib"; then skip "$name"; return; fi
    log "Building $name"
    wget -nc https://xcb.freedesktop.org/dist/${name}.tar.xz
    tar xf ${name}.tar.xz && cd ${name}
    sudo chown -R $(whoami) .
    ./configure --prefix=/usr --disable-static
    make -j$JOBS && sudo make install
    cd $SOURCES
}

xcb_build xcb-util-0.4.1            libxcb-util
xcb_build xcb-util-image-0.4.1      libxcb-image
xcb_build xcb-util-renderutil-0.3.10 libxcb-render-util
xcb_build xcb-util-wm-0.4.2         libxcb-icccm
xcb_build xcb-util-keysyms-0.4.1    libxcb-keysyms
xcb_build xcb-util-cursor-0.1.4     libxcb-cursor

# =============================================================================
# PHASE 2: WAYLAND-PROTOCOLS 1.48
# Uses meson — does NOT need ECM
# Must be 1.48+ for ext-background-effect-v1.xml (kwindowsystem 6.24.0)
# =============================================================================

WP_INSTALLED=$(pkg-config --modversion wayland-protocols 2>/dev/null || echo "0")
if [ "$WP_INSTALLED" != "1.48" ]; then
    log "Building wayland-protocols 1.48"
    wget -nc https://gitlab.freedesktop.org/wayland/wayland-protocols/-/releases/1.48/downloads/wayland-protocols-1.48.tar.xz
    tar xf wayland-protocols-1.48.tar.xz && cd wayland-protocols-1.48
    rm -rf build && mkdir -p build && cd build
    meson setup .. --prefix=/usr --libdir=lib --buildtype=release
    ninja && sudo ninja install
    cd $SOURCES
else
    skip "wayland-protocols 1.48"
fi

# =============================================================================
# PHASE 3: Qt6 MODULES
# qtbase must be built AFTER xcb-util-* packages
# All modules use -include cstdint for GCC 15 compatibility
# qtlocation required by plasma-workspace
# =============================================================================

if ! has_cmake Qt6; then
    log "Building qtbase $QT_VER"
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
else
    skip "qtbase"
fi

qt_module_build() {
    local mod=$1 check=$2
    if [ -f "$check" ]; then skip "$mod"; return; fi
    log "Building $mod $QT_VER"
    wget -nc https://download.qt.io/official_releases/qt/6.8/$QT_VER/submodules/${mod}-everywhere-src-$QT_VER.tar.xz
    tar xf ${mod}-everywhere-src-$QT_VER.tar.xz && cd ${mod}-everywhere-src-$QT_VER
    rm -rf build && mkdir build && cd build
    /usr/bin/qt-cmake .. \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_BUILD_TYPE=Release \
        -DQT_BUILD_TESTS=OFF \
        -DQT_BUILD_EXAMPLES=OFF \
        -DCMAKE_CXX_FLAGS="-include cstdint"
    cmake --build . --parallel $JOBS && sudo cmake --install .
    cd $SOURCES
}

qt_module_build qtshadertools   /usr/lib/libQt6ShaderTools.so
qt_module_build qtdeclarative   /usr/lib/libQt6Qml.so
qt_module_build qtwayland       /usr/lib/libQt6WaylandClient.so
qt_module_build qtsvg           /usr/lib/libQt6Svg.so
qt_module_build qttools         /usr/bin/qhelpgenerator
qt_module_build qt5compat       /usr/lib/libQt6Core5Compat.so
qt_module_build qtimageformats  /usr/plugins/imageformats/libqwebp.so
qt_module_build qtmultimedia    /usr/lib/libQt6Multimedia.so
qt_module_build qtspeech        /usr/lib/libQt6TextToSpeech.so
qt_module_build qtsensors       /usr/lib/libQt6Sensors.so
qt_module_build qtpositioning   /usr/lib/libQt6Positioning.so
qt_module_build qtwebsockets    /usr/lib/libQt6WebSockets.so
qt_module_build qtlocation      /usr/lib/libQt6Location.so

# =============================================================================
# PHASE 4: NON-ECM MISC DEPENDENCIES
# Everything here must NOT require ECM at build time
# =============================================================================

auto_build() {
    local name=$1 url=$2 lib=$3
    if has_lib "$lib"; then skip "$name"; return; fi
    log "Building $name"
    wget -nc $url
    local f=$(basename $url)
    tar xf $f && cd ${f%.tar.*}
    ./configure --prefix=/usr --disable-static
    make -j$JOBS && sudo make install
    cd $SOURCES
}

auto_build libogg-1.3.5 \
    https://downloads.xiph.org/releases/ogg/libogg-1.3.5.tar.xz libogg

auto_build libvorbis-1.3.7 \
    https://downloads.xiph.org/releases/vorbis/libvorbis-1.3.7.tar.xz libvorbis

if ! has_lib libcanberra; then
    log "Building libcanberra 0.30"
    wget -nc http://0pointer.de/lennart/projects/libcanberra/libcanberra-0.30.tar.xz
    tar xf libcanberra-0.30.tar.xz && cd libcanberra-0.30
    ./configure --prefix=/usr --disable-static --enable-pulse --disable-oss
    make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "libcanberra"
fi

if ! has_lib libhunspell; then
    log "Building hunspell 1.7.2"
    wget -nc https://github.com/hunspell/hunspell/releases/download/v1.7.2/hunspell-1.7.2.tar.gz
    tar xf hunspell-1.7.2.tar.gz && cd hunspell-1.7.2
    autoreconf -fi
    ./configure --prefix=/usr --disable-static
    make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "hunspell"
fi

if [ ! -f /usr/lib/liblmdb.so ]; then
    log "Building lmdb 0.9.32"
    wget -nc https://github.com/LMDB/lmdb/archive/LMDB_0.9.32.tar.gz
    tar xf LMDB_0.9.32.tar.gz && cd lmdb-LMDB_0.9.32/libraries/liblmdb
    make -j$JOBS && sudo make install prefix=/usr
    cd $SOURCES
else
    skip "lmdb"
fi

if [ ! -f /usr/include/boost/version.hpp ]; then
    log "Building boost 1.87.0 headers"
    wget -nc https://archives.boost.io/release/1.87.0/source/boost_1_87_0.tar.bz2
    tar xf boost_1_87_0.tar.bz2 && cd boost_1_87_0
    ./bootstrap.sh --prefix=/usr && sudo ./b2 install --with-headers
    cd $SOURCES
else
    skip "boost headers"
fi

if ! has_lib liblcms2; then
    log "Building lcms2 2.16"
    wget -nc https://github.com/mm2/Little-CMS/releases/download/lcms2.16/lcms2-2.16.tar.gz
    tar xf lcms2-2.16.tar.gz && cd lcms2-2.16
    ./configure --prefix=/usr --disable-static
    make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "lcms2"
fi

if ! has_lib libei; then
    log "Building libei 1.3.0"
    wget -nc https://gitlab.freedesktop.org/libinput/libei/-/archive/1.3.0/libei-1.3.0.tar.gz
    tar xf libei-1.3.0.tar.gz && cd libei-1.3.0
    rm -rf build && mkdir -p build && cd build
    meson setup .. --prefix=/usr --libdir=lib --buildtype=release
    ninja && sudo ninja install
    cd $SOURCES
else
    skip "libei"
fi

if ! has_lib libgudev; then
    log "Building libgudev 238"
    wget -nc https://download.gnome.org/sources/libgudev/238/libgudev-238.tar.xz
    tar xf libgudev-238.tar.xz && cd libgudev-238
    rm -rf build
    meson setup build --prefix=/usr --libdir=lib --buildtype=release
    ninja -C build && sudo ninja -C build install
    cd $SOURCES
else
    skip "libgudev"
fi

if ! has_lib libwacom; then
    log "Building libwacom 2.12.2"
    wget -nc https://github.com/linuxwacom/libwacom/releases/download/libwacom-2.12.2/libwacom-2.12.2.tar.xz
    tar xf libwacom-2.12.2.tar.xz && cd libwacom-2.12.2
    rm -rf build
    meson setup build --prefix=/usr --libdir=lib --buildtype=release -Dtests=disabled
    ninja -C build && sudo ninja -C build install
    cd $SOURCES
else
    skip "libwacom"
fi

if ! has_cmd sensors; then
    log "Building lm-sensors 3.6.0"
    wget -nc https://github.com/lm-sensors/lm-sensors/archive/refs/tags/V3-6-0.tar.gz
    tar xf V3-6-0.tar.gz && cd lm-sensors-3-6-0
    make -j$JOBS && sudo make install PREFIX=/usr
    cd $SOURCES
else
    skip "lm-sensors"
fi

if ! has_lib libicuuc; then
    log "Building ICU 76.1"
    wget -nc https://github.com/unicode-org/icu/releases/download/release-76-1/icu4c-76_1-src.tgz
    tar xf icu4c-76_1-src.tgz && cd icu/source
    ./configure --prefix=/usr
    make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "ICU"
fi

if ! has_lib libqalculate; then
    log "Building libqalculate 5.5.0"
    wget -nc https://github.com/Qalculate/libqalculate/releases/download/v5.5.0/libqalculate-5.5.0.tar.gz
    tar xf libqalculate-5.5.0.tar.gz && cd libqalculate-5.5.0
    ./configure --prefix=/usr --disable-static
    make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "libqalculate"
fi

if ! has_lib libpulse-mainloop-glib; then
    log "Building libpulse-mainloop-glib"
    cd $SOURCES/pulseaudio-17.0
    cp src/pulse/glib-mainloop.h /usr/include/pulse/ 2>/dev/null || true
    rm -rf build-glib
    meson setup build-glib --prefix=/usr --libdir=lib \
        -Ddaemon=false -Dglib=enabled -Dtests=false -Ddoxygen=false
    ninja -C build-glib && sudo ninja -C build-glib install
    sudo cp build-glib/src/pulse/libpulse-mainloop-glib.so* /usr/lib/ 2>/dev/null || true
    sudo cp src/pulse/glib-mainloop.h /usr/include/pulse/
    sudo ldconfig
    cd $SOURCES
else
    skip "libpulse-mainloop-glib"
fi

if ! has_lib libqrencode; then
    log "Building qrencode 4.1.1"
    wget -nc https://github.com/fukuchi/libqrencode/archive/v4.1.1.tar.gz -O qrencode-4.1.1.tar.gz
    tar xf qrencode-4.1.1.tar.gz && cd libqrencode-4.1.1
    cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib \
        -DWITH_TOOLS=OFF -DCMAKE_C_FLAGS="-fPIC" -DBUILD_SHARED_LIBS=ON .
    make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "qrencode"
fi

# polkit stack
if ! id polkitd &>/dev/null; then
    sudo groupadd -fg 27 polkitd 2>/dev/null || true
    sudo useradd -c "PolicyKit Daemon Owner" -d /etc/polkit-1 -u 27 \
        -g polkitd -s /bin/false polkitd 2>/dev/null || true
fi

if ! has_lib libduktape; then
    log "Building duktape 2.7.0"
    wget -nc https://duktape.org/duktape-2.7.0.tar.xz
    tar xf duktape-2.7.0.tar.xz && cd duktape-2.7.0
    make -f Makefile.sharedlibrary
    sudo make -f Makefile.sharedlibrary install INSTALL_PREFIX=/usr
    cd $SOURCES
else
    skip "duktape"
fi

if ! has_cmd pkcheck; then
    log "Building polkit 126"
    wget -nc https://github.com/polkit-org/polkit/archive/126/polkit-126.tar.gz
    tar xf polkit-126.tar.gz && cd polkit-126
    rm -rf build && mkdir -p build && cd build
    meson setup .. --prefix=/usr --libdir=lib --buildtype=release \
        -Dman=false -Dtests=false -Dintrospection=false \
        -Dsession_tracking=logind -Dos_type=lfs
    ninja && sudo ninja install
    cd $SOURCES
else
    skip "polkit"
fi

# Perl URI::Escape for kdoctools
if ! perl -MURI::Escape -e 1 2>/dev/null; then
    log "Installing Perl URI::Escape"
    sudo cpan URI::Escape
else
    skip "Perl URI::Escape"
fi

# DocBook XML
if [ ! -d /usr/share/xml/docbook/xml-dtd-4.5 ]; then
    log "Installing DocBook XML 4.5"
    wget -nc http://www.oasis-open.org/docbook/xml/4.5/docbook-xml-4.5.zip
    python3 -c "import zipfile; zipfile.ZipFile('docbook-xml-4.5.zip').extractall('docbook-xml-4.5')"
    sudo mkdir -p /usr/share/xml/docbook/xml-dtd-4.5
    sudo cp -r docbook-xml-4.5/* /usr/share/xml/docbook/xml-dtd-4.5/
else
    skip "DocBook XML"
fi

# DocBook XSL
if [ ! -d /usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2 ]; then
    log "Installing DocBook XSL 1.79.2"
    wget -nc https://github.com/docbook/xslt10-stylesheets/releases/download/release/1.79.2/docbook-xsl-nons-1.79.2.tar.bz2
    tar xf docbook-xsl-nons-1.79.2.tar.bz2
    sudo mkdir -p /usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2
    sudo cp -r docbook-xsl-nons-1.79.2/* /usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2/
else
    skip "DocBook XSL"
fi

if ! has_lib libxslt; then
    log "Building libxslt 1.1.42"
    wget -nc https://download.gnome.org/sources/libxslt/1.1/libxslt-1.1.42.tar.xz
    tar xf libxslt-1.1.42.tar.xz && cd libxslt-1.1.42
    ./configure --prefix=/usr --disable-static
    make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "libxslt"
fi

# =============================================================================
# PHASE 5: EXTRA CMAKE MODULES
# MUST be built before plasma-wayland-protocols, Phonon, QCoro, and ALL KF6
# =============================================================================

if ! has_cmake ECM; then
    log "Building Extra CMake Modules $KF6_VER"
    wget -nc https://download.kde.org/stable/frameworks/$KF6_DIR/extra-cmake-modules-$KF6_VER.tar.xz
    tar xf extra-cmake-modules-$KF6_VER.tar.xz && cd extra-cmake-modules-$KF6_VER
    rm -rf build && mkdir build && cd build
    cmake .. $CMAKE_COMMON
    make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "ECM $KF6_VER"
fi

# =============================================================================
# PHASE 6: PLASMA-WAYLAND-PROTOCOLS 1.20.0
# Needs ECM — must come AFTER Phase 5
# =============================================================================

if [ ! -f /usr/share/plasma-wayland-protocols/plasma-shell.xml ]; then
    log "Building plasma-wayland-protocols 1.20.0"
    wget -nc https://download.kde.org/stable/plasma-wayland-protocols/plasma-wayland-protocols-1.20.0.tar.xz
    tar xf plasma-wayland-protocols-1.20.0.tar.xz && cd plasma-wayland-protocols-1.20.0
    rm -rf build && mkdir -p build && cd build
    cmake .. $CMAKE_COMMON
    make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "plasma-wayland-protocols 1.20.0"
fi

# =============================================================================
# PHASE 7: ECM-DEPENDENT MISC (Phonon, QCoro)
# These need ECM — must come AFTER Phase 5
# =============================================================================

if ! has_cmake phonon4qt6; then
    log "Building Phonon 4.12.0"
    wget -nc https://download.kde.org/stable/phonon/4.12.0/phonon-4.12.0.tar.xz
    tar xf phonon-4.12.0.tar.xz && cd phonon-4.12.0
    rm -rf build && mkdir build && cd build
    cmake .. $CMAKE_COMMON -DPHONON_BUILD_QT5=OFF -DPHONON_BUILD_QT6=ON
    make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "Phonon"
fi

if ! has_cmake QCoro6; then
    log "Building QCoro 0.12.0"
    wget -nc https://github.com/qcoro/qcoro/archive/refs/tags/v0.12.0.tar.gz -O qcoro-0.12.0.tar.gz
    tar xf qcoro-0.12.0.tar.gz && cd qcoro-0.12.0
    rm -rf build && mkdir build && cd build
    cmake .. $CMAKE_COMMON -DBUILD_SHARED_LIBS=ON
    make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "QCoro"
fi

# polkit-qt-1 (needs ECM + polkit + Qt6)
if ! has_cmake PolkitQt6-1; then
    log "Building polkit-qt-1 (Qt6)"
    [ -d polkit-qt-1 ] || git clone https://github.com/KDE/polkit-qt-1.git
    cd polkit-qt-1
    rm -rf build && mkdir build && cd build
    cmake .. $CMAKE_COMMON -DQT_MAJOR_VERSION=6
    make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "polkit-qt-1"
fi

# =============================================================================
# PHASE 8: KDE FRAMEWORKS 6.24.0
# Correct dependency order — do not reorder
# =============================================================================

kf6() {
    local pkg=$1 cmake_name=$2 extra="${3:-}"
    if has_cmake "$cmake_name"; then skip "KF6/$pkg"; return; fi
    log "Building KF6: $pkg $KF6_VER"
    wget -nc https://download.kde.org/stable/frameworks/$KF6_DIR/${pkg}-$KF6_VER.tar.xz
    tar xf ${pkg}-$KF6_VER.tar.xz && cd ${pkg}-$KF6_VER
    rm -rf build && mkdir build && cd build
    cmake .. $CMAKE_COMMON $extra
    make -j$JOBS && sudo make install
    cd $SOURCES
}

# Tier 1 — no KF6 deps
kf6 kcoreaddons    KF6CoreAddons
kf6 kconfig        KF6Config
kf6 karchive       KF6Archive
kf6 kdbusaddons    KF6DBusAddons
kf6 kcrash         KF6Crash
kf6 ki18n          KF6I18n
kf6 kitemviews     KF6ItemViews
kf6 kcodecs        KF6Codecs
kf6 kwidgetsaddons KF6WidgetsAddons
kf6 kitemmodels    KF6ItemModels
kf6 sonnet         KF6Sonnet
kf6 kidletime      KF6IdleTime
kf6 kholidays      KF6Holidays
kf6 kuserfeedback  KF6UserFeedback
kf6 kunitconversion KF6UnitConversion
kf6 solid          KF6Solid
kf6 attica         KF6Attica

# kguiaddons: -DUSE_DBUS=OFF avoids Qt private headers dependency (new in 6.24.0)
kf6 kguiaddons KF6GuiAddons "-DUSE_DBUS=OFF"

# kwindowsystem needs plasma-wayland-protocols (Phase 6) and kguiaddons
kf6 kwindowsystem KF6WindowSystem

# Tier 2 — depend on Tier 1
kf6 kcolorscheme   KF6ColorScheme
kf6 kconfigwidgets KF6ConfigWidgets
kf6 kservice       KF6Service
kf6 kcompletion    KF6Completion
kf6 knotifications KF6Notifications
kf6 kglobalaccel   KF6GlobalAccel
kf6 kpackage       KF6Package
kf6 kdeclarative   KF6Declarative
kf6 kbookmarks     KF6Bookmarks
kf6 kfilemetadata  KF6FileMetaData

# kiconthemes needs kservice + kwidgetsaddons
kf6 kiconthemes KF6IconThemes

# ktextwidgets needs kwidgetsaddons + sonnet
kf6 ktextwidgets KF6TextWidgets

# kjobwidgets needs kwidgetsaddons + knotifications
kf6 kjobwidgets KF6JobWidgets

# kauth needs kwindowsystem + kjobwidgets
kf6 kauth KF6Auth

# kdoctools needs karchive + ki18n — must be BEFORE kio
kf6 kdoctools KF6DocTools

# kio needs kcompletion + kdoctools + kauth + kservice + kbookmarks + kjobwidgets
kf6 kio KF6KIO

# Tier 3 — depend on kio
kf6 knewstuff KF6NewStuff
kf6 kxmlgui   KF6XmlGui
kf6 kparts     KF6Parts
kf6 krunner    KF6Runner
kf6 kstatusnotifieritem KF6StatusNotifierItem
kf6 baloo      KF6Baloo
kf6 kcmutils   KF6KCMUtils
kf6 kded       KF6KDED
kf6 knotifyconfig KF6NotifyConfig

# kirigami needed before ksvg
kf6 kirigami KF6Kirigami2

# ksvg needs kirigami
kf6 ksvg KF6Svg

# kwallet: all daemons disabled — not appropriate for a pentest/security distro
if ! has_cmake KF6Wallet; then
    log "Building KF6: kwallet (all daemons disabled)"
    wget -nc https://download.kde.org/stable/frameworks/$KF6_DIR/kwallet-$KF6_VER.tar.xz
    tar xf kwallet-$KF6_VER.tar.xz && cd kwallet-$KF6_VER
    rm -rf build && mkdir build && cd build
    cmake .. $CMAKE_COMMON \
        -DBUILD_KWALLETD=OFF \
        -DBUILD_KSECRETD=OFF \
        -DBUILD_KWALLET_QUERY=OFF
    make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "kwallet (daemons disabled)"
fi

# syntax-highlighting must be before ktexteditor
kf6 syntax-highlighting KF6SyntaxHighlighting
kf6 ktexteditor KF6TextEditor

# prison: barcode scanning libs not needed on a pentest distro
kf6 prison KF6Prison "-DWITH_DMTX=OFF -DWITH_ZXING=OFF"

# kdoctools already built above — skip here if hit again
# breeze-icons: no cmake config file, check index.theme
if [ ! -f /usr/share/icons/breeze/index.theme ]; then
    log "Building KF6: breeze-icons $KF6_VER"
    wget -nc https://download.kde.org/stable/frameworks/$KF6_DIR/breeze-icons-$KF6_VER.tar.xz
    tar xf breeze-icons-$KF6_VER.tar.xz && cd breeze-icons-$KF6_VER
    rm -rf build && mkdir build && cd build
    cmake .. $CMAKE_COMMON
    make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "breeze-icons"
fi

# =============================================================================
# PHASE 9: PLASMA 6.4.0 PACKAGES
# 6.4.0 is the latest version compatible with Qt 6.8.x
# (6.5.x+ requires Qt 6.9+, 6.6.x requires Qt 6.10+)
# =============================================================================

plasma() {
    local pkg=$1 cmake_name=$2 extra="${3:-}"
    if has_cmake "$cmake_name"; then skip "Plasma/$pkg"; return; fi
    log "Building Plasma: $pkg $PLASMA_VER"
    wget -nc https://download.kde.org/stable/plasma/$PLASMA_VER/${pkg}-$PLASMA_VER.tar.xz
    tar xf ${pkg}-$PLASMA_VER.tar.xz && cd ${pkg}-$PLASMA_VER
    rm -rf build && mkdir build && cd build
    cmake .. $CMAKE_COMMON $extra
    make -j$JOBS && sudo make install
    cd $SOURCES
}

plasma kdecoration       KDecoration2
plasma libkscreen        KF6Screen
plasma libksysguard      KSysGuard
plasma kglobalacceld     KGlobalAcceld
plasma kwayland          KWayland
plasma layer-shell-qt    LayerShellQt
plasma plasma-activities PlasmaActivities
plasma plasma-activities-stats PlasmaActivitiesStats
plasma plasma5support    Plasma5Support
plasma libplasma         Plasma
plasma kscreenlocker     ScreenSaver

# KWin: requires GCC 15 patch for xdgsession_v1.h (QVariant incomplete type)
if ! has_cmake KWin; then
    log "Building KWin $PLASMA_VER (with GCC 15 patch)"
    wget -nc https://download.kde.org/stable/plasma/$PLASMA_VER/kwin-$PLASMA_VER.tar.xz
    tar xf kwin-$PLASMA_VER.tar.xz && cd kwin-$PLASMA_VER
    sed -i '/#include <memory>/a #include <QVariant>' src/wayland/xdgsession_v1.h
    rm -rf build && mkdir build && cd build
    cmake .. $CMAKE_COMMON
    make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "KWin"
fi

if ! has_cmake PlasmaWorkspace; then
    log "Building plasma-workspace $PLASMA_VER"
    wget -nc https://download.kde.org/stable/plasma/$PLASMA_VER/plasma-workspace-$PLASMA_VER.tar.xz
    tar xf plasma-workspace-$PLASMA_VER.tar.xz && cd plasma-workspace-$PLASMA_VER
    rm -rf build && mkdir build && cd build
    cmake .. $CMAKE_COMMON
    make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "plasma-workspace"
fi

if ! has_cmake PlasmaDesktop; then
    log "Building plasma-desktop $PLASMA_VER"
    wget -nc https://download.kde.org/stable/plasma/$PLASMA_VER/plasma-desktop-$PLASMA_VER.tar.xz
    tar xf plasma-desktop-$PLASMA_VER.tar.xz && cd plasma-desktop-$PLASMA_VER
    rm -rf build && mkdir build && cd build
    cmake .. $CMAKE_COMMON \
        -DBUILD_KCM_MOUSE_X11=OFF \
        -DBUILD_KCM_TOUCHPAD_X11=OFF
    make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "plasma-desktop"
fi

# =============================================================================
# PHASE 10: SDDM
# =============================================================================

if ! has_cmd sddm; then
    log "Creating sddm user"
    sudo useradd -r -s /bin/false -d /var/lib/sddm -M -c "SDDM Daemon" sddm 2>/dev/null || true
    sudo mkdir -p /var/lib/sddm
    sudo chown sddm:sddm /var/lib/sddm
    sudo chmod 700 /var/lib/sddm

    log "Building SDDM (git master, Qt6)"
    [ -d $SOURCES/sddm-git ] || git clone --depth=1 https://github.com/sddm/sddm.git $SOURCES/sddm-git
    cd $SOURCES/sddm-git
    git pull 2>/dev/null || true
    rm -rf build && mkdir build && cd build
    cmake .. $CMAKE_COMMON -DBUILD_MAN_PAGES=OFF -DBUILD_WITH_QT6=ON
    make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "SDDM"
fi

# sddm user needs video + input group access
sudo usermod -aG video,input sddm 2>/dev/null || true

# tmpfiles.d: ensure /run/sddm exists at boot with correct ownership
sudo bash -c 'cat > /usr/lib/tmpfiles.d/sddm.conf << EOF
d /run/sddm 0755 sddm sddm -
EOF'

# =============================================================================
# PHASE 11: POST-INSTALL CONFIGURATION
# =============================================================================

log "Fixing /etc/vconsole.conf (removing FONT= entry)"
sudo sed -i '/^FONT=/d' /etc/vconsole.conf

log "Creating Plasma Wayland session file"
sudo mkdir -p /usr/share/wayland-sessions
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

log "Creating SDDM Wayland config"
sudo mkdir -p /etc/sddm.conf.d
sudo bash -c 'cat > /etc/sddm.conf.d/wayland.conf << EOF
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell

[Wayland]
CompositorCommand=kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale1
SessionDir=/usr/share/wayland-sessions
EOF'

log "Creating SDDM PAM configs"
# Explicit pam_systemd.so ensures XDG_RUNTIME_DIR is created for KWin
sudo bash -c 'cat > /etc/pam.d/sddm << EOF
auth      include   system-auth
account   include   system-account
password  include   system-password
session   required  pam_env.so readenv=1
session   required  pam_unix.so
session   required  pam_loginuid.so
session   optional  pam_systemd.so
EOF'

sudo bash -c 'cat > /etc/pam.d/sddm-greeter << EOF
auth     required  pam_permit.so
account  required  pam_permit.so
password required  pam_permit.so
session  required  pam_permit.so
session  optional  pam_systemd.so
EOF'

sudo bash -c 'cat > /etc/pam.d/sddm-autologin << EOF
auth     required  pam_permit.so
account  required  pam_unix.so
password required  pam_permit.so
session  required  pam_env.so readenv=1
session  required  pam_unix.so
session  optional  pam_systemd.so
EOF'

log "Enabling SDDM"
sudo systemctl enable sddm

log "================================================================="
log "Done! KDE Plasma $PLASMA_VER + SDDM installed."
log "Reboot to start SDDM."
log ""
log "On first boot: select 'KDE Plasma' session in SDDM."
log "Fallback: Ctrl+Alt+F2, login as pepper, run your up2sway script."
log "Diagnostics: journalctl -u sddm --no-pager | tail -40"
log "================================================================="
