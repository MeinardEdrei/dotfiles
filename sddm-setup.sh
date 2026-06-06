#!/bin/bash
set -e

# Detect the actual non-root user even if run with sudo
REAL_USER=${SUDO_USER:-$USER}

if [ "$REAL_USER" = "root" ]; then
    echo "Please do not run this script directly as root, or run it via 'sudo' from your normal user."
    exit 1
fi

DOTFILES_DIR="$HOME/dotfiles"
if [ ! -d "$DOTFILES_DIR" ]; then
    # Fallback if $HOME is root (when run via sudo without preserving home env)
    DOTFILES_DIR="/home/$REAL_USER/dotfiles"
fi

THEME_DIR="/usr/share/sddm/themes/silent"
SDDM_CONF="/etc/sddm.conf"

echo "Configuring SDDM fingerprint login for user: $REAL_USER"

# 1. Copy the white fingerprint SVG icon to the theme
if [ -d "$THEME_DIR" ]; then
    echo "Copying fingerprint icon to theme..."
    sudo cp "$DOTFILES_DIR/sddm/fingerprint.svg" "$THEME_DIR/icons/fingerprint.svg"
    sudo chmod 644 "$THEME_DIR/icons/fingerprint.svg"
else
    echo "Warning: Silent SDDM theme not found at $THEME_DIR. Skipping theme asset configuration."
fi

# 2. Adjust fingerprint icon size to 48px in theme config
THEME_CONFIG="$THEME_DIR/configs/default.conf"
if [ -f "$THEME_CONFIG" ]; then
    echo "Setting fingerprint icon size to 48px in theme configs..."
    sudo sed -i 's/icon-size = 32/icon-size = 48/g' "$THEME_CONFIG"
fi

# 3. Add fingerprint user configuration to sddm.conf
if [ -f "$SDDM_CONF" ] || [ ! -e "$SDDM_CONF" ]; then
    echo "Writing configuration to $SDDM_CONF..."
    # Ensure SDDM_CONF exists
    sudo touch "$SDDM_CONF"
    
    # Check if [Fingerprintlogin] section already exists
    if grep -q "\[Fingerprintlogin\]" "$SDDM_CONF" 2>/dev/null; then
        # Section exists, let's update the User key
        sudo sed -i '/\[Fingerprintlogin\]/,/^\[/ s/User=.*/User='"$REAL_USER"'/' "$SDDM_CONF"
    else
        # Section does not exist, append it
        sudo bash -c "echo -e '\n[Fingerprintlogin]\nUser=$REAL_USER' >> $SDDM_CONF"
    fi
fi

echo "SDDM fingerprint setup complete!"
