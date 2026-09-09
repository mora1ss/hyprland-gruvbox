# Personal Gruvbox Hyprland Rice Dotfiles

A Gruvbox theme based on other Gruvbox creations to be able to modify and create some good dotfiles (some things are not mine, like Dunst or Waybar). **I created this to remember what I did in the past and it is still in development.**

## Show

![2025-07-03-174432_hyprshot](https://github.com/user-attachments/assets/5f3f2089-5ec7-4b37-b975-0bc7411f2ddb)
![2025-07-03-174506_hyprshot](https://github.com/user-attachments/assets/2cf1ee06-6ded-45de-ab2e-0d1e7bd1fbe0)
![2025-07-03-175657_hyprshot](https://github.com/user-attachments/assets/00542eac-7d2f-4e87-a003-0ff2d23f3678)
![2025-07-03-175737_hyprshot](https://github.com/user-attachments/assets/452e50dc-b388-4d32-8066-822c205ba26f)
![2025-07-03-174700_hyprshot](https://github.com/user-attachments/assets/7b751e05-0fe7-474d-856c-600617046309)

## Install (Arch Linux, profile minimal)

After `archinstall` with the **minimal** profile, as a normal user:

```bash
sudo pacman -S --needed git
git clone <your-repo-url> ~/hyprland-gruvbox
cd ~/hyprland-gruvbox
chmod +x install.sh
./install.sh
```

Then reboot. SDDM starts with the [qylock](https://github.com/Darkkal44/qylock) **Field** theme. Log into **Hyprland**.

The installer:

- installs official packages with `pacman` and AUR packages with `yay` (builds `yay` if missing)
- installs Oh My Zsh plus `zsh-autosuggestions` and `zsh-syntax-highlighting`
- copies configs from `.config` into `~/.config` (GTK into `gtk-3.0` / `gtk-4.0`, not a `GTK/` folder)
- copies `wallpaper/rockman.png` to `~/Imagens/Wallpapers/`
- configures SDDM (not Ly) with qylock Field
- clones [hyprquickpaper](https://github.com/iamsurjog/hyprquickpaper) to `~/.config/quickshell/hyprquickpaper`
- enables `sddm` and `NetworkManager`

Existing files are renamed with a `.bak.<timestamp>` suffix before overwrite.

If an NVIDIA GPU is present (for example an RTX 3060), the installer also sets DRM/KMS, VA-API (`libva-nvidia-driver`), `/etc/environment`, Firefox `about:config` policies, and Chromium/Electron Wayland flags. On a VM without NVIDIA those steps are skipped so the session does not go black.

The modifier key is **Super** (Windows). Hyprquickpaper is Super+W.

### Official packages

hyprland, xdg-desktop-portal-hyprland, xdg-desktop-portal-gtk, qt5-wayland, qt6-wayland, qt5ct, kitty, waybar, dunst, rofi-wayland, neovim, fastfetch, thunar, thunar-archive-plugin, gvfs, firefox, hyprshot, swww, brightnessctl, playerctl, pavucontrol, networkmanager, pipewire, pipewire-pulse, wireplumber, sddm, qt6-declarative, qt6-5compat, qt6-svg, qt6-multimedia, qt6-multimedia-ffmpeg, gst-plugins-base, gst-plugins-good, gst-plugins-bad, gst-plugins-ugly, fzf, zsh, git, base-devel, nwg-look, gedit, ark, papirus-icon-theme, ttf-firacode-nerd, ttf-jetbrains-mono-nerd, ttf-nerd-fonts-symbols, adwaita-fonts, noto-fonts, noto-fonts-emoji, alacritty, polkit-kde-agent, imagemagick, jq, code, grim, slurp, wl-clipboard, pciutils, ffmpeg

NVIDIA (only if a card is detected): nvidia-open, nvidia-utils, nvidia-settings, libva, libva-nvidia-driver, egl-wayland, matching kernel headers

### AUR packages

quickshell, gruvbox-dark-gtk

## What is included?

- [**Dunst**](https://github.com/dunst-project/dunst): Lightweight notification daemon for Linux.
- [**Fastfetch**](https://github.com/fastfetch-cli/fastfetch): Fast tool to display system info in the terminal.
- [**Hyprland**](https://github.com/hyprwm/Hyprland): Dynamic window manager/compositor for Wayland.
- [**Kitty**](https://github.com/kovidgoyal/kitty): GPU-accelerated terminal emulator.
- [**Nvim**](https://github.com/neovim/neovim): Modern Vim-based text editor.
- [**Rofi**](https://github.com/davatorium/rofi): Application launcher.
- [**Waybar**](https://github.com/Alexays/Waybar): Status bar for Wayland.
- [**Zsh**](https://github.com/zsh-users/zsh) and [**Oh My Zsh!**](https://github.com/ohmyzsh/ohmyzsh): Shell and plugin framework.
- [**Thunar**](https://github.com/xfce-mirror/thunar): File manager.
- [**Yay**](https://github.com/Jguer/yay): AUR helper.
- [**Nwg-look**](https://github.com/nwg-piotr/nwg-look): GTK theme GUI.
- [**Gedit**](https://gedit-text-editor.org/) and [**Ark**](https://github.com/KDE/ark): editor and archive manager.
- [**SDDM**](https://github.com/sddm/sddm) with [**qylock Field**](https://github.com/Darkkal44/qylock): display manager (replaces Ly).
- [**hyprquickpaper**](https://github.com/iamsurjog/hyprquickpaper): wallpaper picker (`Super+W`).
