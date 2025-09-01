# 🕵️ Ultimate OSINT Tools Installer

Turn a fresh **Kali Linux** box into an **OSINT-ready workstation** with one script.  
Runs as a **regular user** (no `sudo` needed), is **idempotent**, and includes a built-in **validator** and **updater**.

---

## ✨ Features (at a glance)

- **APT self-heal + Kali keyring refresh** to avoid flaky installs
- Installs core tools:
  - **Shodan CLI** (patched so it “just works”)
  - **Sherlock**
  - **PhoneInfoga** (Go build with upstream fallback)
  - **SpiderFoot** (APT or pipx)
  - **sn0int** (apt.vulns.sexy or Rust fallback)
  - **Metagoofil**, **Sublist3r**
  - **StegOSuite** (APT or source)
  - **ExifTool**, **Tor**, **Tor Browser Launcher**
  - **Translate Shell** (`trans`) — replaces DeepL (no API key)
- **System-wide wrappers/symlinks** so tools are on `PATH` for all users
- **OSINT Updater** desktop launcher (runs via `pkexec`)
- **Trace Labs CTF Guide** PDF dropped on the Desktop
- **Validator** to sanity-check versions, PATH, and repo keys

---

## 🚀 Quick Start (Kali)

```bash
cd ~/Desktop
# Download (save as osint-tools.sh), make executable, and run as a regular user:
wget -O osint-tools.sh "https://github.com/404Yeti/ultimate-osint-tools/blob/main/osint-tool.sh?raw=1"
chmod +x osint-tools.sh
./osint-tools.sh
