#!/bin/bash
# =============================================================================
# sable-microtools-fixes.sh — Fix failed packages from first run
# Run as root from /sources
# =============================================================================

set -uo pipefail

LOG=/var/log/sable-microtools-fixes.log
FAILED=()
INSTALLED=()

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

header() { echo -e "\n${BOLD}=== $* ===${NC}\n" | tee -a $LOG; }
ok()     { echo -e "${GREEN}  ✓ $*${NC}" | tee -a $LOG; INSTALLED+=("$1"); }
fail()   { echo -e "${RED}  ✗ $* FAILED${NC}" | tee -a $LOG; FAILED+=("$1"); }
has()    { command -v "$1" &>/dev/null; }

echo "=== SableLinux Micro-Tools Fixes — $(date) ===" | tee -a $LOG
cd /sources

# =============================================================================
header "nvme-cli — fix directory structure"
# =============================================================================
if ! has nvme; then
    rm -rf nvme-cli-2.12* nvme-cli-2.12
    wget -q https://github.com/linux-nvme/nvme-cli/archive/refs/tags/v2.12.tar.gz \
        -O nvme-cli-2.12.tar.gz
    tar xf nvme-cli-2.12.tar.gz
    # tarball extracts to nvme-cli-2.12
    cd nvme-cli-2.12
    mkdir -p build
    cmake -B build \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_BUILD_TYPE=Release \
        -DNVME_BUILD_TESTS=OFF \
        >> $LOG 2>&1 && \
    cmake --build build -j14 >> $LOG 2>&1 && \
    cmake --install build >> $LOG 2>&1 && ok nvme-cli || fail nvme-cli
    cd /sources
else
    echo "  ↷ nvme already installed"
fi

# =============================================================================
header "hdparm — fix source URL"
# =============================================================================
if ! has hdparm; then
    rm -rf hdparm*
    wget -q https://sourceforge.net/projects/hdparm/files/hdparm/hdparm-9.65.tar.gz \
        -O hdparm-9.65.tar.gz >> $LOG 2>&1 || \
    wget -q https://github.com/Distrotech/hdparm/archive/refs/tags/v9.65.tar.gz \
        -O hdparm-9.65.tar.gz >> $LOG 2>&1
    tar xf hdparm-9.65.tar.gz
    cd hdparm-9.65 2>/dev/null || cd hdparm-v9.65 2>/dev/null || \
        cd $(ls -d hdparm* | head -1)
    make -j14 >> $LOG 2>&1 && make install >> $LOG 2>&1 && ok hdparm || fail hdparm
    cd /sources
else
    echo "  ↷ hdparm already installed"
fi

# =============================================================================
header "lm-sensors — fix build"
# =============================================================================
if ! has sensors; then
    rm -rf lm-sensors*
    wget -q https://github.com/groeck/lm-sensors/archive/refs/tags/V3-6-0.tar.gz \
        -O lm-sensors-3.6.0.tar.gz
    tar xf lm-sensors-3.6.0.tar.gz
    cd lm-sensors-V3-6-0
    make -j14 PREFIX=/usr ETCDIR=/etc MANDIR=/usr/share/man >> $LOG 2>&1 && \
    make install PREFIX=/usr ETCDIR=/etc MANDIR=/usr/share/man >> $LOG 2>&1 && \
    ok lm-sensors || fail lm-sensors
    cd /sources
else
    echo "  ↷ sensors already installed"
fi

# =============================================================================
header "memtester — GCC 15 fix"
# =============================================================================
if ! has memtester; then
    rm -rf memtester*
    wget -q https://pyropus.ca./software/memtester/old-versions/memtester-4.6.0.tar.gz
    tar xf memtester-4.6.0.tar.gz
    cd memtester-4.6.0
    CFLAGS="-std=gnu17 -O2" make -j14 >> $LOG 2>&1 && \
    make install >> $LOG 2>&1 && ok memtester || fail memtester
    cd /sources
else
    echo "  ↷ memtester already installed"
fi

# =============================================================================
header "iotop — correct package name"
# =============================================================================
if ! has iotop; then
    pip3 install --break-system-packages iotop >> $LOG 2>&1 && \
    ok iotop || fail iotop
else
    echo "  ↷ iotop already installed"
fi

# =============================================================================
header "lsof — fix repo"
# =============================================================================
if ! has lsof; then
    rm -rf lsof*
    wget -q https://github.com/lsof-org/lsof/releases/download/4.99.3/lsof-4.99.3.tar.gz
    tar xf lsof-4.99.3.tar.gz
    cd lsof-4.99.3
    ./configure --prefix=/usr >> $LOG 2>&1 && \
    make -j14 >> $LOG 2>&1 && \
    make install >> $LOG 2>&1 && ok lsof || fail lsof
    cd /sources
else
    echo "  ↷ lsof already installed"
fi

# =============================================================================
header "7-zip — replaces p7zip + zip + unzip (all GCC 15 broken)"
# =============================================================================
if ! has 7zz && ! has 7z; then
    rm -rf 7zip*
    wget -q https://github.com/ip7z/7zip/archive/refs/tags/24.09.tar.gz \
        -O 7zip-24.09.tar.gz
    tar xf 7zip-24.09.tar.gz
    cd 7zip-24.09/CPP/7zip/Bundles/Alone2
    mkdir -p b/g
    make -j14 -f ../../cmpl_gcc.mak >> $LOG 2>&1 && \
    cp b/g/7zz /usr/local/bin/ && \
    ln -sf /usr/local/bin/7zz /usr/local/bin/7z && \
    ok 7-zip || fail 7-zip
    cd /sources
else
    echo "  ↷ 7-zip already installed"
fi

# =============================================================================
header "inotify-tools — run autoreconf first"
# =============================================================================
if ! has inotifywait; then
    rm -rf inotify-tools*
    wget -q https://github.com/inotify-tools/inotify-tools/releases/download/4.23.9.0/inotify-tools-4.23.9.0.tar.gz
    tar xf inotify-tools-4.23.9.0.tar.gz
    cd inotify-tools-4.23.9.0
    autoreconf -fiv >> $LOG 2>&1
    ./configure --prefix=/usr >> $LOG 2>&1 && \
    make -j14 >> $LOG 2>&1 && \
    make install >> $LOG 2>&1 && ok inotify-tools || fail inotify-tools
    cd /sources
else
    echo "  ↷ inotifywait already installed"
fi

# =============================================================================
header "macchanger — run autoreconf first"
# =============================================================================
if ! has macchanger; then
    rm -rf macchanger*
    wget -q https://github.com/alobbs/macchanger/releases/download/1.8.0/macchanger-1.8.0.tar.gz
    tar xf macchanger-1.8.0.tar.gz
    cd macchanger-1.8.0
    autoreconf -fiv >> $LOG 2>&1
    ./configure --prefix=/usr >> $LOG 2>&1 && \
    make -j14 >> $LOG 2>&1 && \
    make install >> $LOG 2>&1 && ok macchanger || fail macchanger
    cd /sources
else
    echo "  ↷ macchanger already installed"
fi

# =============================================================================
header "ngrep — autoreconf + correct source"
# =============================================================================
if ! has ngrep; then
    rm -rf ngrep*
    wget -q https://github.com/jpr5/ngrep/archive/refs/tags/V1_47.tar.gz \
        -O ngrep-1.47.tar.gz
    tar xf ngrep-1.47.tar.gz
    cd ngrep-V1_47
    autoreconf -fiv >> $LOG 2>&1
    ./configure --prefix=/usr >> $LOG 2>&1 && \
    make -j14 >> $LOG 2>&1 && \
    make install >> $LOG 2>&1 && ok ngrep || fail ngrep
    cd /sources
else
    echo "  ↷ ngrep already installed"
fi

# =============================================================================
header "proxychains-ng — correct fork + autoreconf"
# =============================================================================
if ! has proxychains4; then
    rm -rf proxychains*
    wget -q https://github.com/rofl0r/proxychains-ng/archive/refs/tags/v4.17.tar.gz \
        -O proxychains-ng-4.17.tar.gz
    tar xf proxychains-ng-4.17.tar.gz
    cd proxychains-ng-4.17
    autoreconf -fiv >> $LOG 2>&1
    ./configure --prefix=/usr --sysconfdir=/etc >> $LOG 2>&1 && \
    make -j14 >> $LOG 2>&1 && \
    make install >> $LOG 2>&1 && \
    make install-config >> $LOG 2>&1 && \
    ok proxychains-ng || fail proxychains-ng
    cd /sources
else
    echo "  ↷ proxychains4 already installed"
fi

# =============================================================================
header "rhash — fix URL"
# =============================================================================
if ! has rhash; then
    rm -rf RHash* rhash*
    wget -q https://github.com/rhash/RHash/releases/download/v1.4.5/rhash-1.4.5-src.tar.gz
    tar xf rhash-1.4.5-src.tar.gz
    cd RHash-1.4.5
    ./configure --prefix=/usr >> $LOG 2>&1 && \
    make -j14 >> $LOG 2>&1 && \
    make install >> $LOG 2>&1 && ok rhash || fail rhash
    cd /sources
else
    echo "  ↷ rhash already installed"
fi

# =============================================================================
header "recon-ng — git clone instead of pip"
# =============================================================================
if ! has recon-ng; then
    rm -rf recon-ng
    git clone --depth=1 https://github.com/lanmaster53/recon-ng.git >> $LOG 2>&1
    cd recon-ng
    pip3 install --break-system-packages -r REQUIREMENTS >> $LOG 2>&1
    cp recon-ng /usr/local/bin/
    chmod +x /usr/local/bin/recon-ng
    # Create wrapper
    cat > /usr/local/bin/recon-ng << 'WRAPPER'
#!/bin/bash
cd /sources/recon-ng
exec python3 recon-ng "$@"
WRAPPER
    chmod +x /usr/local/bin/recon-ng
    ok recon-ng || fail recon-ng
    cd /sources
else
    echo "  ↷ recon-ng already installed"
fi

# =============================================================================
header "exiftool — fix tarball and directory"
# =============================================================================
if ! has exiftool; then
    rm -rf Image-ExifTool* exiftool*
    wget -q https://exiftool.org/Image-ExifTool-13.00.tar.gz
    tar xf Image-ExifTool-13.00.tar.gz
    ls -la | grep -i exif >> $LOG 2>&1
    cd Image-ExifTool-13.00 2>/dev/null || \
        cd $(ls -d Image-ExifTool* | head -1)
    ls Makefile.PL >> $LOG 2>&1
    perl Makefile.PL >> $LOG 2>&1 && \
    make -j14 >> $LOG 2>&1 && \
    make install >> $LOG 2>&1 && ok exiftool || fail exiftool
    cd /sources
else
    echo "  ↷ exiftool already installed"
fi

# =============================================================================
header "Boehm GC + w3m"
# =============================================================================
if ! has w3m; then
    # Build libgc (Boehm GC) first — w3m dependency
    rm -rf gc* bdwgc*
    wget -q https://github.com/ivmai/bdwgc/releases/download/v8.2.8/gc-8.2.8.tar.gz
    tar xf gc-8.2.8.tar.gz
    cd gc-8.2.8
    ./configure --prefix=/usr --enable-static=no >> $LOG 2>&1 && \
    make -j14 >> $LOG 2>&1 && \
    make install >> $LOG 2>&1 && ok libgc || { fail libgc; cd /sources; }
    ldconfig
    cd /sources

    # Now build w3m
    rm -rf w3m*
    wget -q https://github.com/tats/w3m/archive/refs/tags/v0.5.3+git20230121.tar.gz \
        -O w3m-0.5.3.tar.gz
    tar xf w3m-0.5.3.tar.gz
    cd w3m-v0.5.3+git20230121 2>/dev/null || \
        cd $(ls -d w3m* | head -1)
    CFLAGS="-std=gnu17 -O2" ./configure \
        --prefix=/usr \
        --without-mouse \
        --without-ssl-verify >> $LOG 2>&1 && \
    make -j14 >> $LOG 2>&1 && \
    make install >> $LOG 2>&1 && ok w3m || fail w3m
    cd /sources
else
    echo "  ↷ w3m already installed"
fi

# =============================================================================
header "Summary"
# =============================================================================
echo ""
echo -e "${GREEN}Fixed/Installed (${#INSTALLED[@]}):${NC} ${INSTALLED[*]:-none}" | tee -a $LOG
echo -e "${RED}Still Failed    (${#FAILED[@]}):${NC} ${FAILED[*]:-none}" | tee -a $LOG
echo ""
echo "Full log: $LOG"
