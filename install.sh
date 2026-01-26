#!/bin/bash
set -e

# Define paths
LOG_FILE="$HOME/install_log.txt"
DOTFILES_DIR="$HOME/dotfiles"
NATIVE_LIST="$DOTFILES_DIR/system_config/pkglist-native.txt"
AUR_LIST="$DOTFILES_DIR/system_config/pkglist-aur.txt"

echo "Starting System Restoration..." | tee -a "$LOG_FILE"

# 1. Full system update + keyrings (Arch-safe)
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

# 6. Enable essential services
echo "Enabling System Services..."
SERVICES=(
    bluetooth.service
    docker.service
    NetworkManager.service
    thermald.service
)

for service in "${SERVICES[@]}"; do
    sudo systemctl enable --now "$service"
done

# 7. Docker permissions
echo "Configuring Docker permissions..."
sudo usermod -aG docker "$USER"

echo "--------------------------------------------------------"
echo "Installation Complete!"
echo "IMPORTANT: Reboot or re-login for Docker group changes."
echo "Welcome back, Meinard 🚀"
echo "--------------------------------------------------------"
