# 🕵️ Ultimate OSINT Tools Installer

Turn a fresh **Kali Linux** box into an **OSINT-ready workstation** with one script.  
Run it as a **regular user** (script uses `sudo` when needed), it’s **idempotent**, and ships with a built-in **validator** and **updater**.

---

## ✨ Features (at a glance)

- **APT self-heal + Kali keyring refresh** (handles flaky mirrors, broken deps)
- Installs core tools (with smart fallbacks):
  - **Shodan CLI** (auto-init via `SHODAN_API_KEY`, or cleanly deferred)
  - **Sherlock**
  - **PhoneInfoga** 
  - **SpiderFoot** 
  - **sn0int** 
  - **Metagoofil**, **Sublist3r**
  - **StegHide** + **StegSeek** (fast cracker)
  - **StegOSuite**
  - **ExifTool**, **Tor**, **Tor Browser Launcher**
  - **Translate Shell** 
- **Firefox hardening via enterprise policies**:
  - Delete cookies/history on shutdown
  - Block geo/microphone/camera by default
  - Strict tracking protection + anti-telemetry
  - Bookmarks toolbar shown with an **OSINT** folder preloaded (Shodan, Censys, VirusTotal, Wayback, etc.)
- **System-wide wrappers/symlinks** so tools are on `PATH` for all users
- **OSINT Updater** desktop launcher (runs via `pkexec`)
- **Trace Labs CTF Guide** PDF placed on the Desktop
- **Validator** to sanity-check versions, PATH, repo keys, policy files

---

## 🚀 Quick Start (Kali)

```bash
cd ~/Desktop
# Download, make executable, run as your normal user (sudo permissions required):
wget -O osint-tool.sh "https://github.com/404Yeti/ultimate-osint-tools/blob/main/osint-tool.sh?raw=1"
chmod +x osint-tool.sh

# (optional) auto-init Shodan during setup:
export SHODAN_API_KEY="YOUR_API_KEY"

./osint-tool.sh

