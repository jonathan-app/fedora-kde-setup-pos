# Fedora KDE Post-Install

Automation script to restore your entire development, productivity, and system tools environment after a clean installation of **Fedora KDE Plasma**.

![Fedora](https://img.shields.io/badge/Fedora-40%2B-blue?logo=fedora&logoColor=white)
![KDE Plasma](https://img.shields.io/badge/KDE-Plasma%206-1d99f3?logo=kde&logoColor=white)
![Shell](https://img.shields.io/badge/bash-5%2B-4EAA25?logo=gnubash&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green)

---

## Highlights

- **1-by-1 Interactive Installation**: each application displays its name and a detailed description, prompting you whether to install it (`[Y/n]`).
- **Idempotent**: can be run multiple times without conflicts or unwanted overwrites.
- **Error-resilient**: validates each package with `dnf repoquery` before installing, preventing a missing package from halting the process.
- **Full logging**: output is mirrored to the terminal and saved to `/var/log/post-install-fedora.log`.
- **Scope separation**: the script handles repositories, binaries, and services; dotfiles and personal keys remain under the user's control.

---

## Usage Instructions

### Option 1: Cloning the repository (Recommended)

```bash
git clone https://github.com/jonathan-app/fedora-kde-setup-pos.git
cd fedora-kde-setup-pos
chmod +x post-install-fedora-kde-en.sh post-install-fedora-kde-br.sh

# English version:
sudo ./post-install-fedora-kde-en.sh

# Versão em Português:
sudo ./post-install-fedora-kde-br.sh
```

### Option 2: Creating the file manually

1. Create the script file on your system:
```bash
nano post-install-fedora-kde-en.sh
```

2. Paste the script content, save (`Ctrl+O`, `Enter`), and exit (`Ctrl+X`).

3. Grant execution permissions:
```bash
chmod +x post-install-fedora-kde-en.sh
```

4. Run the script with administrative privileges:
```bash
sudo ./post-install-fedora-kde-en.sh
```

5. **Reboot the system** once finished to ensure background services like `snapd`, fonts, and shell resources load properly.

---

## Automation Steps

1. **System Update**: full synchronization and update of existing packages via `dnf upgrade --refresh`.
2. **RPM Fusion**: enables the `free` and `nonfree` repositories along with audio/video codecs (`gstreamer1-plugins-bad-freeworld`, `ugly`).
3. **Third-Party Repositories**:
   - Adoptium (Eclipse Temurin JDK)
   - Netdata (telemetry agent)
   - Google Chrome & Microsoft Edge
   - Sublime Text
   - AnyDesk
   - Cloudflare WARP
4. **RPM Package Installation**: batch containing compilers, dev tools, databases, network utilities, fonts, and GUI clients.
5. **Flatpak Setup**: adds the official Flathub remote and installs browsers and productivity applications.
6. **Service Activation**: enables `cockpit.socket`, `snapd.socket`, `dnf-automatic.timer`, `netdata`, and `clamav-freshclam`.
7. **Manual Packages Guide**: lists reminders for software distributed exclusively via standalone `.rpm` files.

---

## Installed Software

### RPM Packages (via DNF)

| Category | Packages |
|---|---|
| **Development** | `git`, `gcc`, `gcc-c++`, `make`, `cmake`, `rust`, `cargo`, `gh`, `nodejs22-npm-bin`, `uv`, `python3-devel`, `python3-pip`, `python3-virtualenv`, `python3-black`, `python3-flake8`, headers (`openssl`, `dbus`, `gtk-layer-shell`, `librsvg2`, `webkit2gtk4.1`, `libappindicator`), `patchelf` |
| **Databases & Services** | `postgresql`, `mariadb-server`, `sqlite`, `redis` (valkey), `netdata`, `clamav`, `snapd`, `cockpit` (bridge, networkmanager, storaged, system, ws), `dnf-automatic`, `openscap-scanner` |
| **Containers** | `podman-compose`, `podman-docker` |
| **Monitoring & CLI** | `htop`, `fastfetch`, `btop`, `glances`, `atop`, `nmon`, `iptstate` |
| **Network & Diagnostics** | `bind-utils`, `mtr`, `tcpdump`, `nmap-ncat`, `whois`, `traceroute`, `tree`, `dos2unix`, `minicom`, `lrzsz`, `net-tools` |
| **Files & System** | `unrar`, `7zip`, `compsize`, `gocryptfs`, `cifs-utils`, `nfs-utils` |
| **Shell & Fonts** | `zsh`, `powerline`, `powerline-fonts`, `neovim`, `wl-clipboard`, `aajohan-comfortaa-fonts` |
| **Desktop Applications** | `telegram-desktop`, `kdenlive`, `sublime-text`, `deskflow`, `alacarte`, `anydesk`, `google-chrome-stable`, `microsoft-edge-stable`, `cloudflare-warp` |
| **Multimedia & Java** | `vlc-plugin-gstreamer`, `gstreamer1-plugin-libav`, `faad2-libs`, `java-25-openjdk-headless`, `ffmpegthumbs` |

### Flatpak Applications (Flathub)

| Category | Identifier / App |
|---|---|
| **Browsing & Communication** | Brave, Vivaldi, Telegram, Dropbox |
| **Development & Database** | GitKraken, GitHub Desktop, DBeaver Community, Kate |
| **Design & Media** | Blender, Inkscape, OBS Studio, VLC, Video Downloader |
| **Productivity & Notes** | Obsidian, KeePassXC, qBittorrent, KStars, Yakuake, Flatseal |
| **Creative / AI** | Artcraft Launcher, Vectorcraft |

### Manual Packages (No stable repository)

Download the `.rpm` packages from their respective vendors and install them with `sudo dnf install ./filename.rpm`:

- `chatgpt` (official OpenAI desktop client)
- `opencode` (AI desktop with auto-updater)
- `pihole-meta` (custom local metapackage)
- `slitherer` (game)

---

## Post-Script Manual Steps

Some changes must be performed as a non-root user after rebooting:

```bash
# Set Zsh as the default shell for your user:
chsh -s /usr/bin/zsh

# (Optional) Start database services if you plan to use them locally:
sudo systemctl enable --now postgresql mariadb
```

---

## Repository Structure

```text
fedora-kde-setup-pos/
├── post-install-fedora-kde-en.sh   # English installation script
├── post-install-fedora-kde-br.sh   # Portuguese installation script
├── .gitignore                      # Git ignore file
├── LICENSE                         # MIT License
└── README.md                       # Project documentation
```

---

## License

Distributed under the [MIT](LICENSE) License. Feel free to clone, adapt to your workflow, and share.
