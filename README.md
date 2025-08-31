# 🕵️ Ultimate OSINT Tools Installer

A one-shot bootstrap script for setting up an **OSINT-ready environment** on **Kali Linux** (primary) and **Ubuntu** (partial support).
It automates installation, config, and sanity checks — plus a **desktop “OSINT Updater” launcher** and a built-in **validator**.

---

## 🚀 What you get

- 🔑 **Apt self-heal + Kali archive keyring refresh** (prevents broken package installs)
- 🧰 Installs core OSINT tooling (APT first, with safe fallbacks):
  - **Shodan CLI** (via pipx, with `pkg_resources` fix)
  - **Sherlock** (pipx from git)
  - **PhoneInfoga** (Go → upstream fallback)
  - **SpiderFoot** (APT → pipx fallback)
  - **sn0int** (adds `apt.vulns.sexy` repo + key; cargo fallback)
  - **Metagoofil** (APT → pipx fallback)
  - **Sublist3r** (APT → pipx fallback)
  - **StegOSuite** (APT → source build fallback)
  - **ExifTool**, **Tor**, **Tor Browser Launcher**
- 🌐 **DeepL Translator CLI** via Yarn **with a system-wide wrapper** (`/usr/local/bin/deepl`)
- 🐍 Python/pipx, 🦀 Rust (rustup/cargo), 🐹 Go (GOPATH/GOBIN), Node.js/npm/Yarn
- 🖱️ **Desktop launcher:** “**OSINT Updater**” (runs `apt` updates + refreshes pipx/go/cargo tools via `pkexec`)
- 📄 **Trace Labs Contestant Guide PDF** downloaded to the Desktop
- 🧪 **Built-in validator**: checks PATH, versions, repo keys, and tool health
- 🔁 Idempotent: safe to re-run; logs to `~/osint-bootstrap.log`

> ⚠️ Note: The script **adds the third-party repository** `apt.vulns.sexy` specifically for `sn0int`. You can remove it later (see Cleanup).

---

## ⚡ Quick start (Kali recommended)

```bash
cd ~/Desktop
wget https://raw.githubusercontent.com/404Yeti/ultimate-osint-tools/main/osint-tool.sh
chmod +x osint-tool.sh
sudo ./osint-tool.sh
