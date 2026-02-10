if status is-interactive
    # Commands to run in interactive sessions can go here
end

function c
    clear
end

# Sync Wayland/Display variables from tmux into the current shell
if set -q TMUX
    # This pulls the variables from the tmux server environment and sets them in Fish
    set -gx WAYLAND_DISPLAY (tmux show-env | grep ^WAYLAND_DISPLAY | cut -d= -f2)
    set -gx XDG_RUNTIME_DIR (tmux show-env | grep ^XDG_RUNTIME_DIR | cut -d= -f2)
    set -gx DISPLAY (tmux show-env | grep ^DISPLAY | cut -d= -f2)
end

# set -Ux HYPRSHOT_DIR "$HOME/Pictures/Screenshots"

# Java Home (Crucial for Gradle)
set -gx JAVA_HOME /usr/lib/jvm/java-17-openjdk
set -gx PATH $JAVA_HOME/bin $PATH

# Android Sdk
set -e ANDROID_SDK_ROOT
set -gx ANDROID_HOME /home/batman/Android/Sdk

set -gx ANDROID_NDK_HOME $ANDROID_HOME/ndk/27.1.12297006 

# FIX: Move EAS local builds out of /tmp (RAM) and onto /home partition
set -gx EAS_LOCAL_BUILD_WORKING_DIR $HOME/.eas-build-local

set -gx PATH $ANDROID_HOME/emulator $ANDROID_HOME/platform-tools $ANDROID_HOME/tools $ANDROID_HOME/tools/bin $PATH

# Autostart Niri on TTY1 console login only
if status is-login; and test (tty) = /dev/tty1; and test -z "$WAYLAND_DISPLAY"
    exec niri-session -l
end

function fish_user_key_bindings
    # 1. Bind Ctrl+y to accept the autosuggestion
    bind \cy accept-autosuggestion

    # 2. Bind Ctrl+k (Up) and Ctrl+j (Down) for history search
    # removing '-M insert' fixes the issue for standard mode
    bind \ck history-search-backward
    bind \cj history-search-forward
end

# Only load Starship if NOT in a TTY
if test "$TERM" != "linux"
    starship init fish | source
end

# Emulator
function android-run
    emulator -avd Medium_Phone_API_36.0 -gpu swiftshader_indirect -no-skin &
end

function davincify
    mkdir -p converted
    for i in $argv
        ffmpeg -i "$i" -c:v prores_ks -profile:v 3 -c:a pcm_s16le "converted/"(string replace -r '\.mp4$|\.mkv$' '.mov' $i)
    end
end
