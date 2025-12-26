#!/usr/bin/env bash
set -euo pipefail

# =========================
# Dotfiles Installer (Arch + Hyprland dev setup)
# Repo structure expected:
#   dotfiles/{hypr,hypridle,waybar,wofi,nvim}/...
# =========================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$SCRIPT_DIR")"

CONFIG_DIR="$HOME/.config"

install_vscode_config() {
  log "Installing VS Code configuration"

  local src="$DOTFILES_DIR/vscode"
  local dest="$HOME/.config/Code/User"

  if [[ ! -d "$src" ]]; then
    warn "No vscode/ directory found in dotfiles; skipping VS Code config."
    return 0
  fi

  mkdir -p "$dest"

  for f in settings.json keybindings.json tasks.json; do
    if [[ -f "$src/$f" ]]; then
      backup_path "$dest/$f"
      cp "$src/$f" "$dest/$f"
      log "Installed VS Code $f"
    fi
  done

  if [[ -d "$src/snippets" ]]; then
    mkdir -p "$dest/snippets"
    cp -a "$src/snippets/." "$dest/snippets/"
    log "Installed VS Code snippets"
  fi

  # Extensions
  if [[ -f "$src/extensions.txt" ]]; then
    if need_cmd code; then
      log "Installing VS Code extensions"
      while IFS= read -r ext; do
        [[ -n "$ext" ]] && code --install-extension "$ext" || true
      done < "$src/extensions.txt"
    else
      warn "VS Code not found; skipping extension install."
    fi
  fi
}

create_workspace_tree() {
  log "Creating ~/workspace tree"

  local base="$HOME/workspace"

  # EDITA AQUÍ tu estructura
  local -a WORKSPACE_DIRS=(
    "projects"
    "repos"
    "sandbox"
    "notes"
    "downloads"
  )

  mkdir -p "$base"
  for d in "${WORKSPACE_DIRS[@]}"; do
    mkdir -p "$base/$d"
  done

  log "Workspace created at: $base"
  printf " - %s\n" "${WORKSPACE_DIRS[@]/#/$base/}" || true
}


detect_dotfiles_dir() {
  # Prefer ./dotfiles if exists
  if [[ -d "$REPO_DIR/dotfiles" ]]; then
    echo "$REPO_DIR/dotfiles"
    return
  fi

  # If hypr exists at repo root, use repo root
  if [[ -d "$REPO_DIR/hypr" || -d "$REPO_DIR/waybar" || -d "$REPO_DIR/wofi" || -d "$REPO_DIR/nvim" || -d "$REPO_DIR/neovim" ]]; then
    echo "$REPO_DIR"
    return
  fi

  # Last resort: search up to depth 3 for hypr folder and use its parent
  local hypr_path
  hypr_path="$(find "$REPO_DIR" -maxdepth 3 -type d -name hypr -print -quit 2>/dev/null || true)"
  if [[ -n "$hypr_path" ]]; then
    dirname "$hypr_path"
    return
  fi

  echo "$REPO_DIR"
}

DOTFILES_DIR="$(detect_dotfiles_dir)"

# If repo has ./dotfiles use it, otherwise use repo root
if [[ -d "$REPO_DIR/dotfiles" ]]; then
  DOTFILES_DIR="$REPO_DIR/dotfiles"
else
  DOTFILES_DIR="$REPO_DIR"
fi

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
  local name="$1"
  local src="$DOTFILES_DIR/$name"
  local dest="$CONFIG_DIR/$name"

  if [[ ! -d "$src" ]]; then
    warn "No $name/ directory in $DOTFILES_DIR; skipping."
    return 0
  fi

  mkdir -p "$CONFIG_DIR"
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
  pac_install zsh curl git tmux lsd

  if need_cmd yay; then
    yay -S --needed --noconfirm tty-clock
  else
    warn "yay not found; skipping tty-clock (AUR)."
  fi

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

setup_audio_pipewire() {
  log "Audio: PipeWire + WirePlumber (replacing PulseAudio)"

  # 0) Stop user pulseaudio if running (non fatal)
  systemctl --user stop pulseaudio.service pulseaudio.socket 2>/dev/null || true

  # 1) Remove PulseAudio daemon if present (ignore if not installed)
  if pacman -Q pulseaudio >/dev/null 2>&1; then
    warn "Removing pulseaudio (conflicts with pipewire-pulse)"
    sudo pacman -Rns --noconfirm pulseaudio || true
  fi

  # Optional packages may not exist in all systems, ignore errors
  sudo pacman -Rns --noconfirm pulseaudio-alsa pulseaudio-bluetooth 2>/dev/null || true

  # 2) Install PipeWire stack (now no conflict)
  pac_install pipewire wireplumber pipewire-alsa pipewire-pulse pavucontrol

  # 3) Enable user services
  systemctl --user enable --now pipewire.service pipewire-pulse.service wireplumber.service || true
}

main() {
  confirm_sudo

  log "Updating system"
  sudo pacman -Syu --noconfirm

  log "REPO_DIR = $REPO_DIR"
  log "DOTFILES_DIR = $DOTFILES_DIR"
  log "Listing dotfiles:"
  ls -la "$DOTFILES_DIR" || true

  log "Installing base dev tools"
  pac_install \
    base-devel git curl wget unzip zip \
    ripgrep fd fzf \
    neovim tmux code \
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
    lsd \
    kitty \
    cmatrix \
    swaync \
    cava \
    thunar \
    wl-clipboard \
    swww \
    grim slurp \
    brightnessctl \
    networkmanager network-manager-applet \
    polkit-gnome \
    jq socat

  setup_audio_pipewire

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
log "REPO_DIR = $REPO_DIR"
log "DOTFILES_DIR = $DOTFILES_DIR"
ls -la "$DOTFILES_DIR" || true

mkdir -p "$CONFIG_DIR"

install_config_dir hypr
install_config_dir hypridle
install_config_dir hyprlock
install_config_dir waybar
install_config_dir swaync
install_config_dir cava
install_config_dir wofi

# soportar repo con carpeta "neovim" o "nvim"
if [[ -d "$DOTFILES_DIR/nvim" ]]; then
  install_config_dir nvim
elif [[ -d "$DOTFILES_DIR/neovim" ]]; then
  # copia neovim -> ~/.config/nvim (para que nvim lo lea)
  log "Installing config folder: neovim -> ~/.config/nvim"
  backup_path "$CONFIG_DIR/nvim"
  cp -a "$DOTFILES_DIR/neovim" "$CONFIG_DIR/nvim"
else
  warn "No nvim/ or neovim/ directory found; skipping Neovim config."
fi

  # AUR apps
  log "Installing AUR helper & optional AUR packages"
  install_yay_if_missing
  aur_install \
    brave-bin \
    neovide-bin \
    postman-bin \
    heroic-games-launcher-bin \
    bat \
    fzf-tab

  log "Creating workspace..."
  create_workspace_tree

  log "Seting up vscode..."
  install_vscode_config

  log "Done."
  warn "IMPORTANT: logout/login to apply docker group changes (or reboot)."
  log "If Hyprland doesn't autostart configs, make sure your login session starts Hyprland."
}

main "$@"
