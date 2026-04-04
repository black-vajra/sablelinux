#!/bin/bash
# SableLinux — Sway Desktop Stack Build Script
# Based on live build session (BUILDLOG.md)
# Target: Sway 1.10 + Waybar 0.11.0 on LFS 12.4-systemd base
# Compiler: GCC 15.2.0

set -e

JOBS=14
SOURCES=/sources
CMAKE_COMMON="-DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release"

log() { echo -e "\n\033[1;35m>>> $1\033[0m\n"; }
die() { echo -e "\n\033[1;31mERROR: $1\033[0m\n"; exit 1; }

cd $SOURCES

# ============================================================
# PHASE 1: DISPLAY STACK FOUNDATION
# ============================================================

log "Building libdrm"
wget -nc https://dri.freedesktop.org/libdrm/libdrm-2.4.124.tar.xz
tar xf libdrm-2.4.124.tar.xz && cd libdrm-2.4.124
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release
ninja -C build && sudo ninja -C build install
cd $SOURCES

log "Building wayland"
wget -nc https://gitlab.freedesktop.org/wayland/wayland/-/releases/1.23.1/downloads/wayland-1.23.1.tar.xz
tar xf wayland-1.23.1.tar.xz && cd wayland-1.23.1
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Ddocumentation=false -Dtests=false
ninja -C build && sudo ninja -C build install
cd $SOURCES

log "Building wayland-protocols"
wget -nc https://gitlab.freedesktop.org/wayland/wayland-protocols/-/releases/1.44/downloads/wayland-protocols-1.44.tar.xz
tar xf wayland-protocols-1.44.tar.xz && cd wayland-protocols-1.44
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release
ninja -C build && sudo ninja -C build install
cd $SOURCES

# ============================================================
# PHASE 2: INPUT STACK
# NOTE: libinput 1.31 requires source patch for wlroots 0.18.2 compat
# patch: LIBINPUT_SWITCH_KEYPAD_SLIDE enum missing
# ============================================================

log "Building libevdev"
wget -nc https://freedesktop.org/software/libevdev/libevdev-1.13.4.tar.xz
tar xf libevdev-1.13.4.tar.xz && cd libevdev-1.13.4
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Dtests=disabled -Ddocumentation=disabled
ninja -C build && sudo ninja -C build install
cd $SOURCES

log "Building mtdev"
wget -nc https://bitmath.org/code/mtdev/mtdev-1.1.7.tar.bz2
tar xf mtdev-1.1.7.tar.bz2 && cd mtdev-1.1.7
./configure --prefix=/usr --disable-static && make -j$JOBS && sudo make install
cd $SOURCES

log "Building libinput 1.31 (with LIBINPUT_SWITCH_KEYPAD_SLIDE patch for wlroots)"
wget -nc https://gitlab.freedesktop.org/libinput/libinput/-/archive/1.31.0/libinput-1.31.0.tar.gz
tar xf libinput-1.31.0.tar.gz && cd libinput-1.31.0
# Apply patch: add LIBINPUT_SWITCH_KEYPAD_SLIDE to enum if missing
grep -q "LIBINPUT_SWITCH_KEYPAD_SLIDE" src/libinput.h || \
    sed -i '/LIBINPUT_SWITCH_TABLET_MODE/a\\tLIBINPUT_SWITCH_KEYPAD_SLIDE,' src/libinput.h
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Dtests=false -Ddocumentation=false -Ddebug-gui=false
ninja -C build && sudo ninja -C build install
cd $SOURCES

# ============================================================
# PHASE 3: FONT STACK
# freetype built twice: first without harfbuzz, then with
# ============================================================

log "Building freetype (pass 1 — without harfbuzz)"
wget -nc https://downloads.sourceforge.net/freetype/freetype-2.13.3.tar.xz
tar xf freetype-2.13.3.tar.xz && cd freetype-2.13.3
./configure --prefix=/usr --enable-freetype-config --disable-static \
    --with-harfbuzz=no
make -j$JOBS && sudo make install
cd $SOURCES

log "Building harfbuzz"
wget -nc https://github.com/harfbuzz/harfbuzz/releases/download/10.2.0/harfbuzz-10.2.0.tar.xz
tar xf harfbuzz-10.2.0.tar.xz && cd harfbuzz-10.2.0
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Dbenchmark=disabled -Dtests=disabled -Ddocs=disabled
ninja -C build && sudo ninja -C build install
cd $SOURCES

log "Building freetype (pass 2 — with harfbuzz)"
cd freetype-2.13.3
make distclean
./configure --prefix=/usr --enable-freetype-config --disable-static
make -j$JOBS && sudo make install
cd $SOURCES

log "Building fontconfig"
wget -nc https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.17.1.tar.xz
tar xf fontconfig-2.17.1.tar.xz && cd fontconfig-2.17.1
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var \
    --disable-docs --disable-static
make -j$JOBS && sudo make install
cd $SOURCES

# ============================================================
# PHASE 4: GRAPHICS STACK
# LLVM must be built with RTTI enabled
# Mesa: radeonsi + llvmpipe + RADV; Intel iris/ANV deferred (needs libclc)
# glslang: ENABLE_OPT=OFF (no SPIRV-Tools)
# ============================================================

log "Building cmake 3.31.6"
wget -nc https://cmake.org/files/v3.31/cmake-3.31.6.tar.gz
tar xf cmake-3.31.6.tar.gz && cd cmake-3.31.6
./configure --prefix=/usr && make -j$JOBS && sudo make install
cd $SOURCES

log "Building LLVM 19.1.7 (AMDGPU+BPF, RTTI enabled)"
wget -nc https://github.com/llvm/llvm-project/releases/download/llvmorg-19.1.7/llvm-project-19.1.7.src.tar.xz
tar xf llvm-project-19.1.7.src.tar.xz && cd llvm-project-19.1.7.src
mkdir -p build && cd build
cmake ../llvm \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_PROJECTS="clang" \
    -DLLVM_TARGETS_TO_BUILD="X86;AMDGPU;BPF" \
    -DLLVM_ENABLE_RTTI=ON \
    -DLLVM_BUILD_LLVM_DYLIB=ON \
    -DLLVM_LINK_LLVM_DYLIB=ON \
    -DLLVM_BUILD_TESTS=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_BENCHMARKS=OFF
make -j$JOBS && sudo make install
cd $SOURCES

log "Building glslang (ENABLE_OPT=OFF — no SPIRV-Tools)"
wget -nc https://github.com/KhronosGroup/glslang/archive/refs/tags/16.2.0.tar.gz -O glslang-16.2.0.tar.gz
tar xf glslang-16.2.0.tar.gz && cd glslang-16.2.0
mkdir -p build && cd build
cmake .. $CMAKE_COMMON -DENABLE_OPT=OFF -DBUILD_TESTING=OFF -DENABLE_GLSLANG_BINARIES=ON
make -j$JOBS && sudo make install
cd $SOURCES

log "Building Mesa 25.0.1 (radeonsi + llvmpipe + RADV; no Intel)"
wget -nc https://mesa.freedesktop.org/archive/mesa-25.0.1.tar.xz
tar xf mesa-25.0.1.tar.xz && cd mesa-25.0.1
rm -rf build
meson setup build \
    --prefix=/usr \
    --libdir=lib \
    --buildtype=release \
    -Dgallium-drivers=radeonsi,swrast \
    -Dvulkan-drivers=amd \
    -Dvulkan-layers=device-select,overlay \
    -Dplatforms=x11,wayland \
    -Dllvm=enabled \
    -Dshared-llvm=enabled \
    -Dglvnd=false \
    -Dopengl=true \
    -Degl=enabled \
    -Dgbm=enabled \
    -Dvideo-codecs=h264dec,h264enc,h265dec,h265enc,vc1dec \
    -Dgles1=enabled \
    -Dgles2=enabled \
    -Dopencl-spirv=false \
    -Dgallium-opencl=disabled \
    -Dintel-clc=disabled \
    -Dmicrosoft-clc=disabled
ninja -C build && sudo ninja -C build install
cd $SOURCES

# ============================================================
# PHASE 5: SEATD + SWAY STACK
# ============================================================

log "Building seatd"
wget -nc https://git.sr.ht/~kennylevinsen/seatd/archive/0.9.1.tar.gz -O seatd-0.9.1.tar.gz
tar xf seatd-0.9.1.tar.gz && cd seatd-0.9.1
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Dserver=enabled -Dexamples=disabled -Dtests=disabled
ninja -C build && sudo ninja -C build install
sudo systemctl enable seatd
cd $SOURCES

log "Building libxkbcommon"
wget -nc https://xkbcommon.org/download/libxkbcommon-1.7.0.tar.xz
tar xf libxkbcommon-1.7.0.tar.xz && cd libxkbcommon-1.7.0
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Denable-docs=false -Denable-wayland=true -Denable-x11=true
ninja -C build && sudo ninja -C build install
cd $SOURCES

log "Building pixman"
wget -nc https://cairographics.org/releases/pixman-0.44.0.tar.gz
tar xf pixman-0.44.0.tar.gz && cd pixman-0.44.0
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Dtests=disabled -Ddemos=disabled
ninja -C build && sudo ninja -C build install
cd $SOURCES

log "Building wlroots 0.18.2 (with libinput 1.31 KEYPAD_SLIDE patch)"
wget -nc https://gitlab.freedesktop.org/wlroots/wlroots/-/archive/0.18.2/wlroots-0.18.2.tar.gz
tar xf wlroots-0.18.2.tar.gz && cd wlroots-0.18.2
# Patch for libinput 1.31 API skew
grep -q "LIBINPUT_SWITCH_KEYPAD_SLIDE" include/wlr/types/wlr_switch.h 2>/dev/null || \
    sed -i 's/LIBINPUT_SWITCH_TABLET_MODE/LIBINPUT_SWITCH_TABLET_MODE, LIBINPUT_SWITCH_KEYPAD_SLIDE/' \
    backend/libinput/switch.c 2>/dev/null || true
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Dexamples=false
ninja -C build && sudo ninja -C build install
cd $SOURCES

log "Building sway 1.10 (-Dwerror=false -Dman-pages=disabled)"
wget -nc https://github.com/swaywm/sway/releases/download/1.10/sway-1.10.tar.gz
tar xf sway-1.10.tar.gz && cd sway-1.10
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Dwerror=false -Dman-pages=disabled
ninja -C build && sudo ninja -C build install
cd $SOURCES

# ============================================================
# PHASE 6: SWAY DESKTOP TOOLS
# ============================================================

log "Building swaybg"
wget -nc https://github.com/swaywm/swaybg/releases/download/v1.2.1/swaybg-1.2.1.tar.gz
tar xf swaybg-1.2.1.tar.gz && cd swaybg-1.2.1
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Dman-pages=disabled
ninja -C build && sudo ninja -C build install
cd $SOURCES

log "Building foot terminal"
wget -nc https://codeberg.org/dnkl/foot/releases/download/1.21.0/foot-1.21.0.tar.gz
tar xf foot-1.21.0.tar.gz && cd foot-1.21.0
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Dtests=false
ninja -C build && sudo ninja -C build install
cd $SOURCES

log "Building swayidle"
wget -nc https://github.com/swaywm/swayidle/releases/download/1.8.0/swayidle-1.8.0.tar.gz
tar xf swayidle-1.8.0.tar.gz && cd swayidle-1.8.0
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Dman-pages=disabled
ninja -C build && sudo ninja -C build install
cd $SOURCES

log "Building swaylock (WITHOUT PAM — setuid root instead; PAM+setuid rejected)"
wget -nc https://github.com/swaywm/swaylock/releases/download/v1.8.4/swaylock-1.8.4.tar.gz
tar xf swaylock-1.8.4.tar.gz && cd swaylock-1.8.4
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Dpam=disabled -Dman-pages=disabled
ninja -C build && sudo ninja -C build install
sudo chmod u+s /bin/swaylock
cd $SOURCES

log "Building grim + slurp (screenshots)"
wget -nc https://git.sr.ht/~emersion/grim/refs/download/v1.4.1/grim-1.4.1.tar.xz
tar xf grim-1.4.1.tar.xz && cd grim-1.4.1
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Dman-pages=disabled
ninja -C build && sudo ninja -C build install
cd $SOURCES

wget -nc https://github.com/emersion/slurp/releases/download/v1.5.0/slurp-1.5.0.tar.gz
tar xf slurp-1.5.0.tar.gz && cd slurp-1.5.0
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Dman-pages=disabled
ninja -C build && sudo ninja -C build install
cd $SOURCES

log "Building wl-clipboard"
wget -nc https://github.com/bugaevc/wl-clipboard/releases/download/v2.2.1/wl-clipboard-2.2.1.tar.gz
tar xf wl-clipboard-2.2.1.tar.gz && cd wl-clipboard-2.2.1
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Dman-pages=false
ninja -C build && sudo ninja -C build install
cd $SOURCES

log "Building mako (notifications)"
wget -nc https://github.com/emersion/mako/releases/download/v1.9.0/mako-1.9.0.tar.gz
tar xf mako-1.9.0.tar.gz && cd mako-1.9.0
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Dman-pages=disabled
ninja -C build && sudo ninja -C build install
cd $SOURCES

log "Building scdoc (required by fuzzel)"
wget -nc https://git.sr.ht/~sircmpwn/scdoc/archive/1.11.3.tar.gz -O scdoc-1.11.3.tar.gz
tar xf scdoc-1.11.3.tar.gz && cd scdoc-1.11.3
make -j$JOBS && sudo make install
# fuzzel hardcodes /usr/local/bin — symlink required
sudo ln -sf /bin/scdoc /usr/local/bin/scdoc 2>/dev/null || true
cd $SOURCES

log "Building fuzzel (app launcher)"
# NOTE: tllist header-only lib required first
wget -nc https://codeberg.org/dnkl/tllist/archive/1.1.0.tar.gz -O tllist-1.1.0.tar.gz
tar xf tllist-1.1.0.tar.gz && cd tllist-1.1.0
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release
ninja -C build && sudo ninja -C build install
cd $SOURCES

wget -nc https://codeberg.org/dnkl/fuzzel/archive/1.11.1.tar.gz -O fuzzel-1.11.1.tar.gz
tar xf fuzzel-1.11.1.tar.gz && cd fuzzel-1.11.1
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Dman-pages=disabled
ninja -C build && sudo ninja -C build install
cd $SOURCES

# ============================================================
# PHASE 7: AUDIO (PipeWire stack)
# ============================================================

log "Building PipeWire"
wget -nc https://gitlab.freedesktop.org/pipewire/pipewire/-/archive/1.2.7/pipewire-1.2.7.tar.gz
tar xf pipewire-1.2.7.tar.gz && cd pipewire-1.2.7
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Dsession-managers=[] -Dtests=disabled -Dexamples=disabled
ninja -C build && sudo ninja -C build install
cd $SOURCES

log "Building WirePlumber"
wget -nc https://gitlab.freedesktop.org/pipewire/wireplumber/-/archive/0.5.8/wireplumber-0.5.8.tar.gz
tar xf wireplumber-0.5.8.tar.gz && cd wireplumber-0.5.8
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Dtests=false -Ddoc=disabled
ninja -C build && sudo ninja -C build install
cd $SOURCES

# ============================================================
# PHASE 8: WAYBAR
# GTK C++ chain required: libsigc++ → glibmm → cairomm → pangomm → atkmm → gtkmm
# All must stay on 2.x series for sigc++ 2.0 compatibility
# ============================================================

log "Building libsigc++ 2.12.1"
wget -nc https://download.gnome.org/sources/libsigc++/2.12/libsigc++-2.12.1.tar.xz
tar xf libsigc++-2.12.1.tar.xz && cd libsigc++-2.12.1
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Dbuild-examples=false -Dbuild-documentation=false
ninja -C build && sudo ninja -C build install
cd $SOURCES

log "Building glibmm 2.66.7"
wget -nc https://download.gnome.org/sources/glibmm/2.66/glibmm-2.66.7.tar.xz
tar xf glibmm-2.66.7.tar.xz && cd glibmm-2.66.7
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Dbuild-examples=false -Dbuild-documentation=false
ninja -C build && sudo ninja -C build install
cd $SOURCES

log "Building cairomm 1.14.5"
wget -nc https://www.cairographics.org/releases/cairomm-1.14.5.tar.xz
tar xf cairomm-1.14.5.tar.xz && cd cairomm-1.14.5
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Dbuild-examples=false -Dbuild-documentation=false
ninja -C build && sudo ninja -C build install
cd $SOURCES

log "Building pangomm 2.46.4"
wget -nc https://download.gnome.org/sources/pangomm/2.46/pangomm-2.46.4.tar.xz
tar xf pangomm-2.46.4.tar.xz && cd pangomm-2.46.4
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Dbuild-documentation=false
ninja -C build && sudo ninja -C build install
cd $SOURCES

log "Building atk + atkmm"
wget -nc https://download.gnome.org/sources/atk/2.38/atk-2.38.0.tar.xz
tar xf atk-2.38.0.tar.xz && cd atk-2.38.0
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Dintrospection=false
ninja -C build && sudo ninja -C build install
cd $SOURCES

wget -nc https://download.gnome.org/sources/atkmm/2.28/atkmm-2.28.4.tar.xz
tar xf atkmm-2.28.4.tar.xz && cd atkmm-2.28.4
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Dbuild-documentation=false
ninja -C build && sudo ninja -C build install
cd $SOURCES

log "Building gdk-pixbuf (standalone — required before gtkmm)"
wget -nc https://download.gnome.org/sources/gdk-pixbuf/2.42/gdk-pixbuf-2.42.12.tar.xz
tar xf gdk-pixbuf-2.42.12.tar.xz && cd gdk-pixbuf-2.42.12
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Dintrospection=disabled -Dman=false -Dgtk_doc=false
ninja -C build && sudo ninja -C build install
cd $SOURCES

log "Building gtkmm 3.24.9"
wget -nc https://download.gnome.org/sources/gtkmm/3.24/gtkmm-3.24.9.tar.xz
tar xf gtkmm-3.24.9.tar.xz && cd gtkmm-3.24.9
mkdir -p build && meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Dbuild-examples=false -Dbuild-documentation=false
ninja -C build && sudo ninja -C build install
cd $SOURCES

log "Building waybar 0.11.0 deps and waybar"
# jsoncpp, fmt, spdlog, libnl required by waybar
for pkg in jsoncpp-1.9.6 fmt-11.1.4 spdlog-1.15.1; do
    echo "Install $pkg via cmake from sources..."
done

wget -nc https://github.com/Alexays/Waybar/releases/download/0.11.0/waybar-0.11.0.tar.xz
tar xf waybar-0.11.0.tar.xz && cd waybar-0.11.0
rm -rf build
meson setup build --prefix=/usr --libdir=lib --buildtype=release \
    -Dman-pages=disabled -Dtests=disabled
ninja -C build && sudo ninja -C build install
cd $SOURCES

log "Done! Sway stack installed."
log "Launch with: WLR_DRM_DEVICES=/dev/dri/card1 sway"
log "Or add to ~/.bash_profile: export WLR_DRM_DEVICES=/dev/dri/card1"
