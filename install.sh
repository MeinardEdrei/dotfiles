#!/bin/bash

# Define paths
LOG_FILE="install_log.txt"
DOTFILES_DIR="$HOME/dotfiles-niri"
NATIVE_LIST="$DOTFILES_DIR/system_config/pkglist-native.txt"
AUR_LIST="$DOTFILES_DIR/system_config/pkglist-aur.txt"

echo "Starting System Restoration..." | tee -a "$LOG_FILE"

# 1. Update System & Keyrings (Crucial for fresh installs)
echo "Updating system keyrings..."
sudo pacman -Sy archlinux-keyring --noconfirm

# 2. Install Native Packages
if [ -f "$NATIVE_LIST" ]; then
    echo "Installing Native Packages..."
    # We filter out yay/paru if they accidentally got into the native list to avoid errors
    sudo pacman -S --needed --noconfirm - < "$NATIVE_LIST"
else
    echo "Error: Native package list not found at $NATIVE_LIST"
fi

# 3. Install AUR Helper (yay) if not present
if ! command -v yay &> /dev/null; then
    echo "Installing yay..."
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
else
    echo "yay is already installed."
fi

# 4. Install AUR Packages
if [ -f "$AUR_LIST" ]; then
    echo "Installing AUR Packages..."
    # Remove lines containing 'debug' to avoid installation errors
    yay -S --needed --noconfirm - < "$AUR_LIST"
else
    echo "Error: AUR package list not found at $AUR_LIST"
fi

# 5. Enable System Services (Based on your previous systemctl output)
echo "Enabling System Services..."
SERVICES=(
    "bluetooth.service"
    "docker.service"
    "NetworkManager.service"
    "thermald.service"
)

for service in "${SERVICES[@]}"; do
    echo "Enabling $service..."
    sudo systemctl enable --now "$service"
done

# 6. Add user to Docker group (So you don't need sudo for docker)
echo "Configuring Docker permissions..."
sudo usermod -aG docker $USER

echo "--------------------------------------------------------"
echo "Installation Complete! Welcome Back Meinard. Reboot Now."
echo "--------------------------------------------------------"
