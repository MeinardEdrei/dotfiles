#!/bin/bash

# Define the target file
PAM_FILE="/etc/pam.d/hyprlock"

# Define the desired PAM content
PAM_CONTENT="#%PAM-1.0

auth      sufficient  pam_fprintd.so
auth      include     system-auth
account   include     system-auth
session   include     system-auth"

echo "Configuring PAM for hyprlock (fingerprint support)..."

# Ensure the directory exists
if [ ! -d "/etc/pam.d" ]; then
    echo "Error: /etc/pam.d directory not found. Are you on a Linux system?"
    exit 1
fi

# Write the content to the file using sudo
echo "$PAM_CONTENT" | sudo tee "$PAM_FILE" > /dev/null

# Check if the write was successful
if [ $? -eq 0 ]; then
    echo "Successfully updated $PAM_FILE"
    echo "Note: Make sure 'fprintd' is installed and your fingerprint is enrolled."
else
    echo "Error: Failed to write to $PAM_FILE."
    exit 1
fi
