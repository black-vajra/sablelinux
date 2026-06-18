
---

## DNS + Network Recon Stack — 2026-04-08

### DNS Configuration
- Systemwide DNS changed to Quad9 (9.9.9.9) via /etc/resolv.conf
- Firefox TTS (Read Aloud extension) broke after DNS change — root cause identified:
  Google WaveNet voice proxied through cxl-services.appspot.com returning 503
  Workaround: switched to Microsoft voice in Read Aloud settings
- sudo DNS routing issue identified: default WireGuard route (link-scope, no gateway)
  prevented root from resolving DNS — fixed with:
  sudo ip route add default via 10.6.0.1 dev wg0 metric 50
  (affects sudo make install steps that fetch during install)

### Network Recon / Pentest Stack

#### DNS Tools
- bind 9.20.22 — dig, host, nslookup, full DNS toolset
  - Deps: userspace-rcu 0.15.1, libuv 1.50.0
  - Built --disable-doh (nghttp2 not installed)

#### Network Discovery
- whois 5.5.23 — domain/IP WHOIS queries
- traceroute 2.1.5 — network path tracing
- mtr 0.95 — combined traceroute+ping, live per-hop stats
- arp-scan 1.10.0 — ARP-based host discovery
- netdiscover 0.10 — passive/active ARP recon
  - GCC 15 fix: usage() prototype corrected (void → char *)
- nbtscan 1.7.2 — NetBIOS name enumeration

#### LDAP / SMB
- openldap 2.6.13 — ldapsearch + client libs (--disable-slapd)
- enum4linux-ng 1.3.10 — Windows/Samba enumeration (Python)
  - impacket 0.13.0, ldap3 2.9.1, ldapdomaindump 0.10.0 installed
  - Pending: smbclient (samba build) for full functionality

#### SNMP
- net-snmp 5.9.4 — snmpwalk, snmpget, full SNMP toolset
- onesixtyone 0.3.4 — fast SNMP community string scanner

#### Go-based Recon
- dnsx 1.2.3 — DNS enumeration and brute force
- subfinder — subdomain discovery
- amass — attack surface mapping (OWASP)

#### Notes
- Go tools installed to ~/go/bin; PATH export required:
  export PATH=$PATH:/usr/local/go/bin:~/go/bin

---

## RE / Binary Exploitation Stack — 2026-04-08

### System Tracing
- strace 6.13 — system call tracer
- ltrace 0.8.1 — library call tracer (built from git, no formal release)
- valgrind 3.24.0 — memory error detector, profiler

### Disassembly / Emulation Frameworks
- capstone 5.0.6 — disassembly framework (C + Python bindings)
- keystone 0.9.2 — assembler framework (C + Python bindings)
  - GCC 15 fixes: #include <cstdint> added to STLExtras.h, -std=c++14
- unicorn 2.1.3 — CPU emulator framework (C + Python bindings)

### Binary Analysis (Python)
- pyelftools — ELF parsing library
- pefile — PE file analysis
- checksec.py — binary hardening checker
- z3-solver — SMT solver (angr dependency)
- angr — binary analysis framework

### Reverse Engineering Tools
- rizin 0.9.0 — radare2 fork, modern RE framework
  - rz-ghidra: abandoned — API incompatibility with rizin 0.9.0 at all tagged versions
- r2dec — radare2 decompiler plugin (installed via r2pm)
  - sudo DNS fix required for r2pm -U to reach GitHub
- Ghidra headless decompiler — CLI wrapper around Ghidra 12.0.4
  - /usr/local/bin/ghidra-headless → /opt/ghidra_12.0.4_PUBLIC/support/analyzeHeadless
  - /usr/local/bin/decompile — wrapper script: imports binary, runs DecompileAllFunctions.java
  - DecompileAllFunctions.java installed to Ghidra decompiler scripts directory
  - Output written to /tmp/decompiled.c (or specified path)
  - Ghidra 11.3.1 removed (superseded by 12.0.4)
  - Ghidra native binaries chmod +x applied (decompile, demangler_gnu_v2_41)

### Exploitation / CTF Tools
- one_gadget 1.10.0 — one-shot RCE gadget finder (Ruby gem)
- seccomp-tools 2 gems — seccomp filter analysis
  - RubyGems updated (noted for git commit)
- heaptrace 2.2.8 — heap operation tracer for exploit dev

### Fuzzing
- AFL++ — coverage-guided fuzzer, full install with gcc_plugin
- honggfuzz 2.6 — structure-aware fuzzer
  - Deps: libunwind 1.8.1 (headers manually installed from source)
  - libiberty built from binutils-2.45 source, installed to /usr/lib/
  - Makefile patched: added -lz, -lzstd, -lsframe, -liberty to ARCH_LDFLAGS
  - libhfuzz.so skipped (libbfd.a not -fPIC compiled); main binary + hfuzz-cc installed manually

### Dynamic Instrumentation
- frida + frida-tools — dynamic instrumentation toolkit (pip3)
