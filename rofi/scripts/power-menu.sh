#!/bin/sh

# Ensure the script is executable
chmod +x ~/.config/rofi/scripts/power-menu.sh

chosen=$(printf "󰐥  Power Off\n   Restart\n  Suspend\n   Hibernate\n󰍃  Log Out\n   Lock" | \
    rofi -dmenu -i -p "" -markup-rows -hide-scrollbar \
    -disable-history -kb-text-clear "" -kb-remove-to-eol "" \
    -kb-remove-word-back "" -kb-remove-word-forward "" \
    -kb-accept-entry "Return" \
    -theme ~/.config/rofi/themes/power-menu.rasi)

case "$chosen" in
    "󰐥  Power Off") systemctl poweroff ;;
    "  Restart") systemctl reboot ;;
    "  Suspend") systemctl suspend && hyprlock ;;
    "  Hibernate") systemctl hibernate ;;
    "󰍃  Log Out") hyprctl dispatch exit ;;
    "  Lock") betterlockscreen -l ;;
    *) exit 1 ;;
esac
