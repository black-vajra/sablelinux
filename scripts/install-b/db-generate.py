#!/usr/bin/env python3
"""
db-generate.py — SableLinux hardware-db.json generator
Pulls linux-firmware WHENCE + pci.ids, emits installer/hardware-db.json

Sources:
  WHENCE   : https://raw.githubusercontent.com/endlessm/linux-firmware/master/WHENCE
  pci.ids  : https://raw.githubusercontent.com/pciutils/pciids/master/pci.ids

Run from repo root:
  python3 tools/db-generate.py
  python3 tools/db-generate.py --offline   # use cached files only
"""

import argparse
import json
import re
import sys
import urllib.request
from datetime import date
from pathlib import Path

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

WHENCE_URL  = "https://raw.githubusercontent.com/endlessm/linux-firmware/master/WHENCE"
PCIIDS_URL  = "https://raw.githubusercontent.com/pciutils/pciids/master/pci.ids"
CACHE_DIR   = Path("/tmp/sable-db-cache")
OUTPUT      = Path("installer/hardware-db.json")

LINUX_FIRMWARE_BASE = (
    "https://git.kernel.org/pub/scm/linux/kernel/git/"
    "firmware/linux-firmware.git/plain/"
)

# ---------------------------------------------------------------------------
# Driver filter table
# Only drivers in this map will appear in hardware-db.json.
# Keys are exact "Driver:" names from WHENCE.
# Values supply metadata we can't derive from WHENCE alone.
# ---------------------------------------------------------------------------

DRIVER_META = {
    # ── Intel WiFi ──────────────────────────────────────────────────────────
    "iwlwifi": {
        "class":          "wifi",
        "kernel_module":  "iwlwifi",
        "pci_vendor":     "8086",
        # device IDs we actually care about (modern hardware subset)
        # full list: https://wireless.wiki.kernel.org/en/users/drivers/iwlwifi
        "pci_devices": {
            # 7260 family
            "08b1": "Intel Wireless 7260",
            "08b2": "Intel Wireless 7260",
            "0890": "Intel Wireless 7260",
            "0891": "Intel Wireless 7260",
            # 3160 family
            "08b3": "Intel Wireless 3160",
            "08b4": "Intel Wireless 3160",
            # 7265 family (ASUS Q503UA target)
            "095a": "Intel Wireless 7265",
            "095b": "Intel Wireless 7265",
            # 3165/3168 family
            "3165": "Intel Wireless 3165",
            "3166": "Intel Wireless 3165",
            # 8260/8265 family
            "24f3": "Intel Wireless 8260",
            "24f4": "Intel Wireless 8260",
            "24fd": "Intel Wireless 8265",
            # 9260 family
            "2526": "Intel Wireless 9260",
            # Wi-Fi 6 family
            "2723": "Intel Wi-Fi 6 AX200",
            "02f0": "Intel Wi-Fi 6 AX201",
            "06f0": "Intel Wi-Fi 6 AX201",
            # Wi-Fi 6E family
            "43f0": "Intel Wi-Fi 6 AX210",
            "51f0": "Intel Wi-Fi 6E AX211",
            "51f1": "Intel Wi-Fi 6E AX211",
            "54f0": "Intel Wi-Fi 6E AX411",
            # Wi-Fi 7 family
            "7e40": "Intel Wi-Fi 7 BE200",
            "7740": "Intel Wi-Fi 7 BE201",
        },
    },

    # ── Realtek rtw88 (PCIe) ────────────────────────────────────────────────
    "rtw88": {
        "class":         "wifi",
        "kernel_module": "rtw88",
        "pci_vendor":    "10ec",
        "pci_devices": {
            "b822": "Realtek RTL8822BE",
            "c822": "Realtek RTL8822CE",
            "c821": "Realtek RTL8821CE",
            "b82c": "Realtek RTL8822CS",
            "d723": "Realtek RTL8723DE",
        },
    },

    # ── Realtek rtw89 (PCIe, WiFi 6/6E/7) ───────────────────────────────────
    "rtw89": {
        "class":         "wifi",
        "kernel_module": "rtw89",
        "pci_vendor":    "10ec",
        "pci_devices": {
            "8852": "Realtek RTL8852AE Wi-Fi 6",
            "a85b": "Realtek RTL8852AE Wi-Fi 6",
            "b85b": "Realtek RTL8852BE Wi-Fi 6",
            "b85c": "Realtek RTL8852CE Wi-Fi 6E",
            "8922": "Realtek RTL8922AE Wi-Fi 7",
        },
    },

    # ── MediaTek mt7925 (WiFi 7) ─────────────────────────────────────────────
    "mt7925": {
        "class":         "wifi",
        "kernel_module": "mt7925e",
        "pci_vendor":    "14c3",
        "pci_devices": {
            "0717": "MediaTek MT7925 Wi-Fi 7 (RZ717)",
            "0125": "MediaTek MT7925 Wi-Fi 7",
            "7925": "MediaTek MT7925 Wi-Fi 7",   # Z890/confirmed on real hardware
        },
    },

    # ── MediaTek mt7921 (WiFi 6) ─────────────────────────────────────────────
    "mt7921": {
        "class":         "wifi",
        "kernel_module": "mt7921e",
        "pci_vendor":    "14c3",
        "pci_devices": {
            "7961": "MediaTek MT7921 Wi-Fi 6",
            "7922": "MediaTek MT7922 Wi-Fi 6E",
            "0608": "MediaTek MT7921K (RZ608) Wi-Fi 6E",
            "0616": "MediaTek MT7922 Wi-Fi 6E",
        },
    },

    # ── Atheros ath11k (WCN6855 — Qualcomm) ─────────────────────────────────
    "ath11k": {
        "class":         "wifi",
        "kernel_module": "ath11k_pci",
        "pci_vendor":    "17cb",
        "pci_devices": {
            "1103": "Qualcomm WCN6855 Wi-Fi 6E",
        },
    },

    # ── Broadcom brcmfmac ─────────────────────────────────────────────────────
    "brcmfmac": {
        "class":         "wifi",
        "kernel_module": "brcmfmac",
        "pci_vendor":    "14e4",
        "pci_devices": {
            "43dc": "Broadcom BCM4355 Wi-Fi 5",
            "4464": "Broadcom BCM4364 Wi-Fi 5",
            "4488": "Broadcom BCM4377 Wi-Fi 6",
            "4425": "Broadcom BCM4378 Wi-Fi 6",
            "4433": "Broadcom BCM4387 Wi-Fi 6E",
        },
    },

    # ── Intel Bluetooth (btintel) ────────────────────────────────────────────
    # WHENCE groups all Intel BT firmware under "btusb", not "btintel".
    # Files are intel/ibt-*.sfi + intel/ibt-*.ddc; kernel selects the right one.
    "btintel": {
        "class":         "bluetooth",
        "kernel_module": "btintel",
        "whence_key":    "btusb",
        "fw_filter":     r"intel/ibt-.*\.(sfi|ddc)$",
        "usb_vendor":    "8087",
        "usb_devices": {
            "0025": "Intel Wireless Bluetooth (9260)",
            "0026": "Intel Wireless Bluetooth (AX200)",
            "0029": "Intel Wireless Bluetooth (AX201)",
            "0032": "Intel Wireless Bluetooth (AX210)",
            "0033": "Intel Wireless Bluetooth (AX211)",
            "0035": "Intel Wireless Bluetooth (BE200)",
            "0036": "Intel Wireless Bluetooth (BE201)",
        },
    },

    # ── Realtek Bluetooth (btrtl) ────────────────────────────────────────────
    "btrtl": {
        "class":         "bluetooth",
        "kernel_module": "btrtl",
        "usb_vendor":    "0bda",
        "usb_devices": {
            "b00a": "Realtek Bluetooth RTL8761A",
            "b009": "Realtek Bluetooth RTL8761B",
            "b00c": "Realtek Bluetooth RTL8822C",
            "b00b": "Realtek Bluetooth RTL8761B",
            "c820": "Realtek Bluetooth RTL8821C",
            "b820": "Realtek Bluetooth RTL8822B",
            "c123": "Realtek Bluetooth RTL8852A",
            "c852": "Realtek Bluetooth RTL8852A",
        },
    },

    # ── MediaTek Bluetooth (btmtk) ───────────────────────────────────────────
    "mt7925 bt": {  # note: WHENCE uses "mt7925" for BT too
        "class":         "bluetooth",
        "kernel_module": "btmtk",
        "usb_vendor":    "0e8d",
        "usb_devices": {
            "e025": "MediaTek Bluetooth MT7925",
            "e610": "MediaTek Bluetooth MT7922",
            "e608": "MediaTek Bluetooth MT7921",
        },
    },

    # ── regulatory.db — required by all WiFi adapters ───────────────────────
    "regulatory": {
        "class":         "wifi",
        "description":   "Wireless Regulatory Database (all WiFi adapters)",
        "kernel_module": None,
        "firmware_files": [
            "regulatory.db",
            "regulatory.db.p7s",
        ],
        "notes": "Unconditional — required by all wireless adapters.",
        "unconditional": True,
    },

    # ── i2c-hid (touchpads) ──────────────────────────────────────────────────
    "i2c-hid": {
        "class":         "input",
        "kernel_module": "i2c_hid",
        "notes":         "Generic i2c-hid; no firmware blob needed. Module must be loaded.",
    },

    # ── Intel CPU microcode ──────────────────────────────────────────────────
    "intel-ucode": {
        "class":         "cpu",
        "kernel_module": None,
        "notes":         "Unconditional — apply to all Intel systems.",
    },
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def fetch_or_cache(url: str, cache_name: str, offline: bool) -> str:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    cache_path = CACHE_DIR / cache_name
    if cache_path.exists():
        print(f"  [cache] {cache_name}")
        return cache_path.read_text(encoding="utf-8", errors="replace")
    if offline:
        print(f"  [ERROR] offline mode but no cache: {cache_path}", file=sys.stderr)
        sys.exit(1)
    print(f"  [fetch] {url}")
    with urllib.request.urlopen(url, timeout=30) as r:
        text = r.read().decode("utf-8", errors="replace")
    cache_path.write_text(text, encoding="utf-8")
    return text


def parse_whence(text: str) -> dict:
    """
    Parse WHENCE into:
      { driver_name: { "files": [...], "description": "..." } }
    """
    drivers = {}
    current = None
    for line in text.splitlines():
        m = re.match(r"^Driver:\s+(\S+)\s*(?:-\s*(.*))?$", line)
        if m:
            name = m.group(1)
            desc = (m.group(2) or "").strip()
            current = name
            if name not in drivers:
                drivers[name] = {"files": [], "description": desc}
            continue
        if current is None:
            continue
        m = re.match(r"^File:\s+(\S+)", line)
        if m:
            drivers[current]["files"].append(m.group(1))
        if re.match(r"^-{10}", line):
            current = None
    return drivers


def parse_pciids(text: str) -> dict:
    """
    Parse pci.ids into:
      { "vendor_id": { "name": "...", "devices": { "dev_id": "name" } } }
    """
    db = {}
    current_vendor = None
    for line in text.splitlines():
        if line.startswith("#") or not line.strip():
            continue
        if not line.startswith("\t"):
            m = re.match(r"^([0-9a-f]{4})\s+(.+)$", line)
            if m:
                current_vendor = m.group(1)
                db[current_vendor] = {"name": m.group(2).strip(), "devices": {}}
        elif line.startswith("\t") and not line.startswith("\t\t"):
            if current_vendor:
                m = re.match(r"^\t([0-9a-f]{4})\s+(.+)$", line)
                if m:
                    db[current_vendor]["devices"][m.group(1)] = m.group(2).strip()
    return db


# ---------------------------------------------------------------------------
# Entry builder
# ---------------------------------------------------------------------------

def build_entry(driver_key: str, meta: dict, whence: dict, pcidb: dict) -> list:
    """
    Returns a list of hardware-db entries for this driver.
    PCI drivers: one entry per device ID.
    USB drivers: one entry per device ID.
    Others: single entry.
    """
    # Find firmware files from WHENCE.
    # whence_key overrides the lookup (e.g. btintel lives under btusb in WHENCE).
    # fw_filter optionally narrows the file list by regex.
    whence_key = meta.get("whence_key", driver_key)
    fw_source  = whence.get(whence_key, {})
    raw_files  = fw_source.get("files", [])
    fw_desc    = fw_source.get("description", "")
    if "fw_filter" in meta:
        pattern   = re.compile(meta["fw_filter"])
        raw_files = [f for f in raw_files if pattern.search(f)]

    entries = []

    if "pci_vendor" in meta:
        vendor_id = meta["pci_vendor"]
        vendor_name = pcidb.get(vendor_id, {}).get("name", vendor_id)

        for dev_id, dev_name in meta.get("pci_devices", {}).items():
            # Filter firmware files relevant to this device where possible
            # For iwlwifi we match by device suffix pattern; otherwise all files
            fw_files = firmware_files_for_pci(driver_key, dev_id, raw_files)

            entry_id = f"{driver_key}-{dev_id}"
            entry = {
                "id":          entry_id,
                "class":       meta["class"],
                "description": dev_name,
                "match": {
                    "pci_ids":         [f"{vendor_id}:{dev_id}"],
                    "modalias_prefix": f"pci:v0000{vendor_id.upper()}d0000{dev_id.upper()}",
                },
                "kernel_module":  meta.get("kernel_module"),
                "firmware_files": fw_files,
                "firmware_source": "linux-firmware",
                "firmware_base_url": LINUX_FIRMWARE_BASE,
                "notes": meta.get("notes"),
            }
            entries.append(entry)

    elif "usb_vendor" in meta:
        vendor_id = meta["usb_vendor"]
        for dev_id, dev_name in meta.get("usb_devices", {}).items():
            entry_id = f"{driver_key}-{dev_id}"
            entry = {
                "id":          entry_id,
                "class":       meta["class"],
                "description": dev_name,
                "match": {
                    "usb_ids":         [f"{vendor_id}:{dev_id}"],
                    "modalias_prefix": f"usb:v{vendor_id.upper()}p{dev_id.upper()}",
                },
                "kernel_module":  meta.get("kernel_module"),
                "firmware_files": raw_files,
                "firmware_source": "linux-firmware",
                "firmware_base_url": LINUX_FIRMWARE_BASE,
                "notes": meta.get("notes"),
            }
            entries.append(entry)

    else:
        # No PCI/USB match — structural entry (intel-ucode, i2c-hid, regulatory, etc.)
        # meta["firmware_files"] overrides WHENCE lookup when explicitly set.
        fw_final = meta.get("firmware_files", raw_files)
        match_block = {}
        if meta.get("unconditional"):
            match_block["unconditional"] = True
        entry = {
            "id":            driver_key,
            "class":         meta["class"],
            "description":   meta.get("description", fw_desc or driver_key),
            "match":         match_block,
            "kernel_module": meta.get("kernel_module"),
            "firmware_files": fw_final,
            "firmware_source": "linux-firmware",
            "firmware_base_url": LINUX_FIRMWARE_BASE,
            "notes": meta.get("notes"),
        }
        entries.append(entry)

    return entries


def firmware_files_for_pci(driver: str, dev_id: str, all_files: list) -> list:
    """
    For drivers with many firmware variants (iwlwifi), narrow the file list
    to what's plausibly relevant for the given device ID.
    Falls back to all files if no pattern matches.
    """
    # iwlwifi: map device IDs to firmware family names
    IWLWIFI_MAP = {
        "0082": ["iwlwifi-6000g2a"],
        "0085": ["iwlwifi-6000g2b"],
        "095a": ["iwlwifi-7265D", "iwlwifi-7265"],
        "095b": ["iwlwifi-7265D", "iwlwifi-7265"],
        "08b1": ["iwlwifi-7260"],
        "08b2": ["iwlwifi-7260"],
        "08b3": ["iwlwifi-3160"],
        "08b4": ["iwlwifi-3160"],
        "3165": ["iwlwifi-3168"],
        "3166": ["iwlwifi-3168"],
        "24f3": ["iwlwifi-8000C", "iwlwifi-8265"],
        "24f4": ["iwlwifi-8000C", "iwlwifi-8265"],
        "24fd": ["iwlwifi-8265"],
        "0890": ["iwlwifi-7260"],
        "0891": ["iwlwifi-7260"],
        "2526": ["iwlwifi-9260"],
        "2723": ["iwlwifi-cc-a0", "iwlwifi-QuZ"],
        "02f0": ["iwlwifi-QuZ", "iwlwifi-cc"],
        "06f0": ["iwlwifi-QuZ", "iwlwifi-cc"],
        "43f0": ["iwlwifi-ty-a0"],
        "51f0": ["iwlwifi-so-a0", "iwlwifi-SoSnj"],
        "51f1": ["iwlwifi-so-a0", "iwlwifi-SoSnj"],
        "54f0": ["iwlwifi-so-a0"],
        "7e40": ["iwlwifi-BzBnj", "iwlwifi-Bz"],
        "7740": ["iwlwifi-BzBnj", "iwlwifi-Bz"],
    }
    # ── iwlwifi ─────────────────────────────────────────────────────────────
    if driver == "iwlwifi" and dev_id in IWLWIFI_MAP:
        prefixes = IWLWIFI_MAP[dev_id]
        matched = [f for f in all_files
                   if any(p in f for p in prefixes)]
        if matched:
            return matched

    # ── rtw88: each chip has its own firmware file ───────────────────────────
    RTW88_FW_MAP = {
        "b822": ["rtw88/rtw8822b_fw.bin"],
        "c822": ["rtw88/rtw8822c_fw.bin", "rtw88/rtw8822c_wow_fw.bin"],
        "c821": ["rtw88/rtw8821c_fw.bin"],
        "b82c": ["rtw88/rtw8822c_fw.bin", "rtw88/rtw8822c_wow_fw.bin"],
        "d723": ["rtw88/rtw8723d_fw.bin"],
    }
    if driver == "rtw88" and dev_id in RTW88_FW_MAP:
        return RTW88_FW_MAP[dev_id]

    return all_files


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--offline", action="store_true",
                    help="Use cached files only, no network")
    ap.add_argument("--output", default=str(OUTPUT),
                    help=f"Output path (default: {OUTPUT})")
    args = ap.parse_args()

    print("SableLinux hardware-db generator")
    print("=================================")

    print("\n[1] Fetching sources...")
    whence_text = fetch_or_cache(WHENCE_URL,  "WHENCE",   args.offline)
    pciids_text = fetch_or_cache(PCIIDS_URL,  "pci.ids",  args.offline)

    print("\n[2] Parsing...")
    whence = parse_whence(whence_text)
    pcidb  = parse_pciids(pciids_text)
    print(f"    WHENCE: {len(whence)} driver entries")
    print(f"    pci.ids: {len(pcidb)} vendors")

    print("\n[3] Building entries...")
    all_entries = []
    for driver_key, meta in DRIVER_META.items():
        entries = build_entry(driver_key, meta, whence, pcidb)
        all_entries.extend(entries)
        print(f"    {driver_key:20s} → {len(entries):3d} entries")

    db = {
        "version":  "1.0",
        "updated":  date.today().isoformat(),
        "sources": {
            "whence":  WHENCE_URL,
            "pci_ids": PCIIDS_URL,
        },
        "entry_count": len(all_entries),
        "entries": all_entries,
    }

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(db, indent=2), encoding="utf-8")

    print(f"\n[4] Done.")
    print(f"    Total entries : {len(all_entries)}")
    print(f"    Output        : {out_path}")


if __name__ == "__main__":
    main()
