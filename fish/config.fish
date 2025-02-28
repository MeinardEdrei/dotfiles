if status is-interactive
    # Commands to run in interactive sessions can go here
end

starship init fish | source
set -Ux HYPRSHOT_DIR "$HOME/Pictures/Screenshots"
