# Personal Gruvbox Hyprland Rice Dotfiles

A Gruvbox theme based on other Gruvbox creations to be able to modify and create some good dotfiles (some things are not mine, like Dunst or Waybar). **I created this to remember what I did in the past and it is still in development.**

## Show

![2025-07-03-174432_hyprshot](https://github.com/user-attachments/assets/5f3f2089-5ec7-4b37-b975-0bc7411f2ddb)
![2025-07-03-174506_hyprshot](https://github.com/user-attachments/assets/2cf1ee06-6ded-45de-ab2e-0d1e7bd1fbe0)
![2025-07-03-175657_hyprshot](https://github.com/user-attachments/assets/00542eac-7d2f-4e87-a003-0ff2d23f3678)
![2025-07-03-175737_hyprshot](https://github.com/user-attachments/assets/452e50dc-b388-4d32-8066-822c205ba26f)
![2025-07-03-174700_hyprshot](https://github.com/user-attachments/assets/7b751e05-0fe7-474d-856c-600617046309)

## Install (Arch Linux, profile minimal)

After `archinstall` with the **minimal** profile, as a normal user.

During `archinstall`, **do not** select:

- Desktop / Hyprland / KDE / GNOME (or any other desktop profile)
- A display manager (Ly, GDM, LightDM, SDDM) — this rice installs SDDM afterwards
- PipeWire / extra audio stacks — the installer sets that up
- NVIDIA / proprietary GPU drivers — the installer detects the card after reboot
- Ly anywhere

You still want a normal user in `wheel`, NetworkManager, and `git` so you can clone this repo from the TTY.

```bash
sudo pacman -S --needed git
git clone git@github.com:mora1ss/hyprland-gruvbox.git ~/hyprland-gruvbox
# git clone https://github.com/mora1ss/hyprland-gruvbox.git ~/hyprland-gruvbox
cd ~/hyprland-gruvbox
chmod +x install.sh
./install.sh
```

If SSH is not available yet (typical on a fresh minimal VM), use the HTTPS line instead.

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
- **Session panel** (Quickshell): Arch icon next to the clock, or `Super+F`; MPRIS player plus Suspend / Reboot / Power off / Session (back to SDDM). Super+F again, Super+X or Escape closes it.
- **Settings panel** (Quickshell): `Super+I` — network, display, sound, Bluetooth, power (hypridle screen timeout) and about. Escape, Super+X or Super+I again closes it.
- **Seahorse** and **gnome-keyring**: password/secrets store so Firefox stops asking for `org.freedesktop.secrets`.
- **Ristretto**, **mpv**, **Evince**, **gnome-calculator**: image viewer, video, PDF, calculator (so files do not open in Firefox).
- **btop** and **cmatrix**: system monitor and terminal matrix (`btop`, `cmatrix`).
