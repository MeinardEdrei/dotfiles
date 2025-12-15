if status is-interactive
    # Commands to run in interactive sessions can go here
end

function c
    clear
end

# Auto-start Niri on TTY1
if status is-login
    if test -z "$DISPLAY" -a (tty) = "/dev/tty1"
        # Run Niri, but if it crashes, DO NOT exit the shell
        dbus-run-session niri
    end
end

# set -Ux HYPRSHOT_DIR "$HOME/Pictures/Screenshots"

# Android Sdk
set -e ANDROID_SDK_ROOT
set -x ANDROID_HOME /home/batman/Android/Sdk
set -x PATH $ANDROID_HOME/emulator $ANDROID_HOME/platform-tools $ANDROID_HOME/tools $ANDROID_HOME/tools/bin $PATH

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
