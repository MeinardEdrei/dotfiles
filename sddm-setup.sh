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
    DOTFILES_DIR="/home/$REAL_USER/dotfiles"
fi

SDDM_CONF="/etc/sddm.conf"
PAM_FILE="/etc/pam.d/sddm-fingerprint"

echo "Configuring SDDM for user: $REAL_USER"

# 1. Remove [Fingerprintlogin] from sddm.conf if present
if grep -q "\[Fingerprintlogin\]" "$SDDM_CONF" 2>/dev/null; then
    echo "Removing [Fingerprintlogin] from $SDDM_CONF..."
    sudo sed -i '/\[Fingerprintlogin\]/,/^$/d' "$SDDM_CONF"
fi

# 2. Disable fingerprint in sddm-fingerprint PAM — password only
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
