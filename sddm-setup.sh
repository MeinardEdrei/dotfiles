#!/bin/bash
set -e

REAL_USER=${SUDO_USER:-$USER}

if [ "$REAL_USER" = "root" ]; then
    echo "Please do not run this script directly as root, or run it via 'sudo' from your normal user."
    exit 1
fi

DOTFILES_DIR="$HOME/dotfiles"
if [ ! -d "$DOTFILES_DIR" ]; then
    DOTFILES_DIR="/home/$REAL_USER/dotfiles"
fi

THEME_NAME="pixel-dusk-city"
THEME_SRC="$DOTFILES_DIR/sddm/theme"
THEME_DEST="/usr/share/sddm/themes/$THEME_NAME"
SDDM_CONF="/etc/sddm.conf"
PAM_FILE="/etc/pam.d/sddm-fingerprint"

echo "Configuring SDDM for user: $REAL_USER"

# 1. Install pixel-dusk-city theme
echo "Installing theme '$THEME_NAME'..."
sudo rm -rf "$THEME_DEST"
sudo cp -r "$THEME_SRC" "$THEME_DEST"
sudo chmod -R 644 "$THEME_DEST"
sudo find "$THEME_DEST" -type d -exec chmod 755 {} +

# 2. Set theme in sddm.conf
echo "Setting active theme..."
if grep -q "^\[Theme\]" "$SDDM_CONF" 2>/dev/null; then
    sudo sed -i 's/^Current=.*/Current='"$THEME_NAME"'/' "$SDDM_CONF"
else
    echo -e "\n[Theme]\nCurrent=$THEME_NAME" | sudo tee -a "$SDDM_CONF" > /dev/null
fi

# 3. Disable virtual keyboard
sudo sed -i 's/^InputMethod=.*/InputMethod=/' "$SDDM_CONF"

# 4. Remove [Fingerprintlogin] if present
if grep -q "\[Fingerprintlogin\]" "$SDDM_CONF" 2>/dev/null; then
    sudo sed -i '/\[Fingerprintlogin\]/,/^$/d' "$SDDM_CONF"
fi

# 5. Password-only PAM
echo "Configuring PAM for password-only login..."
sudo tee "$PAM_FILE" > /dev/null << 'EOF'
#%PAM-1.0

auth        required    pam_env.so
auth        required    pam_faillock.so preauth
auth        required    pam_shells.so
auth        required    pam_nologin.so
auth        sufficient  pam_unix.so nullok
auth        required    pam_deny.so
-auth       optional    pam_gnome_keyring.so
-auth       optional    pam_kwallet5.so

account     include     system-local-login
password    include     system-local-login
session     include     system-local-login

-session    optional    pam_gnome_keyring.so auto_start
-session    optional    pam_kwallet5.so auto_start
EOF

echo "SDDM setup complete!"
