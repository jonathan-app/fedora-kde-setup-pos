# Pós-Instalação Fedora KDE

Script de automação para restaurar todo o ambiente de desenvolvimento, produtividade e ferramentas de sistema após uma instalação limpa do **Fedora KDE Plasma**.

![Fedora](https://img.shields.io/badge/Fedora-40%2B-blue?logo=fedora&logoColor=white)
![KDE Plasma](https://img.shields.io/badge/KDE-Plasma%206-1d99f3?logo=kde&logoColor=white)
![Shell](https://img.shields.io/badge/bash-5%2B-4EAA25?logo=gnubash&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green)

---

## Destaques

- **Instalação Interativa 1 a 1**: cada aplicativo exibe seu nome e descrição detalhada, perguntando se você deseja instalá-lo (`[S/n]`).
- **Idempotente**: pode ser executado múltiplas vezes sem conflitos ou sobrescritas indesejadas.
- **Resiliente a erros**: valida cada pacote com `dnf repoquery` antes de instalar, evitando que um pacote ausente interrompa o processo.
- **Registro completo de logs**: saída duplicada no terminal e gravada em `/var/log/post-install-fedora.log`.
- **Separação de escopo**: o script cuida de repositórios, binários e serviços; dotfiles e chaves pessoais permanecem no controle do usuário.

---

## Instruções de Uso

### Opção 1: Clonando o repositório (Recomendado)

```bash
git clone https://github.com/jonathan-app/fedora-kde-setup-pos.git
cd fedora-kde-setup-pos
chmod +x post-install-fedora-kde.sh
sudo ./post-install-fedora-kde.sh
```

### Opção 2: Criando o arquivo manualmente

1. Crie o arquivo do script no seu sistema:
```bash
nano post-install-fedora-kde.sh
```

2. Cole o conteúdo do script, salve (`Ctrl+O`, `Enter`) e saia (`Ctrl+X`).

3. Conceda permissão de execução:
```bash
chmod +x post-install-fedora-kde.sh
```

4. Execute o script com privilégios administrativos:
```bash
sudo ./post-install-fedora-kde.sh
```

5. **Reinicie o sistema** ao término para garantir o carregamento correto de serviços em segundo plano, como `snapd`, fontes e recursos do shell.

---

## Etapas da Automação

1. **Atualização do Sistema**: sincronização e atualização completa de pacotes existentes via `dnf upgrade --refresh`.
2. **RPM Fusion**: habilita os repositórios `free` e `nonfree` com codecs de áudio/vídeo (`gstreamer1-plugins-bad-freeworld`, `ugly`).
3. **Repositórios de Terceiros**:
   - Adoptium (Eclipse Temurin JDK)
   - Netdata (agente de telemetria)
   - Google Chrome & Microsoft Edge
   - Sublime Text
   - AnyDesk
   - Cloudflare WARP
4. **Instalação de Pacotes RPM**: lote com compiladores, ferramentas dev, bancos de dados, utilitários de rede, fontes e clientes GUI.
5. **Configuração de Flatpaks**: adiciona o remote oficial do Flathub e instala os navegadores e aplicativos de produtividade.
6. **Habilitação de Serviços**: ativa `cockpit.socket`, `snapd.socket`, `dnf-automatic.timer`, `netdata` e `clamav-freshclam`.
7. **Guia de Pacotes Manuais**: lista lembretes de softwares distribuídos exclusivamente via `.rpm` avulso.

---

## Softwares Instalados

### Pacotes RPM (via DNF)

| Categoria | Pacotes |
|---|---|
| **Desenvolvimento** | `git`, `gcc`, `gcc-c++`, `make`, `cmake`, `rust`, `cargo`, `gh`, `nodejs22-npm-bin`, `uv`, `python3-devel`, `python3-pip`, `python3-virtualenv`, `python3-black`, `python3-flake8`, headers (`openssl`, `dbus`, `gtk-layer-shell`, `librsvg2`, `webkit2gtk4.1`, `libappindicator`), `patchelf` |
| **Bancos & Serviços** | `postgresql`, `mariadb-server`, `sqlite`, `redis` (valkey), `netdata`, `clamav`, `snapd`, `cockpit` (bridge, networkmanager, storaged, system, ws), `dnf-automatic`, `openscap-scanner` |
| **Contêineres** | `podman-compose`, `podman-docker` |
| **Monitoramento & CLI** | `htop`, `fastfetch`, `btop`, `glances`, `atop`, `nmon`, `iptstate` |
| **Rede & Diagnóstico** | `bind-utils`, `mtr`, `tcpdump`, `nmap-ncat`, `whois`, `traceroute`, `tree`, `dos2unix`, `minicom`, `lrzsz`, `net-tools` |
| **Arquivos & Sistema** | `unrar`, `7zip`, `compsize`, `gocryptfs`, `cifs-utils`, `nfs-utils` |
| **Shell & Fontes** | `zsh`, `powerline`, `powerline-fonts`, `neovim`, `wl-clipboard`, `aajohan-comfortaa-fonts` |
| **Aplicações Desktop** | `telegram-desktop`, `kdenlive`, `sublime-text`, `deskflow`, `alacarte`, `anydesk`, `google-chrome-stable`, `microsoft-edge-stable`, `cloudflare-warp` |
| **Multimídia & Java** | `vlc-plugin-gstreamer`, `gstreamer1-plugin-libav`, `faad2-libs`, `java-25-openjdk-headless`, `ffmpegthumbs` |

### Aplicativos Flatpak (Flathub)

| Categoria | Identificador / App |
|---|---|
| **Navegação & Comunicação** | Brave, Vivaldi, Telegram, Dropbox |
| **Desenvolvimento & Banco** | GitKraken, GitHub Desktop, DBeaver Community, Kate |
| **Design & Mídia** | Blender, Inkscape, OBS Studio, VLC, Video Downloader |
| **Produtividade & Notas** | Obsidian, KeePassXC, qBittorrent, KStars, Yakuake, Flatseal |
| **Criativo / IA** | Artcraft Launcher, Vectorcraft |

### Pacotes Manuais (Sem repositório estável)

Baixe os pacotes `.rpm` dos respectivos fornecedores e instale com `sudo dnf install ./nome-do-arquivo.rpm`:

- `chatgpt` (cliente oficial desktop OpenAI)
- `opencode` (AI desktop com auto-updater)
- `pihole-meta` (metapackage local customizado)
- `slitherer`

---

## Passos Manuais Pós-Script

Algumas alterações devem ser feitas com o usuário não-root após a reinicialização:

```bash
# Definir Zsh como shell padrão para o seu usuário:
chsh -s /usr/bin/zsh

# (Opcional) Inicializar serviços de banco de dados se for utilizá-los localmente:
sudo systemctl enable --now postgresql mariadb
```

---

## Estrutura do Repositório

```text
pos-install_fedora-kde/
├── post-install-fedora-kde.sh   # Script bash principal
├── README.md                    # Documentação do projeto
└── dotfiles/                    # (Opcional) Guarde suas configs (~/.zshrc, ~/.config)
```

---

## Licença

Distribuído sob a licença [MIT](LICENSE). Sinta-se livre para clonar, adaptar para seu fluxo e compartilhar.
