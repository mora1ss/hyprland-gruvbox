#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${HOME}"
CONFIG_DIR="${HOME_DIR}/.config"
WALLPAPER_DIR="${HOME_DIR}/Pictures/Wallpapers"
SCREENSHOT_DIR="${HOME_DIR}/Pictures/Capturas"
HQP_DIR="${CONFIG_DIR}/quickshell/hyprquickpaper"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

info() { printf '\n==> %s\n' "$*"; }
die() { printf 'erro: %s\n' "$*" >&2; exit 1; }

if [[ "$(id -u)" -eq 0 ]]; then
  die "corre este script como utilizador normal, não como root"
fi

command -v sudo >/dev/null || die "sudo é necessário"
command -v git >/dev/null || {
  info "a instalar git"
  sudo pacman -Sy --needed --noconfirm git
}

PACMAN_PKGS=(
  hyprland
  xdg-desktop-portal-hyprland
  xdg-desktop-portal-gtk
  qt5-wayland
  qt6-wayland
  qt5ct
  kitty
  waybar
  dunst
  rofi-wayland
  neovim
  fastfetch
  thunar
  thunar-archive-plugin
  gvfs
  firefox
  hyprshot
  swww
  brightnessctl
  playerctl
  pavucontrol
  networkmanager
  pipewire
  pipewire-pulse
  wireplumber
  sddm
  qt6-declarative
  qt6-5compat
  qt6-svg
  qt6-multimedia
  qt6-multimedia-ffmpeg
  gst-plugins-base
  gst-plugins-good
  gst-plugins-bad
  gst-plugins-ugly
  fzf
  zsh
  git
  base-devel
  nwg-look
  gedit
  ark
  papirus-icon-theme
  ttf-firacode-nerd
  ttf-jetbrains-mono-nerd
  ttf-nerd-fonts-symbols
  adwaita-fonts
  noto-fonts
  noto-fonts-emoji
  alacritty
  hyprpolkitagent
  imagemagick
  jq
  code
  grim
  slurp
  wl-clipboard
)

AUR_PKGS=(
  quickshell
  gruvbox-dark-gtk
)

info "a actualizar o sistema e a instalar pacotes oficiais"
sudo pacman -Syu --needed --noconfirm "${PACMAN_PKGS[@]}"

if ! command -v yay >/dev/null; then
  info "a instalar yay"
  git clone https://aur.archlinux.org/yay.git "${TMP_DIR}/yay"
  (cd "${TMP_DIR}/yay" && makepkg -si --noconfirm)
fi

info "a instalar pacotes AUR"
yay -S --needed --noconfirm "${AUR_PKGS[@]}"

info "a instalar Oh My Zsh"
if [[ ! -d "${HOME_DIR}/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-${HOME_DIR}/.oh-my-zsh/custom}"
if [[ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions \
    "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
fi
if [[ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
fi

backup_if_exists() {
  local dest="$1"
  if [[ -e "${dest}" || -L "${dest}" ]]; then
    mv "${dest}" "${dest}.bak.$(date +%Y%m%d%H%M%S)"
  fi
}

copy_config_dir() {
  local name="$1"
  mkdir -p "${CONFIG_DIR}"
  backup_if_exists "${CONFIG_DIR}/${name}"
  cp -a "${DOTFILES}/.config/${name}" "${CONFIG_DIR}/${name}"
}

info "a copiar as configurações"
copy_config_dir dunst
copy_config_dir fastfetch
copy_config_dir hypr
copy_config_dir kitty
copy_config_dir nvim
copy_config_dir rofi
copy_config_dir waybar

backup_if_exists "${CONFIG_DIR}/gtk-3.0"
backup_if_exists "${CONFIG_DIR}/gtk-4.0"
mkdir -p "${CONFIG_DIR}"
cp -a "${DOTFILES}/.config/GTK/gtk-3.0" "${CONFIG_DIR}/gtk-3.0"
cp -a "${DOTFILES}/.config/GTK/gtk-4.0" "${CONFIG_DIR}/gtk-4.0"

backup_if_exists "${HOME_DIR}/.zshrc"
cp -a "${DOTFILES}/.zshrc" "${HOME_DIR}/.zshrc"

mkdir -p "${WALLPAPER_DIR}" "${SCREENSHOT_DIR}"
if [[ -f "${DOTFILES}/wallpaper/rockman.png" ]]; then
  cp -a "${DOTFILES}/wallpaper/rockman.png" "${WALLPAPER_DIR}/rockman.png"
fi

info "a instalar o tema Field do qylock para o SDDM"
git clone --depth 1 https://github.com/Darkkal44/qylock.git "${TMP_DIR}/qylock"
[[ -d "${TMP_DIR}/qylock/themes/field" ]] || die "tema field não encontrado no qylock"

sudo mkdir -p /usr/share/sddm/themes
sudo rm -rf /usr/share/sddm/themes/field
sudo cp -a "${TMP_DIR}/qylock/themes/field" /usr/share/sddm/themes/field

if ! grep -q '^QtVersion=' /usr/share/sddm/themes/field/metadata.desktop 2>/dev/null; then
  printf '\nQtVersion=6\n' | sudo tee -a /usr/share/sddm/themes/field/metadata.desktop >/dev/null
fi

sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/10-qylock.conf >/dev/null <<'EOF'
[Theme]
Current=field
EOF

info "a instalar hyprquickpaper"
mkdir -p "${CONFIG_DIR}/quickshell"
if [[ ! -d "${HQP_DIR}/.git" ]]; then
  rm -rf "${HQP_DIR}"
  git clone https://github.com/iamsurjog/hyprquickpaper.git "${HQP_DIR}"
fi

cat > "${HQP_DIR}/config.json" <<EOF
{
    "wallpaper_path": "${WALLPAPER_DIR}/",
    "cache_path": "${HOME_DIR}/.cache/quickshell/thumbs/",
    "number_of_pictures": 7,
    "border_color": "#A98881",
    "cache_batch_size": 20
}
EOF

cat > "${HQP_DIR}/commands.sh" <<'EOF'
#!/usr/bin/env bash
swww img "$1" -t grow --transition-duration 1
EOF
chmod +x "${HQP_DIR}/commands.sh"
mkdir -p "${HOME_DIR}/.cache/quickshell/thumbs"

info "a activar serviços"
if systemctl list-unit-files ly.service >/dev/null 2>&1; then
  sudo systemctl disable ly.service --now 2>/dev/null || true
fi
sudo systemctl enable NetworkManager.service
sudo systemctl enable sddm.service
sudo systemctl enable --now pipewire.socket pipewire-pulse.socket wireplumber.service 2>/dev/null || true

ZSH_PATH="$(command -v zsh)"
if [[ "${SHELL}" != "${ZSH_PATH}" ]]; then
  info "a definir zsh como shell por omissão"
  if ! grep -qxF "${ZSH_PATH}" /etc/shells; then
    echo "${ZSH_PATH}" | sudo tee -a /etc/shells >/dev/null
  fi
  chsh -s "${ZSH_PATH}"
fi

info "instalação concluída"
printf '%s\n' \
  "Reinicia o computador para entrar pelo SDDM (tema Field)." \
  "No Hyprland: Control+W abre o hyprquickpaper; Control+N tira um screenshot."
