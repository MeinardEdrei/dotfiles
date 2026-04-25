#!/bin/bash
SCREENSHOT_DIR="$HOME/Pictures/Screenshots/"
mkdir -p "$SCREENSHOT_DIR"
START_TIME=$(date +%s)

# Run niri screenshot
niri msg action screenshot-screen
sleep 0.5

# Find the file
LATEST=$(find "$SCREENSHOT_DIR" -name "Screenshot*.png" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)

if [[ -n "$LATEST" && -f "$LATEST" ]]; then
  FILE_TIME=$(stat -c %Y "$LATEST")
  if [ "$FILE_TIME" -ge "$START_TIME" ]; then
    # -a "Niri Screenshot" matches SwayNC config
    # -i "$LATEST" shows the preview
    # --hint is what the 'open' button uses to find the file
    notify-send -a "Niri Screenshot" \
      -i "$LATEST" \
      --hint="string:screenshot_path:$LATEST" \
      --action="open=Open" \
      --action="folder=Open Folder" \
      "Screenshot Saved" "Full screen captured: $(basename "$LATEST")"
  fi
fi
