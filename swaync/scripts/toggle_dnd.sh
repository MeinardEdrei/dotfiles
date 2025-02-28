
#!/bin/bash

DND_STATUS_FILE="/tmp/dnd_status"

if [ -f "$DND_STATUS_FILE" ]; then
    if [ "$(cat "$DND_STATUS_FILE")" = "enabled" ]; then
        /usr/bin/swaync-client --toggle-dnd
        notify-send "Do Not Disturb Disabled" "You will now receive notifications."
        echo "disabled" > "$DND_STATUS_FILE"
    else
        /usr/bin/swaync-client --toggle-dnd
        notify-send "Do Not Disturb Enabled" "You will not receive notifications."
        echo "enabled" > "$DND_STATUS_FILE"
    fi
else
    echo "enabled" > "$DND_STATUS_FILE"
fi

