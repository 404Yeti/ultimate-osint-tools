# 🕵️ Ultimate OSINT Tools Installer

A one-file bootstrap script that turns a fresh **Kali Linux** box into an **OSINT-ready workstation**.  
Runs as a regular user or with `sudo`, is idempotent, and ships with a built-in **validator** and **updater**.

---

## ✨ What You Get

- ✅ **APT self-heal + Kali keyring refresh** to avoid flaky installs  
- 🧰 Installs and wires up core tools:
  - **Shodan CLI** (via `pipx`, patched so `pkg_resources` errors don’t happen)
  - **Sherlock**
  - **PhoneInfoga** (Go build with upstream fallback)
  - **SpiderFoot** (APT or `pipx` fallback)
  - **sn0int** (via `apt.vulns.sexy` repo or Rust fallback)
  - **Metagoofil**
  - **Sublist3r**
  - **StegOSuite** (APT or source build)
  - **ExifTool**, **Tor**, **Tor Browser Launcher**
  - **Translate Shell** (`trans`) — replaces DeepL CLI (no API key needed)
- 🔗 **System-wide wrappers/symlinks** so tools are on `PATH` for all users:
  - pipx apps (`shodan`, `sherlock`, etc.)
  - Cargo tools (`cargo`, `rustc`, `rustup`, `sn0int`)
- 🧭 Desktop niceties:
  - **OSINT Updater** launcher (runs via `pkexec`)
  - **Trace Labs CTF Contestant Guide** PDF to Desktop
- 🔍 **Validator** to sanity-check versions, PATH, and repo keys

---

## 🚀 Quick Start (Kali)

```bash
cd ~/Desktop
# choose one:
wget https://raw.githubusercontent.com/<your-username>/<your-repo>/main/osint-tools.sh
# or
curl -O https://raw.githubusercontent.com/<your-username>/<your-repo>/main/osint-tools.sh

chmod +x osint-tools.sh
# Run as your normal user (recommended). The script will sudo when needed:
./osint-tools.sh
# or explicitly:
sudo ./osint-tools.sh
