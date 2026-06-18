
---

## Web Application Testing Stack — 2026-04-08

### Go-based Tools
- nuclei — template-based vulnerability scanner (ProjectDiscovery)
- httpx — HTTP probe and fingerprinting tool (ProjectDiscovery)
- katana — web crawler and spidering framework (ProjectDiscovery)
- dalfox — XSS scanner and parameter analysis tool
- cariddi — web crawler with secrets/endpoint discovery

### Python-based Tools
- wapiti3 — black-box web application vulnerability scanner (pip3)
- commix v4.2.dev16 — automated command injection exploitation
  - setup.py install to /usr/lib/python3.13/site-packages/
  - /usr/bin/commix wrapper: cd /sources/commix && python3 commix.py
- mitmproxy — CLI/TUI intercepting proxy for HTTP/HTTPS traffic analysis (pip3)

### Notes
- All Go tools installed to ~/go/bin
- PATH must include /usr/local/go/bin:~/go/bin for Go tools to be accessible
- Previously installed (complete): curl, ffuf, nikto, sqlmap, gobuster
