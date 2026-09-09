#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${HOME}"
CONFIG_DIR="${HOME_DIR}/.config"
WALLPAPER_DIR="${HOME_DIR}/Imagens/Wallpapers"
SCREENSHOT_DIR="${HOME_DIR}/Imagens/Capturas"
HQP_DIR="${CONFIG_DIR}/quickshell/hyprquickpaper"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

info() { printf '\n==> %s\n' "$*"; }
warn() { printf 'aviso: %s\n' "$*" >&2; }
die() { printf 'erro: %s\n' "$*" >&2; exit 1; }

if [[ "$(id -u)" -eq 0 ]]; then
  die "corre este script como utilizador normal, não como root"
fi

command -v sudo >/dev/null || die "sudo é necessário"
command -v git >/dev/null || {
  info "a instalar git"
  sudo pacman -Sy --needed --noconfirm git
}

has_nvidia_gpu() {
  lspci 2>/dev/null | grep -qiE 'VGA compatible controller: NVIDIA|3D controller: NVIDIA'
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
  polkit-kde-agent
  imagemagick
  jq
  code
  grim
  slurp
  wl-clipboard
  pciutils
  ffmpeg
  xdg-user-dirs
  file
)

AUR_PKGS=(
  quickshell
  gruvbox-dark-gtk
)

info "a actualizar o sistema e a instalar pacotes oficiais"
sudo pacman -Syu --needed --noconfirm "${PACMAN_PKGS[@]}"

if has_nvidia_gpu; then
  info "GPU NVIDIA detectada: a instalar drivers e VA-API (DRM / Prime Video)"
  NVIDIA_PKGS=(
    nvidia-open
    nvidia-utils
    nvidia-settings
    libva
    libva-nvidia-driver
    libva-utils
    egl-wayland
  )
  for k in linux linux-lts linux-zen linux-hardened; do
    if pacman -Q "${k}" >/dev/null 2>&1; then
      NVIDIA_PKGS+=("${k}-headers")
    fi
  done
  sudo pacman -S --needed --noconfirm "${NVIDIA_PKGS[@]}"
else
  warn "nenhuma GPU NVIDIA detectada; a saltar drivers NVIDIA (normal numa VM)"
fi

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

info "a criar pastas pessoais (Documentos, Transferências, Projetos, …)"
mkdir -p \
  "${HOME_DIR}/Ambiente de Trabalho" \
  "${HOME_DIR}/Documentos" \
  "${HOME_DIR}/Transferências" \
  "${HOME_DIR}/Imagens" \
  "${HOME_DIR}/Música" \
  "${HOME_DIR}/Vídeos" \
  "${HOME_DIR}/Modelos" \
  "${HOME_DIR}/Público" \
  "${HOME_DIR}/Projetos" \
  "${WALLPAPER_DIR}" \
  "${SCREENSHOT_DIR}" \
  "${HOME_DIR}/.local/bin"

if [[ -f "${DOTFILES}/wallpaper/rockman.png" ]]; then
  cp -a "${DOTFILES}/wallpaper/rockman.png" "${WALLPAPER_DIR}/rockman.png"
fi

cat > "${CONFIG_DIR}/user-dirs.dirs" <<EOF
XDG_DESKTOP_DIR="\$HOME/Ambiente de Trabalho"
XDG_DOWNLOAD_DIR="\$HOME/Transferências"
XDG_TEMPLATES_DIR="\$HOME/Modelos"
XDG_PUBLICSHARE_DIR="\$HOME/Público"
XDG_DOCUMENTS_DIR="\$HOME/Documentos"
XDG_MUSIC_DIR="\$HOME/Música"
XDG_PICTURES_DIR="\$HOME/Imagens"
XDG_VIDEOS_DIR="\$HOME/Vídeos"
EOF
echo 'pt_PT' > "${CONFIG_DIR}/user-dirs.locale"

cat > "${CONFIG_DIR}/gtk-3.0/bookmarks" <<EOF
file://${HOME_DIR}/Documentos Documentos
file://${HOME_DIR}/Transferências Transferências
file://${HOME_DIR}/Imagens Imagens
file://${HOME_DIR}/Música Música
file://${HOME_DIR}/Vídeos Vídeos
file://${HOME_DIR}/Projetos Projetos
file://${HOME_DIR}/Ambiente%20de%20Trabalho Ambiente de Trabalho
EOF

install -m 755 "${DOTFILES}/scripts/hyprquickpaper" "${HOME_DIR}/.local/bin/hyprquickpaper"
xdg-user-dirs-update >/dev/null 2>&1 || true

write_chromium_flags() {
  local file="$1"
  mkdir -p "$(dirname "${file}")"
  cat > "${file}" <<'EOF'
--ozone-platform=wayland
--disable-gpu-sandbox
EOF
}

write_chromium_flags "${CONFIG_DIR}/chromium-flags.conf"
write_chromium_flags "${CONFIG_DIR}/chrome-flags.conf"
write_chromium_flags "${CONFIG_DIR}/brave-flags.conf"
write_chromium_flags "${CONFIG_DIR}/code-flags.conf"
write_chromium_flags "${CONFIG_DIR}/electron-flags.conf"

configure_nvidia() {
  info "a aplicar configuração NVIDIA (DRM, VA-API, Firefox)"

  cat > "${CONFIG_DIR}/hypr/nvidia.lua" <<'EOF'
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

hl.config({
  cursor = {
    no_hardware_cursors = true,
  },
})
EOF

  local env_file=/etc/environment
  local marker='# hyprland-gruvbox nvidia'
  if ! sudo grep -qF "${marker}" "${env_file}" 2>/dev/null; then
    sudo tee -a "${env_file}" >/dev/null <<EOF

${marker}
GBM_BACKEND=nvidia-drm
__GLX_VENDOR_LIBRARY_NAME=nvidia
MOZ_ENABLE_WAYLAND=1
ELECTRON_OZONE_PLATFORM_HINT=auto
EOF
  fi

  sudo tee /etc/modprobe.d/nvidia.conf >/dev/null <<'EOF'
options nvidia_drm modeset=1 fbdev=1
EOF

  if [[ -f /etc/mkinitcpio.conf ]] && ! grep -q 'nvidia_drm' /etc/mkinitcpio.conf; then
    sudo sed -i 's/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
    sudo mkinitcpio -P
  fi

  local kparams='nvidia-drm.modeset=1 nvidia-drm.fbdev=1'
  if [[ -d /boot/loader/entries ]]; then
    for entry in /boot/loader/entries/*.conf; do
      [[ -f "${entry}" ]] || continue
      if ! sudo grep -q 'nvidia-drm.modeset' "${entry}"; then
        sudo sed -i "/^options / s|$| ${kparams}|" "${entry}"
      fi
    done
  fi
  if [[ -f /etc/default/grub ]] && ! grep -q 'nvidia-drm.modeset' /etc/default/grub; then
    sudo sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"${kparams} /" /etc/default/grub
    if command -v grub-mkconfig >/dev/null; then
      sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi
  fi

  sudo mkdir -p /etc/firefox/policies
  sudo tee /etc/firefox/policies/policies.json >/dev/null <<'EOF'
{
  "policies": {
    "Preferences": {
      "media.hardware-video-decoding.force-enabled": {
        "Value": true,
        "Status": "user"
      },
      "widget.dmabuf.force-enabled": {
        "Value": true,
        "Status": "user"
      }
    }
  }
}
EOF
}

if has_nvidia_gpu; then
  configure_nvidia
else
  mkdir -p "${CONFIG_DIR}/hypr"
  cat > "${CONFIG_DIR}/hypr/nvidia.lua" <<'EOF'
-- Sem GPU NVIDIA: ficheiro vazio de propósito.
EOF
fi

info "a instalar o tema Field do qylock para o SDDM"
if [[ -f /usr/share/sddm/themes/field/Main.qml ]]; then
  info "tema Field já está instalado; a saltar o download"
else
  git clone --depth 1 https://github.com/Darkkal44/qylock.git "${TMP_DIR}/qylock"
  [[ -d "${TMP_DIR}/qylock/themes/field" ]] || die "tema field não encontrado no qylock"
  sudo mkdir -p /usr/share/sddm/themes
  sudo rm -rf /usr/share/sddm/themes/field
  sudo cp -a "${TMP_DIR}/qylock/themes/field" /usr/share/sddm/themes/field
fi

if [[ -f /usr/share/sddm/themes/field/metadata.desktop ]] \
  && ! grep -q '^QtVersion=' /usr/share/sddm/themes/field/metadata.desktop 2>/dev/null; then
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
    "cache_path": "${HOME_DIR}/.cache/quickshell/hyprquickpaper/",
    "number_of_pictures": 6,
    "cache_batch_size": 20,
    "height": 500,
    "x_factor": -0.25,
    "keep_open": false
}
EOF

cat > "${HQP_DIR}/colors.json" <<'EOF'
{
    "border_color": "#A98881"
}
EOF

cat > "${HQP_DIR}/commands.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
img="${1:-}"
if [[ -z "${img}" || ! -f "${img}" ]]; then
  exit 1
fi
if ! pgrep -x swww-daemon >/dev/null 2>&1; then
  swww-daemon >/dev/null 2>&1 &
  sleep 0.4
fi
swww img "${img}" -t grow --transition-duration 1
EOF
chmod +x "${HQP_DIR}/commands.sh"
mkdir -p "${HOME_DIR}/.cache/quickshell/hyprquickpaper"

info "a activar serviços"
if systemctl list-unit-files ly.service >/dev/null 2>&1; then
  sudo systemctl disable ly.service --now 2>/dev/null || true
fi
sudo systemctl enable NetworkManager.service
sudo systemctl enable sddm.service
sudo systemctl enable --now pipewire.socket pipewire-pulse.socket wireplumber.service 2>/dev/null || true

retry_user_password() {
  local prompt="$1"
  shift
  local attempt=1
  local max=5
  set +e
  while (( attempt <= max )); do
    info "${prompt} (tentativa ${attempt}/${max})"
    if "$@"; then
      set -e
      return 0
    fi
    warn "palavra-passe incorrecta ou comando falhou; tenta outra vez"
    attempt=$((attempt + 1))
  done
  set -e
  die "falhou após ${max} tentativas"
}

ZSH_PATH="$(command -v zsh)"
if [[ "${SHELL}" != "${ZSH_PATH}" ]]; then
  info "a definir zsh como shell por omissão"
  if ! grep -qxF "${ZSH_PATH}" /etc/shells; then
    echo "${ZSH_PATH}" | sudo tee -a /etc/shells >/dev/null
  fi
  retry_user_password "introduz a palavra-passe da tua conta para o chsh" chsh -s "${ZSH_PATH}"
fi

info "instalação concluída"
printf '%s\n' \
  "Reinicia o computador para entrar pelo SDDM (tema Field)." \
  "No Hyprland: Super+W abre o hyprquickpaper; Super+N tira um screenshot."
if has_nvidia_gpu; then
  printf '%s\n' "NVIDIA DRM activo: depois do reboot confirma com: cat /sys/module/nvidia_drm/parameters/modeset (deve ser Y)."
fi
