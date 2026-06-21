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

# 3. Full system update + keyrings (Arch-safe)
echo "Updating system and keyrings..."
sudo pacman -Syu --noconfirm archlinux-keyring

# 4. Install Native Packages
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
    FINGERPRINT_HW=false
    if lsusb 2>/dev/null | grep -qi "fingerprint" || lspci 2>/dev/null | grep -qi "fingerprint"; then
        FINGERPRINT_HW=true
    fi
    AUR_FILTER='^\s*#|^\s*$'
    if ! $FINGERPRINT_HW; then
        echo "  No fingerprint scanner detected, skipping sddm-fingerprint..."
        AUR_FILTER="$AUR_FILTER|sddm-fingerprint"
    fi
    grep -vE "$AUR_FILTER" "$AUR_LIST" | yay -S --needed --noconfirm -
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

# 10. Ensure niri is registered as a wayland session
echo "Registering niri session..."
NIRI_DESKTOP="/usr/share/wayland-sessions/niri.desktop"
if [[ ! -f "$NIRI_DESKTOP" ]]; then
    sudo mkdir -p /usr/share/wayland-sessions
    sudo tee "$NIRI_DESKTOP" > /dev/null << 'EOF'
[Desktop Entry]
Name=Niri
Comment=A scrollable-tiling Wayland compositor
Exec=niri-session
Type=Application
DesktopNames=niri
EOF
    echo "  niri session registered."
else
    echo "  niri session already registered, skipping."
fi

# Set niri as the default SDDM session
SDDM_CONF="/etc/sddm.conf"
if [[ ! -f "$SDDM_CONF" ]]; then
    sudo tee "$SDDM_CONF" > /dev/null << 'EOF'
[General]
Session=niri
InputMethod=
EOF
    echo "  Created sddm.conf with niri session."
elif grep -q "^Session=" "$SDDM_CONF"; then
    sudo sed -i 's/^Session=.*/Session=niri/' "$SDDM_CONF"
elif grep -q "^\[General\]" "$SDDM_CONF"; then
    sudo sed -i '/^\[General\]/a Session=niri' "$SDDM_CONF"
else
    echo -e "\n[General]\nSession=niri" | sudo tee -a "$SDDM_CONF" > /dev/null
fi

# 12. SDDM setup
HAS_FINGERPRINT=false
if lsusb 2>/dev/null | grep -qi "fingerprint" || lspci 2>/dev/null | grep -qi "fingerprint"; then
    HAS_FINGERPRINT=true
elif command -v fprintd-list &>/dev/null && fprintd-list "$USER" 2>/dev/null | grep -qv "no enrolled"; then
    HAS_FINGERPRINT=true
fi

if [[ -f "$DOTFILES_DIR/sddm-setup.sh" ]]; then
    echo "Configuring SDDM..."
    if $HAS_FINGERPRINT; then
        echo "  Fingerprint scanner detected, enabling fingerprint login..."
        bash "$DOTFILES_DIR/sddm-setup.sh"
    else
        echo "  No fingerprint scanner detected, skipping fingerprint PAM setup..."
        # Still install theme and basic sddm config without fingerprint
        THEME_NAME="pixel-dusk-city"
        THEME_SRC="$DOTFILES_DIR/sddm/theme"
        THEME_DEST="/usr/share/sddm/themes/$THEME_NAME"
        sudo rm -rf "$THEME_DEST"
        sudo cp -r "$THEME_SRC" "$THEME_DEST"
        sudo chmod -R 644 "$THEME_DEST"
        sudo find "$THEME_DEST" -type d -exec chmod 755 {} +
        if grep -q "^\[Theme\]" /etc/sddm.conf 2>/dev/null; then
            sudo sed -i "s/^Current=.*/Current=$THEME_NAME/" /etc/sddm.conf
        else
            echo -e "\n[Theme]\nCurrent=$THEME_NAME" | sudo tee -a /etc/sddm.conf > /dev/null
        fi
    fi
fi

# Skip installing sddm-fingerprint package if no scanner
if ! $HAS_FINGERPRINT; then
    echo "  Skipping sddm-fingerprint package (no fingerprint scanner)"
fi

sudo systemctl enable sddm.service

# 13. GRUB theme setup
echo "Installing GRUB theme..."
GRUB_THEME_SRC="$DOTFILES_DIR/grub/space-isolation"
GRUB_THEME_DEST="/boot/grub/themes/space-isolation"
GRUB_CONFIG="/etc/default/grub"

if [[ -d "$GRUB_THEME_SRC" ]]; then
    sudo mkdir -p "$GRUB_THEME_DEST"
    sudo cp -r "$GRUB_THEME_SRC/." "$GRUB_THEME_DEST"

    # Pick resolution folder — fall back to first available theme.txt
    if [[ -d "$GRUB_THEME_DEST/1920x1080" ]]; then
        THEME_FILE="$GRUB_THEME_DEST/1920x1080/theme.txt"
    else
        THEME_FILE=$(find "$GRUB_THEME_DEST" -name "theme.txt" | sort | head -1)
    fi

    # Remove commented or existing GRUB_THEME line and set the new one
    sudo sed -i '/^#\?GRUB_THEME=/d' "$GRUB_CONFIG"
    echo "GRUB_THEME=$THEME_FILE" | sudo tee -a "$GRUB_CONFIG" > /dev/null
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    echo "GRUB theme installed ($THEME_FILE)."
else
    echo "  Skipping GRUB theme (not found in dotfiles)"
fi

# 14. Noctalia lock screen PAM bypass setup (fingerprint only)
if $HAS_FINGERPRINT; then
    if [[ -f "$DOTFILES_DIR/noctalia-setup.sh" ]]; then
        echo "Configuring Noctalia lock screen..."
        bash "$DOTFILES_DIR/noctalia-setup.sh"
    fi
else
    echo "Skipping Noctalia PAM setup (no fingerprint scanner)"
fi

echo "--------------------------------------------------------"
echo "Installation Complete!"
echo "IMPORTANT: Reboot or re-login for Docker group changes."
echo "Welcome back, Meinard 🚀"
echo "--------------------------------------------------------"
