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

install_tmux_ultra() {
  log "Installing tmux ULTRA setup (TPM + sessionizer + layouts + plugins + binds)"

  # --- packages (base) ---
  sudo pacman -S --needed --noconfirm \
    tmux git fzf fd ripgrep bat wl-clipboard fuser \
    awk sed coreutils findutils

  # notify-send
  sudo pacman -S --needed --noconfirm libnotify || true

  # lazydocker (try pacman first; if not available, try AUR helper)
  if ! command -v lazydocker >/dev/null 2>&1; then
    if sudo pacman -S --needed --noconfirm lazydocker >/dev/null 2>&1; then
      :
    else
      if command -v yay >/dev/null 2>&1; then
        yay -S --needed --noconfirm lazydocker
      elif command -v paru >/dev/null 2>&1; then
        paru -S --needed --noconfirm lazydocker
      else
        warn "lazydocker not installed (no pacman pkg / no AUR helper). You can install it later."
      fi
    fi
  fi

  # --- projects root ---
  mkdir -p "$HOME/workspace/projects"

  # --- sessionizer with layouts ---
  mkdir -p "$HOME/.local/bin"
  cat > "$HOME/.local/bin/tmux-sessionizer" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$HOME/workspace/projects"
[[ -d "$ROOT" ]] || ROOT="$HOME"

need() { command -v "$1" >/dev/null 2>&1; }

if ! need fzf; then
  echo "tmux-sessionizer: fzf not installed" >&2
  exit 1
fi

list_dirs() {
  if need fd; then
    fd -t d -d 3 . "$ROOT" 2>/dev/null
  else
    find "$ROOT" -maxdepth 3 -type d 2>/dev/null
  fi
}

# 1) pick project dir
dir="$(list_dirs | fzf --prompt="Projects > " --height=60% --reverse || true)"
[[ -z "${dir:-}" ]] && exit 0

name="$(basename "$dir" | tr '. ' '__')"

# 2) pick layout
layout="$(
  printf "%s\n" "default" "rust" "node" "laravel" \
  | fzf --prompt="Layout > " --height=40% --reverse --no-multi || true
)"
[[ -z "${layout:-}" ]] && layout="default"

# 3) create or switch session
if tmux has-session -t "$name" 2>/dev/null; then
  tmux switch-client -t "$name"
  exit 0
fi

tmux new-session -d -s "$name" -c "$dir"

case "$layout" in
  rust)
    tmux rename-window -t "$name:1" "nvim"
    tmux send-keys -t "$name:1" "nvim ." C-m

    tmux new-window -t "$name" -n "run" -c "$dir"
    tmux send-keys -t "$name:2" "cargo run" C-m

    tmux new-window -t "$name" -n "test" -c "$dir"
    tmux send-keys -t "$name:3" "cargo test" C-m
    ;;
  node)
    tmux rename-window -t "$name:1" "nvim"
    tmux send-keys -t "$name:1" "nvim ." C-m

    tmux new-window -t "$name" -n "dev" -c "$dir"
    tmux send-keys -t "$name:2" "pnpm dev || npm run dev || yarn dev" C-m

    tmux new-window -t "$name" -n "test" -c "$dir"
    tmux send-keys -t "$name:3" "pnpm test || npm test || yarn test" C-m
    ;;
  laravel)
    tmux rename-window -t "$name:1" "nvim"
    tmux send-keys -t "$name:1" "nvim ." C-m

    tmux new-window -t "$name" -n "serve" -c "$dir"
    tmux send-keys -t "$name:2" "php artisan serve" C-m

    tmux new-window -t "$name" -n "queue" -c "$dir"
    tmux send-keys -t "$name:3" "php artisan queue:work" C-m
    ;;
  default|*)
    tmux rename-window -t "$name:1" "nvim"
    tmux send-keys -t "$name:1" "nvim ." C-m

    tmux new-window -t "$name" -n "shell" -c "$dir"
    ;;
esac

tmux select-window -t "$name:1"
tmux switch-client -t "$name"
EOF
  chmod +x "$HOME/.local/bin/tmux-sessionizer"

  # --- TPM ---
  mkdir -p "$HOME/.tmux/plugins"
  if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  else
    (cd "$HOME/.tmux/plugins/tpm" && git pull --ff-only) || true
  fi

  # --- tmux.conf ULTRA (includes everything) ---
  cat > "$HOME/.tmux.conf" <<'EOF'
##### General #####
set -g mouse on
set -g history-limit 200000
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

# Faster escape (better for nvim)
set -g escape-time 0
set -g focus-events on

# Truecolor + better terminal
set -g default-terminal "tmux-256color"
set -as terminal-features ',xterm-256color:RGB'

##### Prefix #####
unbind C-b
set -g prefix C-a
bind C-a send-prefix

##### Splits (more natural) #####
unbind '"'
unbind %
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

##### Reload config #####
bind r source-file ~/.tmux.conf \; display-message "tmux reloaded"

##### Navigation (vim-like, no prefix) #####
bind -n C-h select-pane -L
bind -n C-j select-pane -D
bind -n C-k select-pane -U
bind -n C-l select-pane -R

##### Resize panes (Alt + hjkl) #####
bind -n M-h resize-pane -L 5
bind -n M-l resize-pane -R 5
bind -n M-j resize-pane -D 5
bind -n M-k resize-pane -U 5

##### Copy mode (vi) + Wayland clipboard #####
setw -g mode-keys vi
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi y send -X copy-pipe-and-cancel "wl-copy"
bind -T copy-mode-vi Escape send -X cancel
bind [ copy-mode

##### Quality: keep cwd when creating windows/panes #####
bind c new-window -c "#{pane_current_path}"

##### Better window switching #####
bind -n M-1 select-window -t 1
bind -n M-2 select-window -t 2
bind -n M-3 select-window -t 3
bind -n M-4 select-window -t 4
bind -n M-5 select-window -t 5
bind -n M-6 select-window -t 6
bind -n M-7 select-window -t 7
bind -n M-8 select-window -t 8
bind -n M-9 select-window -t 9

##### Sessionizer (fzf + layouts) #####
# Prefix + f opens project picker and layout picker
# Popup if tmux >= 3.2, else split fallback.
if-shell -b 'tmux -V | awk "{print \\$2}" | awk -F. "{exit !(\\$1>3 || (\\$1==3 && \\$2>=2))}"' \
  'bind f display-popup -E "$HOME/.local/bin/tmux-sessionizer"' \
  'bind f split-window -v -c "#{pane_current_path}" "$HOME/.local/bin/tmux-sessionizer"'

##### Fuzzy switch windows/panes #####
# Prefix + w: fuzzy select window
bind w display-popup -E 'tmux list-windows -F "#{window_index}: #{window_name}  (#{window_panes} panes)" | fzf | cut -d: -f1 | xargs -r tmux select-window -t'
# Prefix + p: fuzzy select pane across session
bind p display-popup -E 'tmux list-panes -s -F "#{session_name}:#{window_index}.#{pane_index}  #{pane_current_path}" | fzf | awk "{print \\$1}" | xargs -r tmux select-pane -t'

##### Search across panes (last ~5000 lines each) #####
# Prefix + / then type query
bind / command-prompt -p "Search panes:" \
  "run-shell 'q=\"%%\"; tmux list-panes -a -F \"#D\" | while read -r id; do tmux capture-pane -pt \"${id}\" -S -5000 | rg -n --color=never \"$q\" && echo \"---\"; done | less -R'"

##### Sync panes (multi-cursor) #####
# Prefix + s toggles synchronize-panes
bind s setw synchronize-panes \; display-message "sync panes: #{?pane_synchronized,ON,OFF}"

##### Scratch popup #####
# Prefix + x opens scratch session
bind x display-popup -E 'tmux new-session -A -s scratch'

##### Notifications #####
# Prefix + N sends a desktop notification
bind N run-shell 'command -v notify-send >/dev/null 2>&1 && notify-send "tmux" "Done" || true'

##### Docker control #####
# Prefix + d opens lazydocker if installed
bind d display-popup -E 'command -v lazydocker >/dev/null 2>&1 && lazydocker || (echo "lazydocker not installed"; read -r)'

##### Kill port #####
# Prefix + k then type a port number (e.g. 3000)
bind k command-prompt -p "Kill port:" "run-shell 'p=\"%%\"; fuser -k ${p}/tcp 2>/dev/null && tmux display-message \"killed port ${p}\" || tmux display-message \"nothing on ${p}\"'"

##### Focus mode #####
bind F set -g status off \; display-message "FOCUS MODE"
bind B set -g status on  \; display-message "NORMAL MODE"

##### Status bar (clean + useful) #####
set -g status on
set -g status-interval 3
set -g status-style bg=default,fg=white

set -g status-left-length 80
set -g status-left "#[fg=cyan] #S #[fg=white]| #[fg=magenta]#(whoami) "

set -g status-right-length 180
set -g status-right "#[fg=yellow]#(git -C #{pane_current_path} rev-parse --abbrev-ref HEAD 2>/dev/null) #[fg=white]| #[fg=green]#(tmux-cpu 2>/dev/null) #[fg=cyan]#(tmux-battery 2>/dev/null) #[fg=white]| #[fg=green]%Y-%m-%d %H:%M "

##### Plugins (TPM) #####
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'

# Persist sessions
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @continuum-restore 'on'
set -g @resurrect-capture-pane-contents 'on'

# Status utils
set -g @plugin 'tmux-plugins/tmux-cpu'
set -g @plugin 'tmux-plugins/tmux-battery'

# nvim <-> tmux navigation consistency
set -g @plugin 'christoomey/vim-tmux-navigator'

run '~/.tmux/plugins/tpm/tpm'
EOF

  log "tmux ULTRA installed:"
  log "  - ~/.tmux.conf"
  log "  - ~/.local/bin/tmux-sessionizer"
  log "  - ~/.tmux/plugins/tpm"

  # If already inside tmux, reload + try install plugins automatically
  if [[ -n "${TMUX:-}" ]]; then
    tmux source-file "$HOME/.tmux.conf" || true
    tmux run-shell "$HOME/.tmux/plugins/tpm/bin/install_plugins" || true
  else
    warn "Open tmux and press Ctrl+a then I to install plugins (TPM)."
  fi
}

ensure_xampp_compat() {
  log "Ensuring XAMPP compatibility (libxcrypt-compat)"

  sudo pacman -S --needed --noconfirm libxcrypt-compat

  if [[ -x /opt/lampp/lampp ]]; then
    log "Starting XAMPP"
    sudo /opt/lampp/lampp start
  else
    warn "XAMPP not found at /opt/lampp"
  fi
}

install_xampp() {
  log "Installing XAMPP (LAMPP stack)"

  XAMPP_DIR="/opt/lampp"
  INSTALLER="/tmp/xampp-installer.run"
  XAMPP_URL="https://sourceforge.net/projects/xampp/files/XAMPP%20Linux/8.2.12/xampp-linux-x64-8.2.12-0-installer.run/download"

  # --- 1) Si ya existe, no reinstalar ---
  if [[ -d "$XAMPP_DIR" ]]; then
    log "XAMPP already installed at $XAMPP_DIR"
  else
    log "Downloading XAMPP installer"
    wget -O "$INSTALLER" "$XAMPP_URL"

    chmod +x "$INSTALLER"

    log "Running XAMPP installer (GUI)"
    sudo "$INSTALLER"
  fi
}

install_cloudflare_warp() {
  log "Installing Cloudflare WARP (1.1.1.1) + ensuring daemon/registration"

  # --- 1) Asegurar AUR helper ---
  if command -v yay >/dev/null 2>&1; then
    AUR_HELPER="yay"
  elif command -v paru >/dev/null 2>&1; then
    AUR_HELPER="paru"
  else
    die "Need an AUR helper (yay or paru) to install cloudflare-warp-bin."
  fi

  # --- 2) Instalar warp-cli si no existe ---
  if ! command -v warp-cli >/dev/null 2>&1; then
    "$AUR_HELPER" -S --needed --noconfirm cloudflare-warp-bin
  else
    log "warp-cli already installed"
  fi

  # --- 3) Asegurar daemon activo ---
  sudo systemctl daemon-reload || true

  if systemctl list-unit-files | grep -q '^warp-svc\.service'; then
    sudo systemctl enable --now warp-svc.service
  else
    die "warp-svc.service not found after install. Check package installation."
  fi

  # Espera a que el daemon cree el socket y warp-cli pueda hablar con él
  for _ in {1..50}; do
    if warp-cli status >/dev/null 2>&1; then
      break
    fi
    sleep 0.2
  done

  # --- 4) Registro idempotente + ToS no interactivo ---
  WARP="warp-cli --accept-tos"

  if $WARP registration show >/dev/null 2>&1; then
    log "WARP registration already OK"
  else
    log "Registering WARP client (non-interactive)"
    $WARP registration new
  fi

  # --- 5) Modo y conexión ---
  # Opciones: warp | doh | warp+doh
  $WARP mode warp
  log "WARP installed & registered. You can connect later with: warp-cli connect"

  # --- 6) Verificación real ---
  if command -v curl >/dev/null 2>&1; then
    if curl -fsSL https://www.cloudflare.com/cdn-cgi/trace/ | grep -q 'warp=on'; then
      log "Cloudflare WARP connected ✅ (warp=on)"
    else
      warn "WARP connected but not verified as warp=on yet. Run: warp-cli status"
      $WARP status || true
    fi
  else
    warn "curl not installed; skipping 'warp=on' verification"
    $WARP status || true
  fi
}

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
# =========================================================
# Zsh PRO config (Oh-My-Zsh + tmux workflow)
# =========================================================

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# -------------------------
# PATH (keep it in one place)
# -------------------------
typeset -U path PATH
path=(
  "$HOME/bin"
  "$HOME/.cargo/bin"
  "$HOME/.surrealdb"
  "$HOME/.local/bin"     # pipx
  $path
)
export PATH

# -------------------------
# Oh-My-Zsh
# -------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="awesomepanda"

plugins=(
  git
  archlinux
  zsh-autosuggestions
  fast-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

# -------------------------
# FZF (Ctrl+R history, completion)
# -------------------------
if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh
fi
if [[ -f /usr/share/fzf/completion.zsh ]]; then
  source /usr/share/fzf/completion.zsh
fi

# -------------------------
# History (pro)
# -------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt appendhistory
setopt sharehistory
setopt hist_ignore_dups
setopt hist_ignore_space
setopt inc_append_history

# -------------------------
# QoL options
# -------------------------
setopt autocd
setopt correct
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select

# -------------------------
# Editor
# -------------------------
export EDITOR="nvim"

# -------------------------
# Pywal (optional)
# -------------------------
# (cat ~/.cache/wal/sequences &)
# source ~/.cache/wal/colors-tty.sh

# -------------------------
# Yazi (cd on exit)
# -------------------------
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  command yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# -------------------------
# Aliases
# -------------------------

# Terminal / tools
alias cty='tty-clock -S -c -C 6 -t -n -D'
alias fucking='sudo'
alias n='nvim'
alias py='python3'
alias icat='kitty +kitten icat'
alias nv='neovide'
alias ipinfo='curl -s ipinfo.io'

# ls (you use lsd)
alias ls='lsd'
alias lsa='lsd -la'

# cd
alias cd..='cd ..'

# tmux
alias t='tmux'
alias ta='tmux attach'
alias tl='tmux ls'

# Git (avoid conflicts)
alias gcl='git clone '
alias ga='git add .'
alias gcm='git commit -m '
alias gp='git push -u origin main'
alias gs='git status'

# C/C++ (don’t override git clone)
alias gpp='g++ -o o'

# Hyprland / apps
alias hypr='exec hyprland'
alias vscode='code --disable-gpu'
alias heroicgameslauncher='heroic --enable-features=UseOzonePlatform --ozone-platform=x11'

# Secrets / misc
alias access_token='sudo cat ~/secure/.access_token'
alias nasm_fix='nasm -f elf64 -w+all'
alias dockerdbrustydrive='docker exec -it postgres_db psql -U admin -d rusty_drive_db'

# XAMPP
alias xampp-start='sudo /opt/lampp/lampp start'
alias xampp-stop='sudo /opt/lampp/lampp stop'
alias xampp-restart='sudo /opt/lampp/lampp restart'

# -------------------------
# Auto-start tmux (optional)
# Set to 1 to enable
# -------------------------
AUTO_TMUX="${AUTO_TMUX:-0}"

if [[ "$AUTO_TMUX" == "1" ]] && [[ -o interactive ]] && command -v tmux >/dev/null 2>&1; then
  if [[ -z "${TMUX:-}" ]]; then
    tmux new-session -A -s main
  fi
fi

# -------------------------
# End
# -------------------------
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
    ripgrep fd fzf eza bat starship \
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
    swappy \
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
    postman-bin \
    cloudflare-warp-bin \
    bat \
    fzf-tab

  log "Creating workspace..."
  create_workspace_tree

  log "Seting up vscode..."
  install_vscode_config

  install_cloudflare_warp

  install_xampp
  ensure_xampp_compat
  install_tmux_ultra

  log "Done."
  warn "IMPORTANT: logout/login to apply docker group changes (or reboot)."
  log "If Hyprland doesn't autostart configs, make sure your login session starts Hyprland."
}

main "$@"
