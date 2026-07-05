#!/bin/bash
# SableLinux — KDE Plasma 6 Build Script v2
# Complete build from XCB deps through SDDM
# Compiler: GCC 15.2.0
# Qt: 6.8.2 (pre-installed)
# KF6: 6.24.0 | Plasma: 6.4.0
# wayland-protocols: 1.48
# plasma-wayland-protocols: 1.20.0
#
# FIXES vs original script:
# - KF6 6.24.0: -DBUILD_PYTHON_BINDINGS=OFF globally (no Shiboken6)
# - kguiaddons: -DUSE_DBUS=OFF (avoids Qt private headers)
# - kcompletion: added (missing from original, required by kio)
# - kdoctools: moved before kio
# - ECM: moved before Phonon
# - plasma-wayland-protocols: moved before kwindowsystem (Phase 1)
# - wayland-protocols: upgraded to 1.48 (kwindowsystem needs ext-background-effect)
# - plasma-wayland-protocols: upgraded to 1.20.0 (libkscreen EDR/DDC-CI protocols)
# - kwallet: -DBUILD_KWALLETD=OFF -DBUILD_KSECRETD=OFF -DBUILD_KWALLET_QUERY=OFF
# - prison: -DWITH_DMTX=OFF -DWITH_ZXING=OFF
# - Qt6Location: added to Qt modules (plasma-workspace requirement)
# - KWin 6.4.0: patch xdgsession_v1.h (#include <QVariant>) for GCC 15
# - Plasma 6.4.0 (not 6.6.3 — requires Qt 6.10.0)
# - SDDM PAM: pam_systemd.so in session for XDG_RUNTIME_DIR creation
# - SDDM: tmpfiles.d entry for /run/sddm
# - SDDM: sddm user added to video+input groups
# - Skip guards on all packages for fast restarts

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

log()  { echo -e "\n\033[1;35m>>> $1\033[0m\n"; }
skip() { echo -e "\n\033[1;32m--- SKIP (already installed): $1\033[0m\n"; }
die()  { echo -e "\n\033[1;31mERROR: $1\033[0m\n"; exit 1; }

cmake_installed() {
    local name=$1
    [ -f "/usr/lib/cmake/${name}/${name}Config.cmake" ] || \
    [ -f "/lib/cmake/${name}/${name}Config.cmake" ]
}

cd $SOURCES

# ============================================================
# PHASE 1: XCB DEPENDENCIES
# ============================================================

xcb_build() {
    local pkg=$1 lib=$2
    if ldconfig -p | grep -q "$lib"; then skip "$pkg"; return; fi
    log "Building $pkg"
    wget -nc https://xcb.freedesktop.org/dist/${pkg}.tar.xz
    tar xf ${pkg}.tar.xz && cd ${pkg}
    sudo chown -R $(whoami) .
    ./configure --prefix=/usr --disable-static && make -j$JOBS && sudo make install
    cd $SOURCES
}

xcb_build xcb-util-0.4.1         libxcb-util
xcb_build xcb-util-image-0.4.1   libxcb-image
xcb_build xcb-util-renderutil-0.3.10 libxcb-render-util
xcb_build xcb-util-wm-0.4.2      libxcb-icccm
xcb_build xcb-util-keysyms-0.4.1 libxcb-keysyms
xcb_build xcb-util-cursor-0.1.4  libxcb-cursor

# ============================================================
# PHASE 2: WAYLAND PROTOCOLS (must be before Qt and KF6)
# ============================================================

if ! pkg-config --exists wayland-protocols || \
   [ "$(pkg-config --modversion wayland-protocols)" != "1.48" ]; then
    log "Building wayland-protocols 1.48"
    wget -nc https://gitlab.freedesktop.org/wayland/wayland-protocols/-/releases/1.48/downloads/wayland-protocols-1.48.tar.xz
    tar xf wayland-protocols-1.48.tar.xz && cd wayland-protocols-1.48
    mkdir -p build && cd build
    meson setup .. --prefix=/usr --libdir=lib --buildtype=release
    ninja && sudo ninja install
    cd $SOURCES
else
    skip "wayland-protocols 1.48"
fi

if [ ! -f "/usr/share/plasma-wayland-protocols/ext-background-effect-v1.xml" ] && \
   [ ! -f "/usr/share/plasma-wayland-protocols/plasma-shell.xml" ]; then
    log "Building plasma-wayland-protocols 1.20.0"
    wget -nc https://download.kde.org/stable/plasma-wayland-protocols/plasma-wayland-protocols-1.20.0.tar.xz
    tar xf plasma-wayland-protocols-1.20.0.tar.xz && cd plasma-wayland-protocols-1.20.0
    mkdir -p build && cd build
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF
    make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "plasma-wayland-protocols 1.20.0"
fi

# ============================================================
# PHASE 3: Qt6 MODULES
# NOTE: qtbase must be built AFTER xcb-util-* packages
# ============================================================

if ! cmake_installed Qt6; then
    log "Building Qt6 base $QT_VER (with xcb support)"
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
    skip "Qt6 base"
fi

if [ ! -f "/usr/lib/libQt6ShaderTools.so" ]; then
    log "Building qtshadertools $QT_VER"
    wget -nc https://download.qt.io/official_releases/qt/6.8/$QT_VER/submodules/qtshadertools-everywhere-src-$QT_VER.tar.xz
    tar xf qtshadertools-everywhere-src-$QT_VER.tar.xz && cd qtshadertools-everywhere-src-$QT_VER
    rm -rf build && mkdir build && cd build
    /usr/bin/qt-cmake .. -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_FLAGS="-include cstdint"
    cmake --build . --parallel $JOBS && sudo cmake --install .
    cd $SOURCES
else
    skip "qtshadertools"
fi

for mod in qtdeclarative qtwayland qtsvg qttools qt5compat qtimageformats \
           qtmultimedia qtspeech qtsensors qtpositioning qtwebsockets qtlocation; do
    lib_check=""
    case $mod in
        qtdeclarative)   lib_check="/usr/lib/libQt6Qml.so" ;;
        qtwayland)       lib_check="/usr/lib/libQt6WaylandClient.so" ;;
        qtsvg)           lib_check="/usr/lib/libQt6Svg.so" ;;
        qttools)         lib_check="/usr/bin/qhelpgenerator" ;;
        qt5compat)       lib_check="/usr/lib/libQt6Core5Compat.so" ;;
        qtimageformats)  lib_check="/usr/plugins/imageformats/libqwebp.so" ;;
        qtmultimedia)    lib_check="/usr/lib/libQt6Multimedia.so" ;;
        qtspeech)        lib_check="/usr/lib/libQt6TextToSpeech.so" ;;
        qtsensors)       lib_check="/usr/lib/libQt6Sensors.so" ;;
        qtpositioning)   lib_check="/usr/lib/libQt6Positioning.so" ;;
        qtwebsockets)    lib_check="/usr/lib/libQt6WebSockets.so" ;;
        qtlocation)      lib_check="/usr/lib/libQt6Location.so" ;;
    esac
    if [ -n "$lib_check" ] && [ -f "$lib_check" ]; then
        skip "$mod"
        continue
    fi
    log "Building $mod $QT_VER"
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
# PHASE 4: MISC DEPENDENCIES
# ============================================================

misc_autotools() {
    local pkg=$1 url=$2 lib_check=$3
    if ldconfig -p | grep -q "$lib_check"; then skip "$pkg"; return; fi
    log "Building $pkg"
    wget -nc $url
    local tarball=$(basename $url)
    tar xf $tarball && cd ${tarball%.tar.*}
    ./configure --prefix=/usr --disable-static && make -j$JOBS && sudo make install
    cd $SOURCES
}

misc_autotools libogg-1.3.5 \
    https://downloads.xiph.org/releases/ogg/libogg-1.3.5.tar.xz libogg

misc_autotools libvorbis-1.3.7 \
    https://downloads.xiph.org/releases/vorbis/libvorbis-1.3.7.tar.xz libvorbis

if ! ldconfig -p | grep -q libcanberra; then
    log "Building libcanberra 0.30"
    wget -nc http://0pointer.de/lennart/projects/libcanberra/libcanberra-0.30.tar.xz
    tar xf libcanberra-0.30.tar.xz && cd libcanberra-0.30
    ./configure --prefix=/usr --disable-static --enable-pulse --disable-oss
    make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "libcanberra"
fi

if ! ldconfig -p | grep -q libhunspell; then
    log "Building hunspell 1.7.2"
    wget -nc https://github.com/hunspell/hunspell/releases/download/v1.7.2/hunspell-1.7.2.tar.gz
    tar xf hunspell-1.7.2.tar.gz && cd hunspell-1.7.2
    autoreconf -fi && ./configure --prefix=/usr --disable-static
    make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "hunspell"
fi

if [ ! -f "/usr/lib/liblmdb.so" ]; then
    log "Building lmdb 0.9.32"
    wget -nc https://github.com/LMDB/lmdb/archive/LMDB_0.9.32.tar.gz
    tar xf LMDB_0.9.32.tar.gz && cd lmdb-LMDB_0.9.32/libraries/liblmdb
    make -j$JOBS && sudo make install prefix=/usr
    cd $SOURCES
else
    skip "lmdb"
fi

if [ ! -f "/usr/include/boost/version.hpp" ]; then
    log "Building boost 1.87.0 headers"
    wget -nc https://archives.boost.io/release/1.87.0/source/boost_1_87_0.tar.bz2
    tar xf boost_1_87_0.tar.bz2 && cd boost_1_87_0
    ./bootstrap.sh --prefix=/usr && sudo ./b2 install --with-headers
    cd $SOURCES
else
    skip "boost headers"
fi

if ! ldconfig -p | grep -q liblcms2; then
    log "Building lcms2 2.16"
    wget -nc https://github.com/mm2/Little-CMS/releases/download/lcms2.16/lcms2-2.16.tar.gz
    tar xf lcms2-2.16.tar.gz && cd lcms2-2.16
    ./configure --prefix=/usr --disable-static && make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "lcms2"
fi

if ! cmake_installed libei; then
    log "Building libei 1.3.0"
    wget -nc https://gitlab.freedesktop.org/libinput/libei/-/archive/1.3.0/libei-1.3.0.tar.gz
    tar xf libei-1.3.0.tar.gz && cd libei-1.3.0
    mkdir -p build && cd build
    meson setup .. --prefix=/usr --libdir=lib --buildtype=release
    ninja && sudo ninja install
    cd $SOURCES
else
    skip "libei"
fi

if ! ldconfig -p | grep -q libgudev; then
    log "Building libgudev 238"
    wget -nc https://download.gnome.org/sources/libgudev/238/libgudev-238.tar.xz
    tar xf libgudev-238.tar.xz && cd libgudev-238
    meson setup build --prefix=/usr --libdir=lib --buildtype=release
    ninja -C build && sudo ninja -C build install
    cd $SOURCES
else
    skip "libgudev"
fi

if ! ldconfig -p | grep -q libwacom; then
    log "Building libwacom 2.12.2"
    wget -nc https://github.com/linuxwacom/libwacom/releases/download/libwacom-2.12.2/libwacom-2.12.2.tar.xz
    tar xf libwacom-2.12.2.tar.xz && cd libwacom-2.12.2
    meson setup build --prefix=/usr --libdir=lib --buildtype=release -Dtests=disabled
    ninja -C build && sudo ninja -C build install
    cd $SOURCES
else
    skip "libwacom"
fi

if ! command -v sensors &>/dev/null; then
    log "Building lm-sensors 3.6.0"
    wget -nc https://github.com/lm-sensors/lm-sensors/archive/refs/tags/V3-6-0.tar.gz
    tar xf V3-6-0.tar.gz && cd lm-sensors-3-6-0
    make -j$JOBS && sudo make install PREFIX=/usr
    cd $SOURCES
else
    skip "lm-sensors"
fi

if ! ldconfig -p | grep -q libicuuc; then
    log "Building ICU 76.1"
    wget -nc https://github.com/unicode-org/icu/releases/download/release-76-1/icu4c-76_1-src.tgz
    tar xf icu4c-76_1-src.tgz && cd icu/source
    ./configure --prefix=/usr && make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "ICU"
fi

if ! ldconfig -p | grep -q libqalculate; then
    log "Building libqalculate 5.5.0"
    wget -nc https://github.com/Qalculate/libqalculate/releases/download/v5.5.0/libqalculate-5.5.0.tar.gz
    tar xf libqalculate-5.5.0.tar.gz && cd libqalculate-5.5.0
    ./configure --prefix=/usr --disable-static && make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "libqalculate"
fi

# libpulse-mainloop-glib (for Phonon)
if ! ldconfig -p | grep -q libpulse-mainloop-glib; then
    log "Building libpulse-mainloop-glib"
    cd pulseaudio-17.0
    cp /sources/pulseaudio-17.0/src/pulse/glib-mainloop.h /usr/include/pulse/ 2>/dev/null || true
    meson setup build-glib --prefix=/usr --libdir=lib \
        -Ddaemon=false -Dglib=enabled -Dtests=false -Ddoxygen=false --reconfigure 2>/dev/null || \
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

if ! cmake_installed phonon4qt6; then
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

if ! cmake_installed QCoro6; then
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

if ! ldconfig -p | grep -q libqrencode; then
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

# polkit
if ! id polkitd &>/dev/null; then
    sudo groupadd -fg 27 polkitd 2>/dev/null || true
    sudo useradd -c "PolicyKit Daemon Owner" -d /etc/polkit-1 -u 27 \
        -g polkitd -s /bin/false polkitd 2>/dev/null || true
fi

if ! ldconfig -p | grep -q libduktape; then
    log "Building duktape 2.7.0"
    wget -nc https://duktape.org/duktape-2.7.0.tar.xz
    tar xf duktape-2.7.0.tar.xz && cd duktape-2.7.0
    make -f Makefile.sharedlibrary && sudo make -f Makefile.sharedlibrary install INSTALL_PREFIX=/usr
    cd $SOURCES
else
    skip "duktape"
fi

if ! command -v pkcheck &>/dev/null; then
    log "Building polkit 126"
    wget -nc https://github.com/polkit-org/polkit/archive/126/polkit-126.tar.gz
    tar xf polkit-126.tar.gz && cd polkit-126
    mkdir -p build && cd build
    meson setup .. --prefix=/usr --libdir=lib --buildtype=release \
        -Dman=false -Dtests=false -Dintrospection=false \
        -Dsession_tracking=logind -Dos_type=lfs
    ninja && sudo ninja install
    cd $SOURCES
else
    skip "polkit"
fi

if ! cmake_installed PolkitQt6-1; then
    log "Building polkit-qt-1 (Qt6, from git)"
    [ -d polkit-qt-1 ] || git clone https://github.com/KDE/polkit-qt-1.git
    cd polkit-qt-1
    rm -rf build && mkdir build && cd build
    cmake .. $CMAKE_COMMON -DQT_MAJOR_VERSION=6
    make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "polkit-qt-1"
fi

# Perl URI::Escape (for kdoctools)
if ! perl -MURI::Escape -e 1 2>/dev/null; then
    log "Installing Perl URI::Escape"
    sudo cpan URI::Escape
else
    skip "Perl URI::Escape"
fi

# DocBook XML and XSL
if [ ! -d "/usr/share/xml/docbook/xml-dtd-4.5" ]; then
    log "Installing DocBook XML 4.5"
    wget -nc http://www.oasis-open.org/docbook/xml/4.5/docbook-xml-4.5.zip
    python3 -c "import zipfile; zipfile.ZipFile('docbook-xml-4.5.zip').extractall('docbook-xml-4.5')"
    sudo mkdir -p /usr/share/xml/docbook/xml-dtd-4.5
    sudo cp -r docbook-xml-4.5/* /usr/share/xml/docbook/xml-dtd-4.5/
else
    skip "DocBook XML"
fi

if [ ! -d "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" ]; then
    log "Installing DocBook XSL 1.79.2"
    wget -nc https://github.com/docbook/xslt10-stylesheets/releases/download/release/1.79.2/docbook-xsl-nons-1.79.2.tar.bz2
    tar xf docbook-xsl-nons-1.79.2.tar.bz2
    sudo mkdir -p /usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2
    sudo cp -r docbook-xsl-nons-1.79.2/* /usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2/
else
    skip "DocBook XSL"
fi

if ! ldconfig -p | grep -q libxslt; then
    log "Building libxslt 1.1.42"
    wget -nc https://download.gnome.org/sources/libxslt/1.1/libxslt-1.1.42.tar.xz
    tar xf libxslt-1.1.42.tar.xz && cd libxslt-1.1.42
    ./configure --prefix=/usr --disable-static && make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "libxslt"
fi

# ============================================================
# PHASE 5: EXTRA CMAKE MODULES (must be before ALL KF6 and Phonon)
# ============================================================

if ! cmake_installed ECM; then
    log "Building Extra CMake Modules $KF6_VER"
    wget -nc https://download.kde.org/stable/frameworks/$KF6_DIR/extra-cmake-modules-$KF6_VER.tar.xz
    tar xf extra-cmake-modules-$KF6_VER.tar.xz && cd extra-cmake-modules-$KF6_VER
    mkdir -p build && cd build
    cmake .. $CMAKE_COMMON
    make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "ECM"
fi

# ============================================================
# PHASE 6: KDE FRAMEWORKS 6.24.0
# Correct dependency order for 6.24.0
# ============================================================

kf6_build() {
    local pkg=$1
    local cmake_name=$2
    local extra="${3:-}"
    if cmake_installed "$cmake_name"; then
        skip "$pkg"
        return
    fi
    log "Building KF6: $pkg"
    wget -nc https://download.kde.org/stable/frameworks/$KF6_DIR/${pkg}-$KF6_VER.tar.xz
    tar xf ${pkg}-$KF6_VER.tar.xz && cd ${pkg}-$KF6_VER
    rm -rf build && mkdir build && cd build
    cmake .. $CMAKE_COMMON $extra
    make -j$JOBS && sudo make install
    cd $SOURCES
}

kf6_build kcoreaddons    KF6CoreAddons
kf6_build kconfig        KF6Config
kf6_build karchive       KF6Archive
kf6_build kdbusaddons    KF6DBusAddons
kf6_build kcrash         KF6Crash
kf6_build ki18n          KF6I18n
kf6_build kitemviews     KF6ItemViews
kf6_build kcodecs        KF6Codecs
kf6_build kwidgetsaddons KF6WidgetsAddons

# kguiaddons: -DUSE_DBUS=OFF avoids Qt private headers (new in 6.24.0)
kf6_build kguiaddons     KF6GuiAddons "-DUSE_DBUS=OFF"

# kwindowsystem: needs plasma-wayland-protocols (built in Phase 2)
kf6_build kwindowsystem  KF6WindowSystem

kf6_build kcolorscheme   KF6ColorScheme
kf6_build kconfigwidgets KF6ConfigWidgets
kf6_build kservice       KF6Service
kf6_build kiconthemes    KF6IconThemes
kf6_build knotifications KF6Notifications
kf6_build kglobalaccel   KF6GlobalAccel
kf6_build kpackage       KF6Package
kf6_build kdeclarative   KF6Declarative
kf6_build solid          KF6Solid
kf6_build kbookmarks     KF6Bookmarks

# kcompletion: missing from original script, required by kio in 6.24.0
kf6_build kcompletion    KF6Completion

kf6_build kjobwidgets    KF6JobWidgets
kf6_build kauth          KF6Auth

# kdoctools: must be before kio
if ! cmake_installed KF6DocTools; then
    log "Building KF6: kdoctools"
    wget -nc https://download.kde.org/stable/frameworks/$KF6_DIR/kdoctools-$KF6_VER.tar.xz
    tar xf kdoctools-$KF6_VER.tar.xz && cd kdoctools-$KF6_VER
    rm -rf build && mkdir build && cd build
    cmake .. $CMAKE_COMMON && make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "kdoctools"
fi

kf6_build kio            KF6KIO
kf6_build attica         KF6Attica
kf6_build knewstuff      KF6NewStuff
kf6_build kxmlgui        KF6XmlGui
kf6_build kparts         KF6Parts
kf6_build kitemmodels    KF6ItemModels
kf6_build krunner        KF6Runner
kf6_build sonnet         KF6Sonnet
kf6_build ktextwidgets   KF6TextWidgets
kf6_build kstatusnotifieritem KF6StatusNotifierItem
kf6_build kidletime      KF6IdleTime
kf6_build kfilemetadata  KF6FileMetaData
kf6_build baloo          KF6Baloo
kf6_build ksvg           KF6Svg
kf6_build kirigami       KF6Kirigami2
kf6_build kcmutils       KF6KCMUtils
kf6_build kded           KF6KDED
kf6_build knotifyconfig  KF6NotifyConfig

# kwallet: all daemons disabled — not appropriate for a pentest distro
if ! cmake_installed KF6Wallet; then
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

kf6_build kholidays      KF6Holidays
kf6_build kuserfeedback  KF6UserFeedback
kf6_build kunitconversion KF6UnitConversion

# syntax-highlighting must be before ktexteditor
kf6_build syntax-highlighting KF6SyntaxHighlighting
kf6_build ktexteditor    KF6TextEditor

# prison: barcode libs not needed
kf6_build prison KF6Prison "-DWITH_DMTX=OFF -DWITH_ZXING=OFF"

# breeze-icons: no cmake config, check index.theme
if [ ! -f "/usr/share/icons/breeze/index.theme" ]; then
    log "Building KF6: breeze-icons"
    wget -nc https://download.kde.org/stable/frameworks/$KF6_DIR/breeze-icons-$KF6_VER.tar.xz
    tar xf breeze-icons-$KF6_VER.tar.xz && cd breeze-icons-$KF6_VER
    rm -rf build && mkdir build && cd build
    cmake .. $CMAKE_COMMON
    make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "breeze-icons"
fi

kf6_build kholidays      KF6Holidays
kf6_build kuserfeedback  KF6UserFeedback
kf6_build kunitconversion KF6UnitConversion

# ============================================================
# PHASE 7: PLASMA PACKAGES 6.4.0
# ============================================================

plasma_build() {
    local pkg=$1
    local cmake_name=$2
    local extra="${3:-}"
    if cmake_installed "$cmake_name"; then
        skip "$pkg"
        return
    fi
    log "Building Plasma: $pkg"
    wget -nc https://download.kde.org/stable/plasma/$PLASMA_VER/${pkg}-$PLASMA_VER.tar.xz
    tar xf ${pkg}-$PLASMA_VER.tar.xz && cd ${pkg}-$PLASMA_VER
    rm -rf build && mkdir build && cd build
    cmake .. $CMAKE_COMMON $extra
    make -j$JOBS && sudo make install
    cd $SOURCES
}

plasma_build kdecoration          KDecoration2
plasma_build libkscreen           KF6Screen
plasma_build libksysguard         KSysGuard
plasma_build kglobalacceld        KGlobalAcceld
plasma_build kwayland             KWayland
plasma_build layer-shell-qt       LayerShellQt
plasma_build plasma-activities    PlasmaActivities
plasma_build plasma-activities-stats PlasmaActivitiesStats
plasma_build plasma5support       Plasma5Support
plasma_build libplasma            Plasma
plasma_build kscreenlocker        ScreenSaver

# KWin: patch xdgsession_v1.h for GCC 15 (QVariant incomplete type)
if ! cmake_installed KWin; then
    log "Building KWin $PLASMA_VER"
    wget -nc https://download.kde.org/stable/plasma/$PLASMA_VER/kwin-$PLASMA_VER.tar.xz
    tar xf kwin-$PLASMA_VER.tar.xz && cd kwin-$PLASMA_VER
    # GCC 15 fix: QVariant used as incomplete type
    sed -i '/#include <memory>/a #include <QVariant>' src/wayland/xdgsession_v1.h
    rm -rf build && mkdir build && cd build
    cmake .. $CMAKE_COMMON
    make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "KWin"
fi

if ! cmake_installed PlasmaWorkspace; then
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

if ! cmake_installed PlasmaDesktop; then
    log "Building plasma-desktop $PLASMA_VER"
    wget -nc https://download.kde.org/stable/plasma/$PLASMA_VER/plasma-desktop-$PLASMA_VER.tar.xz
    tar xf plasma-desktop-$PLASMA_VER.tar.xz && cd plasma-desktop-$PLASMA_VER
    rm -rf build && mkdir build && cd build
    cmake .. $CMAKE_COMMON -DBUILD_KCM_MOUSE_X11=OFF -DBUILD_KCM_TOUCHPAD_X11=OFF
    make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "plasma-desktop"
fi

# ============================================================
# PHASE 8: SDDM
# ============================================================

if ! command -v sddm &>/dev/null; then
    log "Creating sddm user and groups"
    sudo useradd -r -s /bin/false -d /var/lib/sddm -M -c "SDDM Daemon" sddm 2>/dev/null || true
    sudo mkdir -p /var/lib/sddm
    sudo chown sddm:sddm /var/lib/sddm
    sudo chmod 700 /var/lib/sddm

    log "Building SDDM (git master, Qt6)"
    [ -d $SOURCES/sddm-git ] || git clone --depth=1 https://github.com/sddm/sddm.git $SOURCES/sddm-git
    cd $SOURCES/sddm-git && git pull 2>/dev/null || true
    rm -rf build && mkdir build && cd build
    cmake .. $CMAKE_COMMON -DBUILD_MAN_PAGES=OFF -DBUILD_WITH_QT6=ON
    make -j$JOBS && sudo make install
    cd $SOURCES
else
    skip "SDDM"
fi

# sddm user group membership
sudo usermod -aG video,input sddm 2>/dev/null || true

# tmpfiles.d entry so /run/sddm exists at boot with correct ownership
sudo bash -c 'cat > /usr/lib/tmpfiles.d/sddm.conf << EOF
d /run/sddm 0755 sddm sddm -
EOF'

# ============================================================
# PHASE 9: CONFIGURATION
# ============================================================

log "Fixing /etc/vconsole.conf"
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

log "Creating SDDM config"
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
# sddm PAM: includes pam_systemd.so via system-session for XDG_RUNTIME_DIR
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

log ""
log "Done! KDE Plasma $PLASMA_VER + SDDM installed."
log "Reboot to start SDDM and select Plasma or Sway at login."
log ""
log "If SDDM fails: check 'journalctl -u sddm' and 'systemctl --failed'"
log "Fallback: Ctrl+Alt+F2, login as pepper, run 'sway'"
