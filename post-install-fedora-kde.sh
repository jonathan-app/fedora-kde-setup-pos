#!/usr/bin/env bash
# =============================================================================
#  post-install-fedora-kde.sh
#  Restaura o ambiente após formatar o Fedora KDE de forma interativa.
#
#  Uso:
#    chmod +x post-install-fedora-kde.sh
#    sudo ./post-install-fedora-kde.sh
# =============================================================================
set -uo pipefail

RELEASEVER=$(rpm -E %fedora)
LOG_FILE="/var/log/post-install-fedora.log"
exec > >(tee -a "$LOG_FILE") 2>&1

warn()  { echo -e "\033[1;33m[AVISO]\033[0m $*"; }
ok()    { echo -e "\033[1;32m[OK]\033[0m $*"; }
step()  { echo -e "\n\033[1;34m=== $* ===\033[0m"; }

if [[ $EUID -ne 0 ]]; then
  echo "Rode com sudo: sudo $0"; exit 1
fi

# Função auxiliar para perguntas interativas (lê direto do terminal do usuário)
ask() {
  local question="$1"
  local default="${2:-s}"
  local prompt_char="[S/n]"
  [[ "$default" =~ ^[nN]$ ]] && prompt_char="[s/N]"

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
  [[ "$reply" =~ ^[sSyY]$ ]]
}

# Instalador individual para RPMs com descrição
install_rpm() {
  local name="$1"
  local pkgs="$2"
  local desc="$3"

  echo ""
  echo -e "\033[1;36m▶ $name\033[0m"
  echo -e "  \033[0;37m$desc\033[0m"
  echo -e "  \033[0;33mPacote(s):\033[0m $pkgs"

  if ask "Deseja instalar $name?"; then
    local to_install=()
    for p in $pkgs; do
      if dnf repoquery --quiet "$p" &>/dev/null; then
        to_install+=("$p")
      else
        warn "Pacote '$p' não encontrado nos repositórios (pulando)."
      fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
      if dnf install -y "${to_install[@]}"; then
        ok "$name instalado com sucesso."
      else
        warn "Falha ao instalar pacote(s) de $name."
      fi
    else
      warn "Nenhum pacote disponível para $name."
    fi
  else
    echo -e "\033[1;30m[PULADO]\033[0m $name não será instalado."
  fi
}

# Instalador individual para Flatpaks com descrição
install_flatpak() {
  local name="$1"
  local app_id="$2"
  local desc="$3"

  echo ""
  echo -e "\033[1;36m▶ $name (Flatpak)\033[0m"
  echo -e "  \033[0;37m$desc\033[0m"
  echo -e "  \033[0;33mID:\033[0m $app_id"

  if ask "Deseja instalar $name?"; then
    if flatpak install -y flathub "$app_id"; then
      ok "$name instalado com sucesso."
    else
      warn "Falha ao instalar o Flatpak $name ($app_id)."
    fi
  else
    echo -e "\033[1;30m[PULADO]\033[0m $name não será instalado."
  fi
}

# Ativador individual para serviços de sistema
enable_service() {
  local service="$1"
  local name="$2"
  local desc="$3"

  echo ""
  echo -e "\033[1;36m▶ Serviço: $name ($service)\033[0m"
  echo -e "  \033[0;37m$desc\033[0m"

  if ask "Deseja ativar e inicializar o serviço $name?"; then
    systemctl enable --now "$service" && ok "Serviço $service ativado." || warn "Falha ao ativar $service."
  else
    echo -e "\033[1;30m[PULADO]\033[0m Serviço $service não ativado."
  fi
}

# -----------------------------------------------------------------------------
step "0. Atualização do Sistema"
# -----------------------------------------------------------------------------
echo -e "\033[1;36m▶ Atualização Geral do Fedora\033[0m"
echo -e "  \033[0;37mAtualiza o cache e todos os pacotes instalados para a versão mais recente.\033[0m"
if ask "Deseja rodar 'dnf upgrade --refresh' agora?"; then
  dnf upgrade -y --refresh && ok "Sistema atualizado." || warn "dnf upgrade falhou (verifique a conexão de rede)."
else
  echo -e "\033[1;30m[PULADO]\033[0m Atualização inicial pulada."
fi

# -----------------------------------------------------------------------------
step "1. RPM Fusion e Codecs de Multimídia"
# -----------------------------------------------------------------------------
echo -e "\033[1;36m▶ RPM Fusion (Free + Non-Free) e Codecs\033[0m"
echo -e "  \033[0;37mRepositórios essenciais para softwares proprietários e codecs multimídia (H.264, AAC, MP3, etc.).\033[0m"
if ask "Deseja habilitar o RPM Fusion e instalar codecs?"; then
  dnf install -y \
    "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${RELEASEVER}.noarch.rpm" \
    "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${RELEASEVER}.noarch.rpm" \
    || warn "RPM Fusion já instalado ou falhou"

  dnf install -y gstreamer1-plugins-bad-freeworld gstreamer1-plugins-ugly vlc-plugin-gstreamer gstreamer1-plugin-libav faad2-libs \
    && ok "RPM Fusion e codecs multimídia configurados." || warn "Falha em alguns codecs de multimídia."
else
  echo -e "\033[1;30m[PULADO]\033[0m RPM Fusion e codecs pulados."
fi

# -----------------------------------------------------------------------------
step "2. Repositórios e Aplicações de Terceiros"
# -----------------------------------------------------------------------------

# Google Chrome
echo ""
echo -e "\033[1;36m▶ Google Chrome\033[0m"
echo -e "  \033[0;37mNavegador web do Google (Stable) com sincronização e suporte DRM.\033[0m"
if ask "Deseja instalar o Google Chrome?"; then
  dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm \
    && ok "Google Chrome instalado com sucesso." || warn "Falha ao instalar Google Chrome."
else
  echo -e "\033[1;30m[PULADO]\033[0m Google Chrome não será instalado."
fi

# Microsoft Edge
echo ""
echo -e "\033[1;36m▶ Microsoft Edge\033[0m"
echo -e "  \033[0;37mNavegador web da Microsoft baseado em Chromium.\033[0m"
if ask "Deseja instalar o Microsoft Edge?"; then
  rpm --import https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null || true
  dnf config-manager --add-repo https://packages.microsoft.com/yumrepos/edge \
    && dnf install -y microsoft-edge-stable \
    && ok "Microsoft Edge instalado com sucesso." || warn "Falha ao instalar Microsoft Edge."
else
  echo -e "\033[1;30m[PULADO]\033[0m Microsoft Edge não será instalado."
fi

# Sublime Text
echo ""
echo -e "\033[1;36m▶ Sublime Text\033[0m"
echo -e "  \033[0;37mEditor de código-fonte rápido, leve e sofisticado.\033[0m"
if ask "Deseja instalar o Sublime Text?"; then
  rpm --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg 2>/dev/null || true
  dnf config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo \
    && dnf install -y sublime-text \
    && ok "Sublime Text instalado com sucesso." || warn "Falha ao instalar Sublime Text."
else
  echo -e "\033[1;30m[PULADO]\033[0m Sublime Text não será instalado."
fi

# AnyDesk
echo ""
echo -e "\033[1;36m▶ AnyDesk\033[0m"
echo -e "  \033[0;37mAplicativo de suporte e acesso remoto para desktop.\033[0m"
if ask "Deseja instalar o AnyDesk?"; then
  cat > /etc/yum.repos.d/anydesk.repo <<'EOF'
[anydesk]
name=AnyDesk Fedora - stable
baseurl=http://rpm.anydesk.com/fedora/$basearch/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://keys.anydesk.com/repos/RPM-GPG-KEY
EOF
  dnf install -y anydesk && ok "AnyDesk instalado com sucesso." || warn "Falha ao instalar AnyDesk."
else
  echo -e "\033[1;30m[PULADO]\033[0m AnyDesk não será instalado."
fi

# Cloudflare WARP
echo ""
echo -e "\033[1;36m▶ Cloudflare WARP\033[0m"
echo -e "  \033[0;37mCliente oficial da Cloudflare para DNS criptografado 1.1.1.1 e túnel WARP.\033[0m"
if ask "Deseja instalar o Cloudflare WARP?"; then
  cat > /etc/yum.repos.d/cloudflare-warp.repo <<'EOF'
[cloudflare-warp]
name=Cloudflare WARP
baseurl=https://pkg.cloudflareclient.com/fedora/$releasever/$basearch
enabled=1
gpgcheck=1
gpgkey=https://pkg.cloudflareclient.com/pubkey.gpg
EOF
  dnf install -y cloudflare-warp && ok "Cloudflare WARP instalado com sucesso." || warn "Falha ao instalar Cloudflare WARP."
else
  echo -e "\033[1;30m[PULADO]\033[0m Cloudflare WARP não será instalado."
fi

# Adoptium / Temurin Java Repo
echo ""
echo -e "\033[1;36m▶ Repositório Adoptium (Eclipse Temurin JDK)\033[0m"
echo -e "  \033[0;37mRepositório oficial para versões corporativas do Eclipse Temurin Java (JDK 8, 11, 17, 21).\033[0m"
if ask "Deseja configurar o repositório Adoptium?"; then
  cat > /etc/yum.repos.d/adoptium.repo <<'EOF'
[Adoptium]
name=Adoptium
baseurl=https://packages.adoptium.net/artifactory/rpm/fedora/$releasever/$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.adoptium.net/artifactory/api/gpg/key/public
EOF
  ok "Repositório Adoptium configurado."
else
  echo -e "\033[1;30m[PULADO]\033[0m Repositório Adoptium não configurado."
fi

# Netdata Repo
echo ""
echo -e "\033[1;36m▶ Repositório e Agente Netdata\033[0m"
echo -e "  \033[0;37mMonitoramento e diagnóstico de métricas de sistema em tempo real com dashboard web.\033[0m"
if ask "Deseja configurar o repositório do Netdata?"; then
  curl -fsSL https://packagecloud.io/install/repositories/netdata/netdata/script.rpm.sh | bash \
    || warn "Netdata repo falhou (pode ser instalado via kickstart get.netdata.cloud)"
else
  echo -e "\033[1;30m[PULADO]\033[0m Repositório Netdata não configurado."
fi

# -----------------------------------------------------------------------------
step "3. Pacotes RPM (Instalação Individual)"
# -----------------------------------------------------------------------------

# --- Desenvolvimento ---
install_rpm "Git" "git" "Sistema distribuído de controle de versões de código."
install_rpm "Build Essentials (C/C++)" "gcc gcc-c++ make cmake pkgconf-pkg-config" "Compiladores GCC, G++, Make, CMake e ferramentas essenciais de build."
install_rpm "Rust & Cargo" "rust cargo" "Linguagem de programação Rust e gerenciador de pacotes Cargo."
install_rpm "GitHub CLI" "gh" "Utilitário oficial de linha de comando para o GitHub."
install_rpm "Node.js & NPM" "nodejs22-npm-bin" "Runtime JavaScript Node.js 22 LTS e gerenciador de pacotes npm."
install_rpm "Astral UV" "uv" "Gerenciador ultrarrápido de pacotes e ambientes virtuais Python escrito em Rust."
install_rpm "Python Dev Tools" "python3-devel python3-pip python3-virtualenv python3-black python3-flake8" "Ambiente completo Python 3 com pip, virtualenv, formatador black e linter flake8."
install_rpm "Bibliotecas Dev & Headers" "openssl-devel dbus-devel gtk-layer-shell-devel librsvg2-devel webkit2gtk4.1-devel libappindicator-gtk3-devel patchelf" "Cabeçalhos C/C++ necessários para compilar módulos nativos e interfaces gráficas Linux."

# --- Bancos de Dados & Serviços ---
install_rpm "PostgreSQL" "postgresql" "Cliente e bibliotecas para o banco de dados relacional PostgreSQL."
install_rpm "MariaDB Server" "mariadb-server" "Servidor de banco de dados relacional SQL livre compatível com MySQL."
install_rpm "SQLite" "sqlite" "Motor de banco de dados SQL leve, autocontido e embutido em arquivo."
install_rpm "Redis / Valkey" "redis" "Banco de dados em memória chave-valor para cache rápido e filas."
install_rpm "Netdata Package" "netdata" "Agente de monitoramento de sistema em tempo real."
install_rpm "ClamAV Antivirus" "clamav clamav-update" "Antivírus open-source e ferramenta de atualização de assinaturas Freshclam."
install_rpm "Snapd" "snapd" "Daemon para suporte e execução de pacotes Snap no Fedora."
install_rpm "Cockpit Web Console" "cockpit-bridge cockpit-networkmanager cockpit-storaged cockpit-system cockpit-ws cockpit-ws-selinux" "Painel web administrativo para gerenciamento de servidores e máquinas Linux."
install_rpm "DNF Automatic" "dnf-automatic" "Serviço para automatizar notificações e downloads de atualizações do Fedora."
install_rpm "OpenSCAP & Security Guide" "openscap-scanner scap-security-guide" "Ferramentas de auditoria de segurança e conformidade para o Fedora."

# --- Contêineres ---
install_rpm "Podman & Compose" "podman-compose podman-docker" "Gerenciador de contêineres sem necessidade de daemon root (alternativa nativa ao Docker)."

# --- Monitoramento & Terminal ---
install_rpm "Htop" "htop" "Monitor interativo de processos no terminal com visualização detalhada."
install_rpm "Fastfetch" "fastfetch" "Exibição rápida de resumo de hardware, kernel e ambiente gráfico no terminal."
install_rpm "Btop" "btop" "Monitor moderno de recursos com gráficos em tempo real de CPU, memória, discos e rede."
install_rpm "Glances" "glances" "Monitor avançado de sistema escrito em Python com modo terminal e servidor web."
install_rpm "Atop" "atop" "Monitor de desempenho detalhado capaz de registrar e inspecionar gargalos de recursos."
install_rpm "Nmon" "nmon" "Monitor clássico e leve de performance para CPU, memória, adaptadores e discos."
install_rpm "IPTState" "iptstate" "Visualizador em tempo real da tabela de conexões de estado do firewall IP."

# --- Rede & Diagnóstico ---
install_rpm "DNS Utils (bind-utils)" "bind-utils" "Utilitários clássicos de consulta DNS (dig, nslookup, host)."
install_rpm "MTR" "mtr" "Diagnóstico de conectividade combinando traceroute e ping em uma única interface."
install_rpm "TCPDump" "tcpdump" "Capturador e analisador de pacotes de rede via linha de comando."
install_rpm "Ncat" "nmap-ncat" "Versão moderna do utilitário Netcat para teste de portas e transferências TCP/UDP."
install_rpm "Whois" "whois" "Cliente para consulta de registros de domínios e blocos de endereçamento IP."
install_rpm "Traceroute" "traceroute" "Rastreamento da rota percorrida por pacotes até um servidor de destino."
install_rpm "Tree" "tree" "Exibição recursiva de arquivos e diretórios em formato visual de árvore."
install_rpm "Dos2unix" "dos2unix" "Conversor de quebras de linha entre os formatos Windows (CRLF) e Unix (LF)."
install_rpm "Minicom" "minicom" "Emulador de terminal serial para comunicação com dispositivos de rede e microcontroladores."
install_rpm "Lrzsz" "lrzsz" "Ferramentas de transferência de arquivos via protocolos ZMODEM, YMODEM e XMODEM."
install_rpm "Net-tools" "net-tools" "Conjunto clássico de comandos de rede do Linux (netstat, ifconfig, arp, route)."

# --- Sistema de Arquivos & Compressão ---
install_rpm "Unrar" "unrar" "Utilitário para descompactação de arquivos no formato RAR."
install_rpm "7-Zip" "7zip" "Compactador e descompactador com suporte a arquivos 7z, zip, tar e alta compressão."
install_rpm "Compsize" "compsize" "Utilitário para medição da taxa de compressão em sistemas de arquivos Btrfs."
install_rpm "Gocryptfs" "gocryptfs" "Sistema de arquivos criptografado baseado em FUSE para segurança de pastas."
install_rpm "CIFS Utils" "cifs-utils" "Utilitários para montagem e integração com compartilhamentos de rede SMB/Samba."
install_rpm "NFS Utils" "nfs-utils" "Suporte para compartilhamento e montagem de redes de arquivos NFS."

# --- Shell, Editor & Fontes ---
install_rpm "Zsh" "zsh" "Shell avançado e altamente customizável com recursos modernos de autocompletar."
install_rpm "Powerline & Fontes" "powerline powerline-fonts" "Statusline estilizada e conjunto de fontes com glifos para terminal."
install_rpm "Neovim" "neovim" "Editor de texto modal moderno, rápido e extensível baseado no Vim."
install_rpm "WL-Clipboard" "wl-clipboard" "Utilitários wl-copy e wl-paste para manipular a área de transferência no Wayland."
install_rpm "Fonte Comfortaa" "aajohan-comfortaa-fonts" "Família de fontes tipográficas geométricas TrueType Comfortaa."

# --- Aplicações Desktop & KDE ---
install_rpm "Telegram Desktop" "telegram-desktop" "Mensageiro instantâneo Telegram oficial."
install_rpm "Kdenlive" "kdenlive" "Editor de vídeo não-linear profissional e open-source do projeto KDE."
install_rpm "Deskflow" "deskflow" "Compartilhamento de mouse e teclado entre múltiplos computadores pela rede local."
install_rpm "Alacarte" "alacarte" "Editor gráfico simples para criar e modificar atalhos do menu de aplicativos."
install_rpm "Discos (GNOME Disk Utility)" "gnome-disk-utility" "Utilitário gráfico para gerenciamento de partições, formatação e SMART."
install_rpm "FFmpegThumbs" "ffmpegthumbs" "Gerador de miniaturas (thumbnails) de vídeos para o gerenciador de arquivos Dolphin."
install_rpm "Tesseract OCR" "tesseract-common tesseract-langpack-eng" "Mecanismo de reconhecimento óptico de caracteres para extração de texto de imagens."
install_rpm "Java OpenJDK 25" "java-25-openjdk-headless" "Ambiente de execução Java versão 25 (OpenJDK headless)."

# -----------------------------------------------------------------------------
step "4. Flatpaks (Flathub)"
# -----------------------------------------------------------------------------
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

install_flatpak "Artcraft Launcher" "ai.storyteller.artcraft-launcher" "Launcher e ambiente para criação de arte e jogos digitais."
install_flatpak "Vectorcraft" "ai.storyteller.vectorcraft" "Ferramenta de criação e edição gráfica vetorial."
install_flatpak "GitKraken" "com.axosoft.GitKraken" "Cliente gráfico profissional para gerenciamento visual de repositórios Git."
install_flatpak "Brave Browser" "com.brave.Browser" "Navegador focado em privacidade com bloqueador nativo de anúncios e rastreadores."
install_flatpak "Dropbox" "com.dropbox.Client" "Cliente oficial do serviço de armazenamento e sincronização na nuvem Dropbox."
install_flatpak "Flatseal" "com.github.tchx84.Flatseal" "Gerenciador gráfico para revisar e modificar permissões concedidas aos Flatpaks."
install_flatpak "Video Downloader" "com.github.unrud.VideoDownloader" "Baixador gráfico simples de vídeos e áudios de múltiplos sites da web."
install_flatpak "OBS Studio" "com.obsproject.Studio" "Software completo para gravação de tela e transmissão ao vivo (streaming)."
install_flatpak "Vivaldi Browser" "com.vivaldi.Vivaldi" "Navegador de alta produtividade com painéis laterais e divisão de abas."
install_flatpak "DBeaver Community" "io.dbeaver.DBeaverCommunity" "Gerenciador universal de bancos de dados (PostgreSQL, MySQL, SQLite, etc.)."
install_flatpak "GitHub Desktop" "io.github.shiftey.Desktop" "Interface gráfica oficial do GitHub para controle de commits e branches."
install_flatpak "Obsidian" "md.obsidian.Obsidian" "Aplicativo de notas e base de conhecimento estruturada em arquivos locais Markdown."
install_flatpak "Blender" "org.blender.Blender" "Suíte completa para modelagem 3D, escultura, animação e renderização."
install_flatpak "FileZilla" "org.filezillaproject.Filezilla" "Cliente tradicional para transferência de arquivos via FTP, FTPS e SFTP."
install_flatpak "Inkscape" "org.inkscape.Inkscape" "Editor profissional de ilustrações e gráficos vetoriais em formato SVG."
install_flatpak "Kate" "org.kde.kate" "Editor de texto avançado do KDE com abas, suporte a LSP e terminal embutido."
install_flatpak "KStars" "org.kde.kstars" "Software planetário e ferramenta de astrofotografia com controle de telescópios (EKOS)."
install_flatpak "Yakuake" "org.kde.yakuake" "Terminal suspenso drop-down estilo Quake para o KDE Plasma."
install_flatpak "KeePassXC" "org.keepassxc.KeePassXC" "Gerenciador de senhas seguro, offline e criptografado."
install_flatpak "qBittorrent" "org.qbittorrent.qBittorrent" "Cliente BitTorrent open-source, leve e livre de anúncios."
install_flatpak "VLC Media Player" "org.videolan.VLC" "Reprodutor multimídia completo compatível com quase todos os formatos de mídia."

# -----------------------------------------------------------------------------
step "5. Ativação de Serviços"
# -----------------------------------------------------------------------------
enable_service "cockpit.socket" "Cockpit Web Console" "Interface web para administração do sistema na porta 9090."
enable_service "snapd.socket" "Snapd Daemon" "Serviço necessário para rodar pacotes Snap (cria também link /snap)."
ln -sf /var/lib/snapd/snap /snap 2>/dev/null || true
enable_service "dnf-automatic.timer" "DNF Automatic Timer" "Temporizador para checagem periódica automática de atualizações."
enable_service "netdata" "Netdata Agent" "Coleta contínua de métricas de telemetria com painel web local na porta 19999."
enable_service "clamav-freshclam" "ClamAV Freshclam" "Atualização periódica automática da base de dados de vírus."

# -----------------------------------------------------------------------------
step "6. Pós-ações e Configurações Manuais"
# -----------------------------------------------------------------------------
echo ""
echo -e "\033[1;33mPara alterar seu shell para Zsh como usuário padrão, rode fora do sudo:\033[0m"
echo "  chsh -s /usr/bin/zsh"
echo ""
echo -e "\033[1;33mCaso queira iniciar seus bancos de dados locais agora:\033[0m"
echo "  sudo systemctl enable --now postgresql mariadb"

# -----------------------------------------------------------------------------
step "7. Pacotes Manuais (Download Avulso)"
# -----------------------------------------------------------------------------
cat <<'MANUAL'
  Estes softwares não possuem repositório estável oficial. Baixe o .rpm e instale com:
  sudo dnf install -y ./arquivo.rpm

  • opencode (AI desktop com updater interno)
  • chatgpt (cliente desktop oficial da OpenAI)
  • pihole-meta (pacote de metadados local)
  • slitherer (jogo)
MANUAL

# -----------------------------------------------------------------------------
step "Concluído"
# -----------------------------------------------------------------------------
echo "Log completo registrado em: $LOG_FILE"
echo "Recomenda-se reiniciar a máquina para carregar completamente serviços, fontes e codecs."
