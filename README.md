# 🕵️ Ultimate OSINT Tools Installer  

A one-stop bootstrap script for setting up an **OSINT-ready environment** on **Kali Linux** (primary) or **Ubuntu** (partial support).  
This script automates installation, configuration, and adds a clean **CLI menu** + **desktop shortcuts** for easy use.  

---

## 🚀 Features  

- 🔑 **APT self-heal + keyring refresh** (avoids broken package installs)  
- 📦 Installs **core OSINT tools** automatically:  
  - [Shodan CLI](https://help.shodan.io/command-line-interface/0-installation)  
  - [Sherlock](https://github.com/sherlock-project/sherlock)  
  - [PhoneInfoga](https://github.com/sundowndev/phoneinfoga)  
  - [SpiderFoot](https://github.com/smicallef/spiderfoot)  
  - [sn0int](https://github.com/kpcyrd/sn0int)  
  - [Metagoofil](https://github.com/opsdisk/metagoofil)  
  - [Sublist3r](https://github.com/aboul3la/Sublist3r)  
  - [StegOSuite](https://github.com/osde8info/stegosuite) (Java-based stego tool)  
  - [ExifTool](https://github.com/exiftool/exiftool)  
  - [Tor & Tor Browser Launcher](https://www.torproject.org/)  
- 🖥️ Creates **Desktop launchers**:  
  - `osint-menu` → intuitive CLI launcher for tools  
  - `OSINT Updater` → updates Kali & OSINT tools ("grandma mode")  
- 📄 Downloads the **Trace Labs Contestant Guide PDF** directly to the Desktop  

---

## ⚡ Quick Start  

### Kali Linux (recommended)  

```bash
cd ~/Desktop
wget https://raw.githubusercontent.com/404Yeti/ultimate-osint-tools/main/tlosint-tools.sh
chmod +x osint-tools.sh
sudo ./osint-tools.sh
