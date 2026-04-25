#!/bin/bash

SCREENSHOT_DIR="$HOME/Pictures/Screenshots/"
mkdir -p "$SCREENSHOT_DIR"

# 1. Record the current time BEFORE the screenshot
START_TIME=$(date +%s)

# 2. Run Niri screenshot
niri msg action screenshot

# 3. Wait briefly for the file to be saved to disk
sleep 0.5

# 4. Find the latest file
LATEST=$(find "$SCREENSHOT_DIR" -name "Screenshot*.png" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)

if [[ -n "$LATEST" && -f "$LATEST" ]]; then
  # 5. Check the file's modification time
  FILE_TIME=$(stat -c %Y "$LATEST")

  # 6. ONLY notify if the file is newer than when we started the script
  if [ "$FILE_TIME" -ge "$START_TIME" ]; then
    notify-send -a "Niri Screenshot" \
      -i "$LATEST" \
      --hint="string:screenshot_path:$LATEST" \
      --action="open=Open" \
      --action="folder=Open Folder" \
      "Screenshot" "Area screenshot saved: $(basename "$LATEST")"
  else
    echo "Screenshot was cancelled (newest file is old)."
  fi
else
  echo "No screenshot files found at all."
fi
