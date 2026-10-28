#!/usr/bin/env bash
# =============================================================================
#  post-install-fedora-kde-en.sh
#  Automated and interactive post-installation setup for Fedora KDE Plasma.
#
#  Usage:
#    chmod +x post-install-fedora-kde-en.sh
#    sudo ./post-install-fedora-kde-en.sh
# =============================================================================
set -uo pipefail

RELEASEVER=$(rpm -E %fedora)
LOG_FILE="/var/log/post-install-fedora.log"
exec > >(tee -a "$LOG_FILE") 2>&1

warn()  { echo -e "\033[1;33m[WARNING]\033[0m $*"; }
ok()    { echo -e "\033[1;32m[OK]\033[0m $*"; }
step()  { echo -e "\n\033[1;34m=== $* ===\033[0m"; }

if [[ $EUID -ne 0 ]]; then
  echo "Please run with sudo: sudo $0"; exit 1
fi

# Helper function for interactive prompts (reads directly from user tty)
ask() {
  local question="$1"
  local default="${2:-y}"
  local prompt_char="[Y/n]"
  [[ "$default" =~ ^[nN]$ ]] && prompt_char="[y/N]"

  local reply=""
  if [[ -r /dev/tty ]]; then
    printf "\033[1;35m  ? %s %s: \033[0m" "$question" "$prompt_char" > /dev/tty
    read -r reply < /dev/tty || reply="$default"
  else
    printf "\033[1;35m  ? %s %s: \033[0m" "$question" "$prompt_char"
    read -r reply || reply="$default"
  fi

  reply="${reply:-$default}"
  echo "[$reply] $question" >> "$LOG_FILE" 2>/dev/null || true
  [[ "$reply" =~ ^[yYsS]$ ]]
}

# Individual RPM installer with description
install_rpm() {
  local name="$1"
  local pkgs="$2"
  local desc="$3"

  echo ""
  echo -e "\033[1;36m▶ $name\033[0m"
  echo -e "  \033[0;37m$desc\033[0m"
  echo -e "  \033[0;33mPackage(s):\033[0m $pkgs"

  if ask "Do you want to install $name?"; then
    local to_install=()
    for p in $pkgs; do
      if dnf repoquery --quiet "$p" &>/dev/null; then
        to_install+=("$p")
      else
        warn "Package '$p' not found in repositories (skipping)."
      fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
      if dnf install -y "${to_install[@]}"; then
        ok "$name installed successfully."
      else
        warn "Failed to install package(s) for $name."
      fi
    else
      warn "No packages available for $name."
    fi
  else
    echo -e "\033[1;30m[SKIPPED]\033[0m $name will not be installed."
  fi
}

# Individual Flatpak installer with description
install_flatpak() {
  local name="$1"
  local app_id="$2"
  local desc="$3"

  echo ""
  echo -e "\033[1;36m▶ $name (Flatpak)\033[0m"
  echo -e "  \033[0;37m$desc\033[0m"
  echo -e "  \033[0;33mID:\033[0m $app_id"

  if ask "Do you want to install $name?"; then
    if flatpak install -y flathub "$app_id"; then
      ok "$name installed successfully."
    else
      warn "Failed to install Flatpak $name ($app_id)."
    fi
  else
    echo -e "\033[1;30m[SKIPPED]\033[0m $name will not be installed."
  fi
}

# Individual system service enabler
enable_service() {
  local service="$1"
  local name="$2"
  local desc="$3"

  echo ""
  echo -e "\033[1;36m▶ Service: $name ($service)\033[0m"
  echo -e "  \033[0;37m$desc\033[0m"

  if ask "Do you want to enable and start service $name?"; then
    systemctl enable --now "$service" && ok "Service $service enabled." || warn "Failed to enable $service."
  else
    echo -e "\033[1;30m[SKIPPED]\033[0m Service $service not enabled."
  fi
}

# -----------------------------------------------------------------------------
step "0. System Update"
# -----------------------------------------------------------------------------
echo -e "\033[1;36m▶ General Fedora Update\033[0m"
echo -e "  \033[0;37mRefreshes repository metadata and updates all installed packages to their latest versions.\033[0m"
if ask "Do you want to run 'dnf upgrade --refresh' now?"; then
  dnf upgrade -y --refresh && ok "System updated." || warn "dnf upgrade failed (check network connection)."
else
  echo -e "\033[1;30m[SKIPPED]\033[0m Initial update skipped."
fi

# -----------------------------------------------------------------------------
step "1. RPM Fusion & Multimedia Codecs"
# -----------------------------------------------------------------------------
echo -e "\033[1;36m▶ RPM Fusion (Free + Non-Free) and Codecs\033[0m"
echo -e "  \033[0;37mEssential repositories for proprietary software and multimedia codecs (H.264, AAC, MP3, etc.).\033[0m"
if ask "Do you want to enable RPM Fusion and install codecs?"; then
  dnf install -y \
    "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${RELEASEVER}.noarch.rpm" \
    "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${RELEASEVER}.noarch.rpm" \
    || warn "RPM Fusion already installed or failed"

  dnf install -y gstreamer1-plugins-bad-freeworld gstreamer1-plugins-ugly vlc-plugin-gstreamer gstreamer1-plugin-libav faad2-libs \
    && ok "RPM Fusion and multimedia codecs configured." || warn "Failed to configure some multimedia codecs."
else
  echo -e "\033[1;30m[SKIPPED]\033[0m RPM Fusion and codecs skipped."
fi

# -----------------------------------------------------------------------------
step "2. Third-Party Repositories & Applications"
# -----------------------------------------------------------------------------

# Google Chrome
echo ""
echo -e "\033[1;36m▶ Google Chrome\033[0m"
echo -e "  \033[0;37mGoogle web browser (Stable) with sync and DRM support.\033[0m"
if ask "Do you want to install Google Chrome?"; then
  dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm \
    && ok "Google Chrome installed successfully." || warn "Failed to install Google Chrome."
else
  echo -e "\033[1;30m[SKIPPED]\033[0m Google Chrome will not be installed."
fi

# Microsoft Edge
echo ""
echo -e "\033[1;36m▶ Microsoft Edge\033[0m"
echo -e "  \033[0;37mMicrosoft Chromium-based web browser.\033[0m"
if ask "Do you want to install Microsoft Edge?"; then
  rpm --import https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null || true
  dnf config-manager --add-repo https://packages.microsoft.com/yumrepos/edge \
    && dnf install -y microsoft-edge-stable \
    && ok "Microsoft Edge installed successfully." || warn "Failed to install Microsoft Edge."
else
  echo -e "\033[1;30m[SKIPPED]\033[0m Microsoft Edge will not be installed."
fi

# Sublime Text
echo ""
echo -e "\033[1;36m▶ Sublime Text\033[0m"
echo -e "  \033[0;37mFast, lightweight, and sophisticated source code editor.\033[0m"
if ask "Do you want to install Sublime Text?"; then
  rpm --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg 2>/dev/null || true
  dnf config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo \
    && dnf install -y sublime-text \
    && ok "Sublime Text installed successfully." || warn "Failed to install Sublime Text."
else
  echo -e "\033[1;30m[SKIPPED]\033[0m Sublime Text will not be installed."
fi

# AnyDesk
echo ""
echo -e "\033[1;36m▶ AnyDesk\033[0m"
echo -e "  \033[0;37mRemote desktop access and support application.\033[0m"
if ask "Do you want to install AnyDesk?"; then
  cat > /etc/yum.repos.d/anydesk.repo <<'EOF'
[anydesk]
name=AnyDesk Fedora - stable
baseurl=http://rpm.anydesk.com/fedora/$basearch/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://keys.anydesk.com/repos/RPM-GPG-KEY
EOF
  dnf install -y anydesk && ok "AnyDesk installed successfully." || warn "Failed to install AnyDesk."
else
  echo -e "\033[1;30m[SKIPPED]\033[0m AnyDesk will not be installed."
fi

# Cloudflare WARP
echo ""
echo -e "\033[1;36m▶ Cloudflare WARP\033[0m"
echo -e "  \033[0;37mOfficial Cloudflare client for 1.1.1.1 encrypted DNS and WARP tunnel.\033[0m"
if ask "Do you want to install Cloudflare WARP?"; then
  cat > /etc/yum.repos.d/cloudflare-warp.repo <<'EOF'
[cloudflare-warp]
name=Cloudflare WARP
baseurl=https://pkg.cloudflareclient.com/fedora/$releasever/$basearch
enabled=1
gpgcheck=1
gpgkey=https://pkg.cloudflareclient.com/pubkey.gpg
EOF
  dnf install -y cloudflare-warp && ok "Cloudflare WARP installed successfully." || warn "Failed to install Cloudflare WARP."
else
  echo -e "\033[1;30m[SKIPPED]\033[0m Cloudflare WARP will not be installed."
fi

# Adoptium / Temurin Java Repo
echo ""
echo -e "\033[1;36m▶ Adoptium Repository (Eclipse Temurin JDK)\033[0m"
echo -e "  \033[0;37mOfficial repository for enterprise Eclipse Temurin Java builds (JDK 8, 11, 17, 21).\033[0m"
if ask "Do you want to configure the Adoptium repository?"; then
  cat > /etc/yum.repos.d/adoptium.repo <<'EOF'
[Adoptium]
name=Adoptium
baseurl=https://packages.adoptium.net/artifactory/rpm/fedora/$releasever/$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.adoptium.net/artifactory/api/gpg/key/public
EOF
  ok "Adoptium repository configured."
else
  echo -e "\033[1;30m[SKIPPED]\033[0m Adoptium repository not configured."
fi

# Netdata Repo
echo ""
echo -e "\033[1;36m▶ Netdata Repository and Agent\033[0m"
echo -e "  \033[0;37mReal-time system health and performance monitoring with a web dashboard.\033[0m"
if ask "Do you want to configure the Netdata repository?"; then
  curl -fsSL https://packagecloud.io/install/repositories/netdata/netdata/script.rpm.sh | bash \
    || warn "Netdata repo script failed (can be installed via kickstart at get.netdata.cloud)"
else
  echo -e "\033[1;30m[SKIPPED]\033[0m Netdata repository not configured."
fi

# -----------------------------------------------------------------------------
step "3. RPM Packages (Individual Installation)"
# -----------------------------------------------------------------------------

# --- Development ---
install_rpm "Git" "git" "Distributed version control system."
install_rpm "Build Essentials (C/C++)" "gcc gcc-c++ make cmake pkgconf-pkg-config" "GCC, G++, Make, CMake compilers and essential build tools."
install_rpm "Rust & Cargo" "rust cargo" "Rust programming language and Cargo package manager."
install_rpm "GitHub CLI" "gh" "Official GitHub command-line utility."
install_rpm "Node.js & NPM" "nodejs22-npm-bin" "Node.js 22 LTS JavaScript runtime and npm package manager."
install_rpm "Astral UV" "uv" "Blazing fast Python package manager and resolver written in Rust."
install_rpm "Python Dev Tools" "python3-devel python3-pip python3-virtualenv python3-black python3-flake8" "Complete Python 3 environment with pip, virtualenv, black formatter, and flake8 linter."
install_rpm "Dev Libraries & Headers" "openssl-devel dbus-devel gtk-layer-shell-devel librsvg2-devel webkit2gtk4.1-devel libappindicator-gtk3-devel patchelf" "C/C++ development headers for building native modules and graphical Linux apps."

# --- Databases & Services ---
install_rpm "PostgreSQL" "postgresql" "Client libraries and utilities for the PostgreSQL database."
install_rpm "MariaDB Server" "mariadb-server" "Open-source MySQL-compatible relational SQL database server."
install_rpm "SQLite" "sqlite" "Lightweight, self-contained, embedded SQL database engine."
install_rpm "Redis / Valkey" "redis" "In-memory key-value data store for caching and message queues."
install_rpm "Netdata Package" "netdata" "Real-time system monitoring agent."
install_rpm "ClamAV Antivirus" "clamav clamav-update" "Open-source antivirus engine and Freshclam signature updater."
install_rpm "Snapd" "snapd" "Daemon to support and run Snap packages on Fedora."
install_rpm "Cockpit Web Console" "cockpit-bridge cockpit-networkmanager cockpit-storaged cockpit-system cockpit-ws cockpit-ws-selinux" "Web-based admin console for Linux server and machine management."
install_rpm "DNF Automatic" "dnf-automatic" "Service to automate package update checks and downloads."
install_rpm "OpenSCAP & Security Guide" "openscap-scanner scap-security-guide" "Security compliance auditing and vulnerability scanner for Fedora."

# --- Containers ---
install_rpm "Podman & Compose" "podman-compose podman-docker" "Daemonless, rootless container engine (native Docker alternative)."

# --- Monitoring & Terminal ---
install_rpm "Htop" "htop" "Interactive process viewer in the terminal with detailed resource metrics."
install_rpm "Fastfetch" "fastfetch" "Fast terminal system information tool showing hardware, kernel, and desktop details."
install_rpm "Btop" "btop" "Modern resource monitor showing real-time CPU, memory, disks, and network graphs."
install_rpm "Glances" "glances" "Advanced system monitor written in Python with terminal and web interface modes."
install_rpm "Atop" "atop" "Advanced performance monitor capable of logging and diagnosing system bottlenecks."
install_rpm "Nmon" "nmon" "Classic lightweight performance monitor for CPU, memory, disks, and network adapters."
install_rpm "IPTState" "iptstate" "Real-time state table viewer for the IP firewall."

# --- Networking & Diagnostics ---
install_rpm "DNS Utils (bind-utils)" "bind-utils" "Standard DNS query utilities (dig, nslookup, host)."
install_rpm "MTR" "mtr" "Network diagnostic tool combining traceroute and ping into a single interface."
install_rpm "TCPDump" "tcpdump" "Command-line packet analyzer and network traffic capture utility."
install_rpm "Ncat" "nmap-ncat" "Modern Netcat replacement for port checks and TCP/UDP data transfer."
install_rpm "Whois" "whois" "Client for querying domain name and IP address block registration data."
install_rpm "Traceroute" "traceroute" "Traces the packet route from source to destination server."
install_rpm "Tree" "tree" "Recursive directory listing program displaying files in a visual tree format."
install_rpm "Dos2unix" "dos2unix" "Line break converter between Windows (CRLF) and Unix (LF) formats."
install_rpm "Minicom" "minicom" "Serial communications terminal emulator for network hardware and microcontrollers."
install_rpm "Lrzsz" "lrzsz" "File transfer utilities supporting ZMODEM, YMODEM, and XMODEM protocols."
install_rpm "Net-tools" "net-tools" "Classic Linux networking utilities (netstat, ifconfig, arp, route)."

# --- Filesystem & Compression ---
install_rpm "Unrar" "unrar" "Utility for extracting RAR archive files."
install_rpm "7-Zip" "7zip" "High-compression archiver supporting 7z, zip, and tar formats."
install_rpm "Compsize" "compsize" "Utility to calculate compression ratios on Btrfs filesystems."
install_rpm "Gocryptfs" "gocryptfs" "FUSE-based encrypted filesystem for directory-level security."
install_rpm "CIFS Utils" "cifs-utils" "Utilities for mounting and managing SMB/Samba network shares."
install_rpm "NFS Utils" "nfs-utils" "Support for mounting and managing Network File System (NFS) shares."

# --- Shell, Editor & Fonts ---
install_rpm "Zsh" "zsh" "Advanced, highly customizable shell with modern autocomplete features."
install_rpm "Powerline & Fonts" "powerline powerline-fonts" "Terminal statusline and glyph font pack."
install_rpm "Neovim" "neovim" "Modern, fast, and extensible modal text editor based on Vim."
install_rpm "WL-Clipboard" "wl-clipboard" "Wayland clipboard command-line utilities (wl-copy and wl-paste)."
install_rpm "Comfortaa Fonts" "aajohan-comfortaa-fonts" "Comfortaa geometric rounded TrueType font family."

# --- Desktop Apps & KDE ---
install_rpm "Telegram Desktop" "telegram-desktop" "Official Telegram desktop messaging client."
install_rpm "Kdenlive" "kdenlive" "Professional open-source non-linear video editor by the KDE community."
install_rpm "Deskflow" "deskflow" "Seamless keyboard and mouse sharing across local computers."
install_rpm "Alacarte" "alacarte" "Simple graphical menu editor for application shortcuts."
install_rpm "Disks (GNOME Disk Utility)" "gnome-disk-utility" "Graphical disk manager for partitioning, formatting, and SMART health monitoring."
install_rpm "FFmpegThumbs" "ffmpegthumbs" "Fast video thumbnail generator for the Dolphin file manager."
install_rpm "Tesseract OCR" "tesseract-common tesseract-langpack-eng" "Optical character recognition engine for extracting text from images."
install_rpm "Java OpenJDK 25" "java-25-openjdk-headless" "Java 25 runtime environment (OpenJDK headless)."

# -----------------------------------------------------------------------------
step "4. Flatpaks (Flathub)"
# -----------------------------------------------------------------------------
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

install_flatpak "Artcraft Launcher" "ai.storyteller.artcraft-launcher" "Launcher and creative suite for digital game and art creation."
install_flatpak "Vectorcraft" "ai.storyteller.vectorcraft" "Vector graphic design and editing tool."
install_flatpak "GitKraken" "com.axosoft.GitKraken" "Visual Git client with repository graph visualization and merge tools."
install_flatpak "Brave Browser" "com.brave.Browser" "Privacy-focused web browser with built-in ad and tracker blocking."
install_flatpak "Dropbox" "com.dropbox.Client" "Official client for Dropbox cloud file storage and syncing."
install_flatpak "Flatseal" "com.github.tchx84.Flatseal" "Graphical permissions manager for Flatpak applications."
install_flatpak "Video Downloader" "com.github.unrud.VideoDownloader" "Simple utility to download videos and audio from various websites."
install_flatpak "OBS Studio" "com.obsproject.Studio" "Free and open-source software for video recording and live streaming."
install_flatpak "Vivaldi Browser" "com.vivaldi.Vivaldi" "Feature-rich browser with tab tiling, side panels, and built-in tools."
install_flatpak "DBeaver Community" "io.dbeaver.DBeaverCommunity" "Universal database management tool supporting PostgreSQL, MySQL, SQLite, etc."
install_flatpak "GitHub Desktop" "io.github.shiftey.Desktop" "Graphical Git client focusing on branch and commit management."
install_flatpak "Obsidian" "md.obsidian.Obsidian" "Markdown-based personal knowledge base and note-taking application."
install_flatpak "Blender" "org.blender.Blender" "Complete 3D creation suite for modeling, sculpting, animation, and rendering."
install_flatpak "FileZilla" "org.filezillaproject.Filezilla" "Cross-platform FTP, FTPS, and SFTP client."
install_flatpak "Inkscape" "org.inkscape.Inkscape" "Professional vector graphics editor using the standard SVG format."
install_flatpak "Kate" "org.kde.kate" "Advanced KDE text editor with tab support, LSP, and integrated terminal."
install_flatpak "KStars" "org.kde.kstars" "Desktop planetarium and astrophotography suite with EKOS telescope control."
install_flatpak "Yakuake" "org.kde.yakuake" "Quake-style drop-down terminal emulator for KDE Plasma."
install_flatpak "KeePassXC" "org.keepassxc.KeePassXC" "Secure, offline, encrypted password manager."
install_flatpak "qBittorrent" "org.qbittorrent.qBittorrent" "Lightweight, open-source BitTorrent client with no ads."
install_flatpak "VLC Media Player" "org.videolan.VLC" "Universal multimedia player supporting almost all audio and video formats."

# -----------------------------------------------------------------------------
step "5. Service Activation"
# -----------------------------------------------------------------------------
enable_service "cockpit.socket" "Cockpit Web Console" "Web administration interface on port 9090."
enable_service "snapd.socket" "Snapd Daemon" "Service required to run Snap packages (also creates /snap symlink)."
ln -sf /var/lib/snapd/snap /snap 2>/dev/null || true
enable_service "dnf-automatic.timer" "DNF Automatic Timer" "Systemd timer for automatic periodic update checks."
enable_service "netdata" "Netdata Agent" "Real-time metrics telemetry daemon with local web UI on port 19999."
enable_service "clamav-freshclam" "ClamAV Freshclam" "Automatic daily virus database signature updater."

# -----------------------------------------------------------------------------
step "6. Post-actions & Manual Configurations"
# -----------------------------------------------------------------------------
echo ""
echo -e "\033[1;33mTo change your default shell to Zsh as a regular user, run outside sudo:\033[0m"
echo "  chsh -s /usr/bin/zsh"
echo ""
echo -e "\033[1;33mTo start local database servers now:\033[0m"
echo "  sudo systemctl enable --now postgresql mariadb"

# -----------------------------------------------------------------------------
step "7. Manual Packages (Standalone Downloads)"
# -----------------------------------------------------------------------------
cat <<'MANUAL'
  These applications do not have an official stable repository. Download the .rpm and install with:
  sudo dnf install -y ./file.rpm

  • opencode (AI desktop app with built-in updater)
  • chatgpt (official OpenAI desktop client)
  • pihole-meta (local metadata package)
  • slitherer (game)
MANUAL

# -----------------------------------------------------------------------------
step "Finished"
# -----------------------------------------------------------------------------
echo "Full execution log saved at: $LOG_FILE"
echo "A system reboot is recommended to fully apply services, fonts, and multimedia codecs."
