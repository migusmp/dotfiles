#!/usr/bin/env bash
set -euo pipefail

# =========================
# Dotfiles Installer (Arch + Hyprland dev setup)
# Repo structure expected:
#   dotfiles/{hypr,hypridle,waybar,wofi,nvim}/...
# =========================

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"

log() { printf "\n\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\n\033[1;33m[WARN]\033[0m %s\n" "$*"; }
die() { printf "\n\033[1;31m[ERR]\033[0m %s\n" "$*"; exit 1; }

need_cmd() { command -v "$1" >/dev/null 2>&1; }

confirm_sudo() {
  if ! sudo -v; then
    die "No sudo permissions."
  fi
}

pac_install() {
  local pkgs=("$@")
  sudo pacman -S --needed --noconfirm "${pkgs[@]}"
}

enable_service() {
  local svc="$1"
  sudo systemctl enable --now "$svc"
}

backup_path() {
  local path="$1"
  if [[ -e "$path" ]]; then
    local ts
    ts="$(date +%Y%m%d-%H%M%S)"
    log "Backup: $path -> ${path}.bak-${ts}"
    mv "$path" "${path}.bak-${ts}"
  fi
}

install_config_dir() {
  local name="$1"              # hypr, waybar, nvim, ...
  local src="$REPO_DIR/$name"
  local dest="$HOME/.config/$name"

  if [[ ! -d "$src" ]]; then
    warn "No $name/ directory in repo; skipping."
    return 0
  fi

  mkdir -p "$HOME/.config"
  backup_path "$dest"

  log "Installing config folder: $name -> ~/.config/$name"
  cp -a "$src" "$dest"
}

install_yay_if_missing() {
  if need_cmd yay; then
    return 0
  fi

  log "Installing yay (AUR helper)"
  pac_install git base-devel

  local tmpdir
  tmpdir="$(mktemp -d)"
  (
    cd "$tmpdir"
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
  )
  rm -rf "$tmpdir"
}

aur_install() {
  local pkgs=("$@")
  if ! need_cmd yay; then
    warn "yay not found; skipping AUR packages: ${pkgs[*]}"
    return 0
  fi
  yay -S --needed --noconfirm "${pkgs[@]}"
}

install_zsh() {
  log "Installing ZSH and Oh My Zsh + plugins (awesomepanda)"

  # deps útiles para tu zshrc
  pac_install zsh curl git tmux lsd tty-clock

  # poner zsh como shell por defecto
  if [[ "${SHELL:-}" != "/bin/zsh" ]]; then
    log "Setting zsh as default shell"
    chsh -s /bin/zsh "$USER"
  fi

  # instalar oh-my-zsh si no existe
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log "Installing Oh My Zsh"
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  # plugins
  local ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
  mkdir -p "$ZSH_CUSTOM/plugins"

  log "Installing ZSH plugins"
  [[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]] || \
    git clone https://github.com/zsh-users/zsh-autosuggestions \
      "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

  [[ -d "$ZSH_CUSTOM/plugins/fast-syntax-highlighting" ]] || \
    git clone https://github.com/zdharma-continuum/fast-syntax-highlighting \
      "$ZSH_CUSTOM/plugins/fast-syntax-highlighting"

  if [[ ! -f "$HOME/.oh-my-zsh/themes/awesomepanda.zsh-theme" ]]; then
    warn "awesomepanda theme not found in oh-my-zsh themes folder. It may still work if your OMZ includes it."
  fi

  log "Writing ~/.zshrc (your config)"
  cat > "$HOME/.zshrc" <<'EOF'
#a
#If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="awesomepanda"

plugins=(
    git
    archlinux
    zsh-autosuggestions
#    zsh-syntax-highlighting
    fast-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# My alias
alias cty='tty-clock -S -c -C 6 -t -n -D'
alias fucking='sudo'
alias n='nvim'

alias t='tmux'
alias ta='tmux attach'
alias tl='tmux ls'

alias cd..='cd ..'

alias gc='git clone '
alias ga='git add .'
alias gcm='git commit -m '
alias gp='git push -u origin main'
alias gs='git status'

alias py='python3'
alias icat='kitty +kitten icat'
alias hypr='exec hyprland'
alias vscode='code --disable-gpu'
alias heroicgameslauncher='heroic --enable-features=UseOzonePlatform --ozone-platform=x11'
alias nv='neovide'
alias lsa='lsd -la'
alias ls='lsd'

alias access_token='sudo cat ~/secure/.access_token'
alias nasm_fix='nasm -f elf64 -w+all'
alias dockerdbrustydrive='docker exec -it postgres_db psql -U admin -d rusty_drive_db'

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# fastfetch

export PATH=~/bin:$PATH
export PATH="$HOME/.surrealdb:$PATH"
export PATH="$PATH:$HOME/.local/bin"
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# Yazi Setup
export EDITOR="nvim"
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# . "/home/migus/.deno/env"

alias xampp-start='sudo /opt/lampp/lampp start'
alias xampp-stop='sudo /opt/lampp/lampp stop'
alias xampp-restart='sudo /opt/lampp/lampp restart'
EOF
}

install_kitty() {
  log "Installing Kitty terminal config"
  pac_install kitty

  mkdir -p "$HOME/.config/kitty"

  log "Writing ~/.config/kitty/kitty.conf"
  cat > "$HOME/.config/kitty/kitty.conf" <<'EOF'
shell zsh

font_family JetBrainsMono Nerd Font
font_size 15.0
# font_family Victor Mono Light

map ctrl+shift+c copy_to_clipboard
map ctrl+shift+v paste_from_clipboard
EOF
}

main() {
  confirm_sudo

  log "Updating system"
  sudo pacman -Syu --noconfirm

  log "Installing base dev tools"
  pac_install \
    base-devel git curl wget unzip zip \
    ripgrep fd fzf \
    neovim tmux \
    openssh rsync \
    htop btop tree lsof strace \
    archlinux-keyring

  log "Installing programming toolchains"
  pac_install \
    nodejs npm pnpm \
    rustup \
    jdk-openjdk maven gradle \
    gcc clang cmake ninja gdb \
    python python-pip

  log "Installing desktop / Hyprland essentials (functional setup)"
  pac_install \
    hyprland \
    xdg-desktop-portal-hyprland \
    hyprlock hypridle \
    waybar \
    wofi \
    kitty \
    thunar \
    wl-clipboard \
    grim slurp \
    brightnessctl \
    pipewire wireplumber pipewire-alsa pipewire-pulse pavucontrol \
    networkmanager network-manager-applet \
    polkit-gnome \
    jq socat

  log "Enabling NetworkManager"
  enable_service NetworkManager

  log "Setting Rust toolchain (stable)"
  if ! rustup show >/dev/null 2>&1; then
    rustup default stable
  else
    rustup default stable || true
  fi

  log "Installing Docker"
  pac_install docker docker-compose
  enable_service docker
  sudo usermod -aG docker "$USER" || true

  log "Fonts (nerd fonts)"
  pac_install ttf-jetbrains-mono-nerd ttf-firacode-nerd
  fc-cache -fv || true

  # Shell + terminal configs
  install_zsh
  install_kitty

  # Dotfiles configs (repo -> ~/.config)
  log "Installing dotfiles configs"
  mkdir -p "$CONFIG_DIR"

  install_config_dir hypr
  install_config_dir hypridle
  install_config_dir waybar
  install_config_dir wofi
  install_config_dir nvim

  # AUR apps
  log "Installing AUR helper & optional AUR packages"
  install_yay_if_missing
  aur_install \
    visual-studio-code-bin \
    brave-bin \
    neovide-bin \
    postman-bin \
    heroic-games-launcher-bin \
    bat \
    yazi-git \
    fzf-tab

  log "Done."
  warn "IMPORTANT: logout/login to apply docker group changes (or reboot)."
  log "If Hyprland doesn't autostart configs, make sure your login session starts Hyprland."
}

main "$@"
