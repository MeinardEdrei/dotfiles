#!/bin/bash
set -e

# Define paths
LOG_FILE="$HOME/install_log.txt"
DOTFILES_DIR="$HOME/dotfiles"
NATIVE_LIST="$DOTFILES_DIR/system_config/pkglist-native.txt"
AUR_LIST="$DOTFILES_DIR/system_config/pkglist-aur.txt"

echo "Starting System Restoration..." | tee -a "$LOG_FILE"

# 1. Set up Chaotic-AUR if not already configured
if ! grep -q '\[chaotic-aur\]' /etc/pacman.conf; then
    echo "Setting up Chaotic-AUR..."
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key 3056513887B78AEB
    sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
    sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf
    echo "Chaotic-AUR configured."
else
    echo "Chaotic-AUR already configured, skipping."
fi

# 2. Full system update + keyrings (Arch-safe)
echo "Updating system and keyrings..."
sudo pacman -Syu --noconfirm archlinux-keyring

# 2. Install Native Packages
if [[ -f "$NATIVE_LIST" ]]; then
    echo "Installing Native Packages..."
    grep -vE '^\s*#|^\s*$' "$NATIVE_LIST" |
        sudo pacman -S --needed --noconfirm - || true
else
    echo "Error: Native package list not found at $NATIVE_LIST"
    exit 1
fi

# 3. Ensure yay dependencies
sudo pacman -S --needed --noconfirm git base-devel

# 4. Install yay if missing
if ! command -v yay &>/dev/null; then
    echo "Installing yay..."
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
else
    echo "yay is already installed."
fi

# 5. Install AUR Packages
if [[ -f "$AUR_LIST" ]]; then
    echo "Installing AUR Packages..."
    grep -vE '^\s*#|^\s*$' "$AUR_LIST" |
        yay -S --needed --noconfirm -
else
    echo "Error: AUR package list not found at $AUR_LIST"
fi

# 6. Symlink dotfile configs
echo "Symlinking dotfile configs..."
CONFIG_DIR="$HOME/.config"
mkdir -p "$CONFIG_DIR"

# Map: dotfiles subdirectory -> ~/.config/ target name
declare -A SYMLINKS=(
    ["fish"]="fish"
    ["hypr"]="hypr"
    ["kitty"]="kitty"
    ["nvim"]="nvim"
    ["rofi"]="rofi"
    ["swaync"]="swaync"
    ["tmux"]="tmux"
    ["waybar"]="waybar"
    ["lazygit"]="lazygit"
    ["niri"]="niri"
    ["noctalia"]="noctalia"
)

for src_name in "${!SYMLINKS[@]}"; do
    src="$DOTFILES_DIR/$src_name"
    dest="$CONFIG_DIR/${SYMLINKS[$src_name]}"

    if [[ ! -d "$src" ]]; then
        echo "  Skipping $src_name (not found in dotfiles)"
        continue
    fi

    if [[ -L "$dest" ]]; then
        current_target=$(readlink "$dest")
        if [[ "$current_target" == "$src" ]]; then
            echo "  $src_name already symlinked, skipping"
            continue
        else
            echo "  $src_name symlink points elsewhere ($current_target), relinking..."
            ln -sfn "$src" "$dest"
        fi
    elif [[ -d "$dest" ]]; then
        echo "  WARNING: $dest is a real directory. Backing up to ${dest}.bak and symlinking..."
        mv "$dest" "${dest}.bak"
        ln -s "$src" "$dest"
    else
        echo "  Linking $src_name..."
        ln -s "$src" "$dest"
    fi
done

# Starship config (lives at ~/.config/starship.toml, not a directory)
STARSHIP_SRC="$DOTFILES_DIR/starship.toml"
STARSHIP_DEST="$CONFIG_DIR/starship.toml"
if [[ -f "$STARSHIP_SRC" ]]; then
    if [[ -L "$STARSHIP_DEST" && "$(readlink "$STARSHIP_DEST")" == "$STARSHIP_SRC" ]]; then
        echo "  starship.toml already symlinked, skipping"
    else
        [[ -e "$STARSHIP_DEST" ]] && mv "$STARSHIP_DEST" "${STARSHIP_DEST}.bak"
        ln -s "$STARSHIP_SRC" "$STARSHIP_DEST"
        echo "  Linked starship.toml"
    fi
fi

# 7. Enable essential services (skip unavailable ones)
echo "Enabling System Services..."
SERVICES=(
    bluetooth.service
    docker.service
    NetworkManager.service
    thermald.service
)

for service in "${SERVICES[@]}"; do
    if systemctl list-unit-files "$service" &>/dev/null && systemctl list-unit-files "$service" | grep -q "$service"; then
        sudo systemctl enable --now "$service" && echo "  Enabled $service" || echo "  WARNING: Failed to enable $service"
    else
        echo "  Skipping $service (not available on this system)"
    fi
done

# 8. Systemd system service for tmux save on shutdown
echo "Setting up tmux save service..."
sudo ln -sf "$DOTFILES_DIR/systemd/system/tmux-save.service" /etc/systemd/system/tmux-save.service
sudo systemctl daemon-reload
sudo systemctl enable tmux-save.service
sudo systemctl start tmux-save.service

# 9. Docker permissions
echo "Configuring Docker permissions..."
sudo usermod -aG docker "$USER"

# 10. SDDM setup
if [[ -f "$DOTFILES_DIR/sddm-setup.sh" ]]; then
    echo "Configuring SDDM..."
    bash "$DOTFILES_DIR/sddm-setup.sh"
fi
sudo systemctl enable sddm.service

# 11. GRUB theme setup
echo "Installing GRUB theme..."
GRUB_THEME_SRC="$DOTFILES_DIR/grub/space-isolation"
GRUB_THEME_DEST="/boot/grub/themes/space-isolation"
GRUB_CONFIG="/etc/default/grub"

if [[ -d "$GRUB_THEME_SRC" ]]; then
    sudo mkdir -p "$GRUB_THEME_DEST"
    sudo cp -r "$GRUB_THEME_SRC/." "$GRUB_THEME_DEST"
    if grep -q "^GRUB_THEME=" "$GRUB_CONFIG"; then
        sudo sed -i "s|^GRUB_THEME=.*|GRUB_THEME=$GRUB_THEME_DEST/1920x1080/theme.txt|" "$GRUB_CONFIG"
    else
        echo "GRUB_THEME=$GRUB_THEME_DEST/1920x1080/theme.txt" | sudo tee -a "$GRUB_CONFIG"
    fi
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    echo "GRUB theme installed."
else
    echo "  Skipping GRUB theme (not found in dotfiles)"
fi

# 12. Noctalia lock screen PAM bypass setup
if [[ -f "$DOTFILES_DIR/noctalia-setup.sh" ]]; then
    echo "Configuring Noctalia lock screen..."
    bash "$DOTFILES_DIR/noctalia-setup.sh"
fi

echo "--------------------------------------------------------"
echo "Installation Complete!"
echo "IMPORTANT: Reboot or re-login for Docker group changes."
echo "Welcome back, Meinard 🚀"
echo "--------------------------------------------------------"
