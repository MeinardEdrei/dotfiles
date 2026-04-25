#!/bin/bash

SCREENSHOT_DIR="$HOME/Pictures/Screenshots/"
# Use double quotes for everything
ACTION="$SWAYNC_ACTION_ID"
FILE="$SWAYNC_NOTIFICATION_HINT_screenshot_path"

case "$ACTION" in
    "open")
        # Check if FILE is not empty and the file exists
        if [[ -n "$FILE" && -f "$FILE" ]]; then
            xdg-open "$FILE"
        else
            # Fallback: Open the newest file if the hint failed
            LATEST=$(ls -t "$SCREENSHOT_DIR"/*.png | head -1)
            if [[ -n "$LATEST" ]]; then
                xdg-open "$LATEST"
            fi
        fi
        ;;
    "folder")
        xdg-open "$SCREENSHOT_DIR"
        ;;
    *)
        # Log error for debugging if needed
        echo "Unknown action: $ACTION" >> /tmp/swaync-error.log
        ;;
esac
