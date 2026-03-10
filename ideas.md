# SableLinux — Project Ideas & Notes

## Compliance-Aware OSINT Agent

An agentic app that takes a target (domain, IP, company, person) as input and:

1. Researches jurisdiction-specific legality of OSINT targeting (CFAA, GDPR, local laws)
2. Determines which OSINT techniques are legally applicable to that specific target type
3. Executes permitted passive recon tools (theHarvester, whois, DNS, etc.)
4. Synthesizes a structured report: legal framework + findings + recommended next steps

Key differentiator: compliance-aware before execution — reasons about what it's legally
allowed to gather before gathering it. Relevant to professional red team engagements
where rules of engagement matter.

Prototype of the commercial pentest automation and report writing product.

Stack: Python, LangGraph, Anthropic/OpenAI API, theHarvester, whois, DNS tools.

---
## 2026-03-10

## Agentic SableLinux System Intelligence Tool

### Concept
An AI-assisted agent that monitors and makes recommendations for a source-built Linux system that has no package manager and no automatic update mechanism. Fills the gap left by the absence of `apt update` / `pacman -Syu`.

### Proposed Capabilities

#### 1. Kernel Tracking & CVE Monitoring
- Track current kernel version (6.16.1) against latest stable releases
- Monitor kernel.org for new stable releases in the 6.x series
- Query NVD/CVE databases for kernel CVEs affecting the running version
- Recommend specific patches or flag upgrade urgency based on severity
- Check dmesg for unknown device or driver load failures

#### 2. Hardware Support Delta
- Compare installed kernel version against upstream changelogs
- Flag new driver support added after 6.16 relevant to installed hardware
- PCIe, Wi-Fi, Bluetooth, USB controller support tracking
- GPU driver improvements (especially RDNA4/gfx1201 — bleeding edge)

#### 3. Security Patch Tracking
- Continuous CVE monitoring for: kernel, OpenSSL, OpenSSH, glibc, sudo, PAM
- Severity scoring and prioritization (CVSS)
- Patch availability and backport feasibility assessment
- Special focus on internet-facing services (SSH on port 2269)

#### 4. Package Version Intelligence
- Track all installed BLFS packages against upstream releases
- Flag security-relevant updates vs. feature updates
- Dependency chain impact analysis
- Build order recommendations for updates

#### 5. Kernel Module & API Compatibility
- Track kernel internal API changes that could affect installed modules
- Flag potential incompatibilities before kernel upgrades
- Module rebuild requirements after kernel updates

### Technical Approach
- Local LLM inference backend (llama.cpp + ROCm on RDNA4) — air-gappable, no API costs
- Web scraping agents for: kernel.org, NVD, BLFS changelogs, upstream project releases
- SQLite local database for tracking installed versions and known CVEs
- Sway/waybar integration for passive alerts
- CLI interface for detailed reports

### Commercial Angle
- Directly supports the SableLinux acquisition thesis
- Unique value prop: security-aware system intelligence for from-scratch Linux builds
- No equivalent exists for LFS/BLFS-based systems
- Extensible to any source-built distro

