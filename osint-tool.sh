#!/bin/zsh
# Ultimate OSINT Setup for Kali + Pro CLI Menu
# - ALWAYS refresh Kali archive keyring before apt ops
# - APT self-heal + full-upgrade + base deps
# - Python/pipx, Go (GOPATH/GOBIN), Rust/cargo
# - Installs: Shodan, Sherlock, PhoneInfoga, SpiderFoot, sn0int, Metagoofil,
#             Sublist3r, StegOSuite (APT first; source fallback), ExifTool, Tor/Tor Browser, Gowitness
# - Installs Go tools directly into /usr/local/bin (no /root symlink issues)
# - Pro CLI menu: osint-menu (whiptail → fzf → PS3 fallback)
# - Idempotent & logged to ~/osint-bootstrap.log

set -uo pipefail
export DEBIAN_FRONTEND=noninteractive

LOG_FILE="${HOME}/osint-bootstrap.log"
touch "$LOG_FILE" || { echo "Cannot write ${LOG_FILE}"; exit 1; }

if [[ $EUID -eq 0 ]]; then SUDO=""; else SUDO="sudo"; fi

log()   { print -r -- "$(date +'%F %T') [INFO] $*" | tee -a "$LOG_FILE" >&2; }
logerr(){ print -r -- "$(date +'%F %T') [ERR ] $*"  | tee -a "$LOG_FILE" >&2; }
run()   { print -r -- "$(date +'%F %T') [EXEC] $*" | tee -a "$LOG_FILE" >&2; eval "$@" 2>>"$LOG_FILE"; }

# --- ALWAYS fetch the Kali archive keyring before apt update ---
ensure_kali_keyring() {
  local KR="/usr/share/keyrings/kali-archive-keyring.gpg"
  ${SUDO} mkdir -p /usr/share/keyrings 2>>"$LOG_FILE" || logerr "mkdir keyrings failed"
  log "[*] Forcing Kali archive keyring refresh…"
  if command -v wget >/dev/null 2>&1; then
    ${SUDO} wget -q "https://archive.kali.org/archive-keyring.gpg" -O "$KR" || logerr "Kali keyring download failed (wget)"
  elif command -v curl >/dev/null 2>&1; then
    ${SUDO} curl -fsSL "https://archive.kali.org/archive-keyring.gpg" -o "$KR" || logerr "Kali keyring download failed (curl)"
  else
    logerr "Neither wget nor curl available to fetch Kali keyring"
  fi
  ${SUDO} chmod 0644 "$KR" 2>>"$LOG_FILE" || true
  ${SUDO} chown root:root "$KR" 2>>"$LOG_FILE" || true
  ${SUDO} mkdir -p /etc/apt/trusted.gpg.d 2>>"$LOG_FILE" || true
  ${SUDO} cp -f "$KR" /etc/apt/trusted.gpg.d/kali-archive-keyring.gpg 2>>"$LOG_FILE" || true
}

apt_self_heal() {
  log "[*] APT self-heal & upgrade"
  ensure_kali_keyring
  run "${SUDO} apt-get update -y"
  run "${SUDO} apt-get -y --allow-downgrades --allow-remove-essential --allow-change-held-packages dist-upgrade"
  run "${SUDO} apt-get -f install -y || true"
  run "${SUDO} dpkg --configure -a || true"
  run "${SUDO} apt-get -y autoremove --purge || true"
  run "${SUDO} apt-get -y clean || true"
}

install_base_packages() {
  log "[*] Base packages & build deps"
  ensure_kali_keyring
  run "${SUDO} apt-get update -y"
  local pkgs=(
    ca-certificates apt-transport-https software-properties-common gnupg
    curl wget git jq unzip zip xz-utils coreutils moreutils ripgrep fzf
    build-essential pkg-config make gcc g++ libc6-dev
    # Python
    python3 python3-venv python3-pip python3-setuptools python3-dev pipx
    # Go
    golang-go
    # Rust deps
    libssl-dev
    # Java + Maven (fallback build path for StegOSuite)
    openjdk-11-jdk maven
    # OSINT/common tools
    exiftool tor torbrowser-launcher
    # TUI helpers
    whiptail zenity
    # Optional GUI helper
    chromium
  )
  run "${SUDO} apt-get install -y ${^pkgs}"
}

setup_python_envs() {
  log "[*] Python user tools (pip/pipx) & PATH"
  local SHIMS="${HOME}/.local/bin"
  if [[ ":$PATH:" != *":${SHIMS}:"* ]]; then
    print -r -- 'export PATH="$HOME/.local/bin:$PATH"' | tee -a "${HOME}/.zprofile" "${HOME}/.profile" >>"$LOG_FILE" 2>&1
    export PATH="$HOME/.local/bin:$PATH"
  fi
  if ! command -v pip3 >/dev/null 2>&1; then
    run "python3 -m ensurepip --upgrade"
  fi
  run "python3 -m pip install --user -U pip wheel setuptools"
  if command -v pipx >/dev/null 2>&1; then
    run "pipx ensurepath || true"
  fi
}

setup_go_env() {
  log "[*] Configure Go (GOPATH/GOBIN) & PATH"
  local GOPATH_DEFAULT="${HOME}/go"
  export GOPATH="${GOPATH:-$GOPATH_DEFAULT}"
  export GOBIN="${GOPATH}/bin"
  if [[ ":$PATH:" != *":${GOBIN}:"* ]]; then
    {
      print -r -- "export GOPATH=\"${GOPATH}\""
      print -r -- "export GOBIN=\"${GOBIN}\""
      print -r -- 'export PATH="$GOBIN:$PATH"'
    } | tee -a "${HOME}/.zprofile" "${HOME}/.profile" >>"$LOG_FILE" 2>&1
    export PATH="$GOBIN:$PATH"
  fi
  mkdir -p "$GOBIN" "$GOPATH/src" "$GOPATH/pkg" >>"$LOG_FILE" 2>&1 || true
}

setup_rust_env() {
  log "[*] Install Rust (rustup) for sn0int"
  if ! command -v cargo >/dev/null 2>&1; then
    run "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal"
    if [[ -f ${HOME}/.cargo/env ]]; then
      source "${HOME}/.cargo/env"
      if [[ ":$PATH:" != *":${HOME}/.cargo/bin:"* ]]; then
        print -r -- 'source "$HOME/.cargo/env"' | tee -a "${HOME}/.zprofile" "${HOME}/.profile" >>"$LOG_FILE" 2>&1
      fi
    fi
  fi
}

# --- helpers ---
apt_try_install() {
  local pkg="$1"
  if dpkg -s "$pkg" >/dev/null 2>&1; then return 0; fi
  ensure_kali_keyring
  run "${SUDO} apt-get update -y"
  run "${SUDO} apt-get install -y $pkg" || return 1
}
pipx_install_or_upgrade() {
  local spec="$1" ; local bin_hint="${2:-}"
  if [[ -n "$bin_hint" ]] && command -v "$bin_hint" >/dev/null 2>&1; then
    if [[ "$spec" != git+* && "$spec" != */* ]]; then run "pipx upgrade \"$spec\" || true"; fi
    return 0
  fi
  run "pipx install \"$spec\""
}
go_install_if_missing() {
  local module="$1" ; local bin="${2:-}" ; local name="$bin"
  if [[ -z "$name" ]]; then name="${module##*/}"; name="${name%@*}"; fi
  if ! command -v "$name" >/dev/null 2>&1; then run "go install \"$module\""; fi
}
cargo_install_if_missing() { local crate="$1"; if ! command -v "$crate" >/dev/null 2>&1; then run "cargo install --locked \"$crate\""; fi; }

# Install a Go tool directly to /usr/local/bin (avoids /root path)
go_install_global() {
  local module="$1"   # e.g. github.com/sensepost/gowitness@latest
  local bin="$2"      # e.g. gowitness
  local dest="/usr/local/bin/${bin}"
  run "env GOBIN=/usr/local/bin go install \"$module\""
  if [[ -f "$dest" ]]; then
    ${SUDO} chmod 0755 "$dest" || true
    ${SUDO} chown root:root "$dest" || true
    log "[*] Installed $bin to $dest (chmod 0755). If not visible: run 'rehash' in zsh."
  else
    logerr "[go_install_global] Failed to install $bin to $dest"
  fi
}

# --- Fallback: build StegOSuite from source (only if APT not available) ---
build_stegosuite_from_source() {
  local repo="https://github.com/osde8info/stegosuite.git"
  local app="stegosuite"
  local optdir="/opt/${app}"
  local desktop="${HOME}/.local/share/applications/${app}.desktop"
  local tmpdir; tmpdir="$(mktemp -d)"
  log "[*] Building StegOSuite from source (Maven + JDK 11)…"
  run "${SUDO} mkdir -p \"$optdir\""
  (
    cd "$tmpdir"
    run "git clone --depth=1 \"$repo\" src"
    cd src
    if ! mvn -q -DskipTests package; then
      logerr "[stegosuite] Maven build failed — SWT repository issues are common upstream."
    fi
    local jar; jar="$(ls -1 target/*stegosuite*.jar 2>/dev/null | head -n1 || true)"
    if [[ -n "$jar" ]]; then
      run "${SUDO} install -m 0644 \"$jar\" \"$optdir/${app}.jar\""
      log "[*] Installed: $optdir/${app}.jar"
    else
      logerr "[stegosuite] Build finished but no JAR found in target/. Check ${LOG_FILE}."
    fi
  )
  rm -rf "$tmpdir" || true

  mkdir -p "$(dirname "$desktop")"
  cat > "$desktop" <<EOF
[Desktop Entry]
Type=Application
Name=${app:u}
Comment=Launch ${app}
Exec=sh -c 'java -jar "${optdir}/${app}.jar" || zenity --error --text="Missing ${app}.jar in ${optdir}"'
Icon=utilities-terminal
Terminal=false
Categories=Utility;Security;
StartupNotify=true
EOF
  chmod +x "$desktop"
  log "[*] Desktop entry created: $desktop"
}

# --- Tool installs ---
install_tools_from_list() {
  log "[*] Installing requested OSINT tools"

  # Shodan CLI
  pipx_install_or_upgrade "shodan" "shodan"

  # Sherlock (git for freshness)
  pipx_install_or_upgrade "git+https://github.com/sherlock-project/sherlock.git" "sherlock"

  # PhoneInfoga (Go) — install globally
  go_install_global "github.com/sundowndev/phoneinfoga/v2/cmd/phoneinfoga@latest" "phoneinfoga"

  # SpiderFoot (prefer APT; fallback pipx/git)
  if ! apt_try_install spiderfoot; then
    pipx_install_or_upgrade "git+https://github.com/smicallef/spiderfoot.git" "sf.py"
  fi

  # sn0int (Rust)
  cargo_install_if_missing "sn0int"

  # Metagoofil (prefer APT; fallback pipx/git)
  if ! apt_try_install metagoofil; then
    pipx_install_or_upgrade "git+https://github.com/opsdisk/metagoofil.git" "metagoofil"
  fi

  # Sublist3r (prefer APT; fallback pipx/git)
  if ! apt_try_install sublist3r; then
    pipx_install_or_upgrade "git+https://github.com/aboul3la/Sublist3r.git" "sublist3r"
  fi

  # --- StegOSuite (APT first, then fallback build) ---
  if ! apt_try_install stegosuite; then
    log "[*] stegosuite APT not available; attempting source build."
    build_stegosuite_from_source
  fi

  # ExifTool (APT name may vary)
  apt_try_install exiftool || apt_try_install libimage-exiftool-perl || true

  # Tor / Tor Browser (APT already in base)
  true

}

# --- CLI Menu installer ---
install_cli_menu() {
  log "[*] Installing CLI menu: osint-menu"
  local BIN="/usr/local/bin/osint-menu"
  ${SUDO} tee "$BIN" >/dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
has(){ command -v "$1" >/dev/null 2>&1; }
ts(){ date +'%Y%m%d-%H%M%S'; }
log(){ printf '[%s] %s\n' "$(date +'%F %T')" "$*"; }

mk_ws(){ local t="${1:-misc}"; local r="${HOME}/osint-workspaces/${t}"; local w="${r}/$(ts)"; mkdir -p "$w"; echo "$w"; }

ensure_tools(){
  local miss=()
  for b in shodan sherlock phoneinfoga sn0int metagoofil sublist3r exiftool gowitness; do has "$b" || miss+=("$b"); done
  has spiderfoot || has sf.py || miss+=("spiderfoot/sf.py")
  if ((${#miss[@]})); then echo "Missing: ${miss[*]}"; echo "Re-run setup or install missing tools."; exit 1; fi
}

action_shodan(){
  local c; c="$(menu_pick "Shodan Actions" "Init (set API key)" "My Info" "Host Lookup (IP)" "Search Query (save JSON)" "Count Query" "Back")"
  case "${c:-Back}" in
    "Init (set API key)") read -rp "API key: " k; shodan init "$k" ;;
    "My Info") shodan info | less -R ;;
    "Host Lookup (IP)") read -rp "IP: " ip; ws="$(mk_ws "shodan_${ip}")"; shodan host "$ip" | tee "${ws}/host_${ip}.txt";;
    "Search Query (save JSON)") read -rp "Query: " q; ws="$(mk_ws "shodan_search")"; shodan search --fields ip_str,port,org,hostnames --limit 200 "$q" | tee "${ws}/search.txt"; shodan download "${ws}/results" "$q"; shodan parse --fields ip_str,port,org,hostnames "${ws}/results.json.gz" > "${ws}/results.csv"; log "Saved in $ws";;
    "Count Query") read -rp "Query: " q; shodan count "$q";;
    *) ;;
  esac
}

action_sherlock(){ read -rp "Username: " u; ws="$(mk_ws "sherlock_${u}")"; sherlock "$u" --folderoutput "$ws" --site all || true; log "Results: $ws"; }
action_phoneinfoga(){ read -rp "Phone (E.164, e.g. +12025550123): " n; ws="$(mk_ws "phone_${n//+/plus}")"; phoneinfoga scan -n "$n" | tee "${ws}/phoneinfoga_${n}.txt"; }
action_spiderfoot(){ local bin="spiderfoot"; has spiderfoot || bin="sf.py"; local host="127.0.0.1" port="5001"; ws="$(mk_ws spiderfoot)"; echo "Open: http://${host}:${port}"; "${bin}" -l "${host}:${port}" 2>&1 | tee "${ws}/spiderfoot_${port}.log"; }
action_sn0int(){ ws="$(mk_ws sn0int)"; sn0int init || true; echo -e "Examples:\n  sn0int run recon/domains example.com"; (cd "$ws" && bash); }
action_metagoofil(){ read -rp "Domain: " d; read -rp "Doc types (default: pdf,doc,docx,xls,xlsx,ppt,pptx): " t; t="${t:-pdf,doc,docx,xls,xlsx,ppt,pptx}"; ws="$(mk_ws "metagoofil_${d}")"; metagoofil -d "$d" -t "$t" -l 200 -n 100 -o "$ws" -f "${ws}/report.html" | tee "${ws}/metagoofil.log"; log "Saved: ${ws}/report.html"; }
action_sublist3r(){ read -rp "Domain: " d; ws="$(mk_ws "subdomains_${d}")"; sublist3r -d "$d" -o "${ws}/subdomains.txt" | tee "${ws}/sublist3r.log"; log "Saved: ${ws}/subdomains.txt"; }
action_stegosuite(){
  if has stegosuite; then setsid sh -c 'stegosuite >/dev/null 2>&1 &' </dev/null
  elif [[ -f /opt/stegosuite/stegosuite.jar ]]; then setsid sh -c 'java -jar /opt/stegosuite/stegosuite.jar >/dev/null 2>&1 &' </devnull
  else echo "StegOSuite not found. Install with APT or ensure /opt/stegosuite/stegosuite.jar exists."; fi
}
action_exiftool(){ read -rp "Path (file or dir): " p; ws="$(mk_ws exif)"; if [[ -d "$p" ]]; then exiftool -r "$p" | tee "${ws}/exif_recursive.txt"; else exiftool "$p" | tee "${ws}/exif_$(ts).txt"; fi; }
action_torbrowser(){ if has torbrowser-launcher; then torbrowser-launcher; else echo "torbrowser-launcher not installed."; fi; }
pipeline_subs_to_gowitness(){
  read -rp "Domain: " d; ws="$(mk_ws "screens_${d}")"
  echo "[*] Subdomain enum…"; sublist3r -d "$d" -o "${ws}/subdomains.txt" >/dev/null
  echo "[*] Building URLs…"; awk '{print "http://" $0 "\nhttps://" $0}' "${ws}/subdomains.txt" | sort -u > "${ws}/urls.txt"
  echo "[*] Gowitness screenshots…"; gowitness file -f "${ws}/urls.txt" --db "${ws}/gowitness.sqlite" --log-level info | tee "${ws}/gowitness.log"
  log "Outputs in $ws (captures/, urls.txt, gowitness.sqlite)"; echo "Tip: cd \"$ws\" && gowitness report serve"
}

menu_pick(){
  local title="$1"; shift; local options=("$@")
  if has whiptail; then
    local args=() i=1; for o in "${options[@]}"; do args+=("$i" "$o"); ((i++)); done
    local sel; sel=$(whiptail --title "$title" --menu "Choose an action:" 20 78 12 "${args[@]}" 3>&1 1>&2 2>&3) || { echo "Exit"; return; }
    echo "${options[$((sel-1))]}"; return
  fi
  if has fzf; then printf '%s\n' "${options[@]}" | fzf --prompt="$title > " --height=20 --reverse; return; fi
  PS3="[$title] Enter choice #: "; select o in "${options[@]}"; do [[ -n "${o:-}" ]] && { echo "$o"; break; }; done
}

main_menu(){
  ensure_tools
  while :; do
    c="$(menu_pick "OSINT Toolbox" \
      "Shodan CLI" \
      "Sherlock (username)" \
      "PhoneInfoga (phone)" \
      "SpiderFoot (web UI)" \
      "sn0int (shell)" \
      "Metagoofil (docs)" \
      "Sublist3r (subdomains)" \
      "StegOSuite (GUI)" \
      "ExifTool (metadata)" \
      "Tor Browser" \
      "Pipeline: Subdomain enum → Gowitness screenshots" \
      "Exit")"
    case "${c:-Exit}" in
      "Shodan CLI") action_shodan ;;
      "Sherlock (username)") action_sherlock ;;
      "PhoneInfoga (phone)") action_phoneinfoga ;;
      "SpiderFoot (web UI)") action_spiderfoot ;;
      "sn0int (shell)") action_sn0int ;;
      "Metagoofil (docs)") action_metagoofil ;;
      "Sublist3r (subdomains)") action_sublist3r ;;
      "StegOSuite (GUI)") action_stegosuite ;;
      "ExifTool (metadata)") action_exiftool ;;
      "Tor Browser") action_torbrowser ;;
      "Pipeline: Subdomain enum → Gowitness screenshots") pipeline_subs_to_gowitness ;;
      *) echo "Bye!"; exit 0 ;;
    esac
  done
}
main_menu
EOF
  ${SUDO} chmod +x "$BIN"
  log "[*] Installed osint-menu (run: osint-menu)"
}

# Optional desktop launcher for the menu (clickable)
install_menu_launcher() {
  local D="$HOME/.local/share/applications/osint-menu.desktop"
  mkdir -p "$(dirname "$D")"
  cat > "$D" <<'EOF'
[Desktop Entry]
Type=Application
Name=OSINT Toolbox (CLI)
Comment=Run the OSINT CLI toolbox
Exec=sh -c 'x-terminal-emulator -e osint-menu'
Icon=utilities-terminal
Terminal=false
Categories=Security;Utility;Network;
StartupNotify=true
EOF
  chmod +x "$D"
  log "[*] Desktop launcher created: $D"
}

post_install_checks() {
  log "[*] Post-install sanity checks"
  local missing=()
  for b in shodan sherlock phoneinfoga sn0int metagoofil sublist3r exiftool gowitness tor; do
    command -v "$b" >/dev/null 2>&1 || missing+=("$b")
  done
  command -v spiderfoot >/dev/null 2>&1 || command -v sf.py >/dev/null 2>&1 || missing+=("spiderfoot/sf.py")
  command -v stegosuite >/dev/null 2>&1 || [[ -f /opt/stegosuite/stegosuite.jar ]] || missing+=("stegosuite (APT) or /opt/stegosuite/stegosuite.jar")
  command -v torbrowser-launcher >/dev/null 2>&1 || missing+=("torbrowser-launcher")
  if (( ${#missing[@]} )); then
    logerr "Missing or not detected: ${missing[*]}"
    log "Review ${LOG_FILE} for errors; upstream names can change."
  else
    log "[*] All requested tools detected."
  fi
}

usage_hints() {
  cat <<'EOF' | tee -a "$LOG_FILE" >/dev/null
----------------------------------------------------------------
Usage:
- Launch toolbox:  osint-menu
- Shodan:          shodan init <API_KEY>  (first time)
- StegOSuite:      stegosuite   (APT)   or   java -jar /opt/stegosuite/stegosuite.jar
- Pipeline demo:   Sublist3r → URLs → Gowitness screenshots (gallery: gowitness report serve)
- PATH refresh:    source ~/.profile   (or open a new terminal)
Workspaces:
- Outputs saved in  ~/osint-workspaces/<target>/<timestamp>/
Logs:
- Setup log:       ~/osint-bootstrap.log
----------------------------------------------------------------
EOF
}

main() {
  log "==== Ultimate OSINT Setup starting ===="
  apt_self_heal
  install_base_packages
  setup_python_envs
  setup_go_env
  setup_rust_env
  install_tools_from_list
  install_cli_menu
  install_menu_launcher
  post_install_checks
  usage_hints
  log "==== Completed. See ${LOG_FILE} for details. ===="
}
main "$@"
