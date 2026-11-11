#!/usr/bin/env bash
# restore.sh: one command to rebuild your Arch setup after a fresh install.
#
#   cd ~/dotfiles && git pull
#   ./restore/restore.sh               do everything below
#   ./restore/restore.sh --dry-run     show what it WOULD do, change nothing
#   ./restore/restore.sh --save-configs   copy your live app settings INTO the repo (then you commit)
#   ./restore/restore.sh --check       packages missing / installed but not in packages.txt
#   ./restore/restore.sh --ask         same as default, but pacman/yay ask before installing
#
# It does NOT touch partitions, btrfs/snapper, the bootloader or your personal files.
# It is safe to run again: nothing is overwritten without a .bak-<date> copy.
set -u

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HERE="$DOTFILES/restore"
LOG="$HOME/restore.log"
STAMP="$(date +%F-%H%M)"
CONFIG="$HOME/.config"
DRY=0; ASK=0; MODE=restore
FAILED=()

for a in "$@"; do
  case "$a" in
    --dry-run)       DRY=1;;
    --ask)           ASK=1;;
    --save-configs)  MODE=save;;
    --check)         MODE=check;;
    -h|--help)       sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *)               echo "unknown option: $a (try --help)"; exit 1;;
  esac
done
NOCONFIRM="--noconfirm"; ((ASK)) && NOCONFIRM=""

# ---------- helpers ----------
say()    { printf '%s\n' "$*" | tee -a "$LOG"; }
step()   { say ""; say "==> $*"; }
warn()   { say "  ! $*"; }
fail()   { FAILED+=("$*"); warn "$*"; }
run()    { if ((DRY)); then say "  [dry-run] $*"; else say "  \$ $*"; "$@"; fi; }
run_sh() { if ((DRY)); then say "  [dry-run] $1"; else say "  \$ $1"; bash -c "$1"; fi; }

# ---------- tracked app settings: live ~/.config  <->  restore/configs ----------
# Small settings files that apps rewrite themselves, so they are copied, not symlinked.
# (No secrets here: OBS is excluded on purpose because its websocket password lives in its config.)
TRACKED=(gtk-3.0 gtk-4.0 Kvantum qt5ct qt6ct nwg-look nwg-displays mpv easyeffects environment.d
         xsettingsd xdg-desktop-portal btop dolphinrc kdeglobals kdedefaults mimeapps.list
         user-dirs.dirs user-dirs.locale pavucontrol.ini qalculate Cursor/User/settings.json
         Cursor/User/snippets)
TRACKED_HOME=(.gitconfig)
RSYNC_X=(--exclude='*.log' --exclude='Cache' --exclude='cache' --exclude='*.lock' --exclude='*.bak' --exclude='dank-colors.css' --exclude='90-dms.conf' --exclude='noctalia.theme')

save_configs() {
  step "Saving live settings into the repo (restore/configs)"
  local p dest
  for p in "${TRACKED[@]}"; do
    [[ -e "$CONFIG/$p" ]] || continue
    dest="$HERE/configs/dotconfig/$p"
    run mkdir -p "$(dirname "$dest")"
    if [[ -d "$CONFIG/$p" ]]; then run rsync -rt "${RSYNC_X[@]}" "$CONFIG/$p/" "$dest/"
    else run rsync -t "$CONFIG/$p" "$dest"; fi
  done
  for p in "${TRACKED_HOME[@]}"; do
    [[ -e "$HOME/$p" ]] || continue
    run mkdir -p "$HERE/configs/home"
    run rsync -t "$HOME/$p" "$HERE/configs/home/$p"
  done
  say "  Done. Review and commit:  cd $DOTFILES && git status && git diff restore/configs"
  say "  (.gitconfig holds your name and email: keep it out of a public repo if you do not want them shown)"
}

restore_configs() {
  step "Restoring app settings from restore/configs"
  local p src dest
  for p in "${TRACKED[@]}"; do
    src="$HERE/configs/dotconfig/$p"; dest="$CONFIG/$p"
    [[ -e "$src" ]] || continue
    run mkdir -p "$(dirname "$dest")"
    if [[ -d "$src" ]]; then
      # merge into the live folder; any file that gets replaced is kept as <file>.bak-<date>
      run rsync -rt --backup --suffix=".bak-$STAMP" "$src/" "$dest/"
    else
      if [[ -e "$dest" ]] && cmp -s "$src" "$dest"; then continue; fi
      [[ -e "$dest" ]] && run mv "$dest" "$dest.bak-$STAMP"
      run cp -a "$src" "$dest"
    fi
  done
  for p in "${TRACKED_HOME[@]}"; do
    src="$HERE/configs/home/$p"; dest="$HOME/$p"
    [[ -e "$src" ]] || continue
    if [[ -e "$dest" ]] && cmp -s "$src" "$dest"; then continue; fi
    [[ -e "$dest" ]] && run mv "$dest" "$dest.bak-$STAMP"
    run cp -a "$src" "$dest"
  done
}

# ---------- packages ----------
read_packages() {   # prints "native name" or "aur name" lines
  local line
  while IFS= read -r line; do
    line="${line%%#*}"; line="$(echo "$line" | xargs)"; [[ -z "$line" ]] && continue
    if [[ "$line" == aur:* ]]; then echo "aur ${line#aur:}"; else echo "native $line"; fi
  done < "$HERE/packages.txt"
}

ensure_yay() {
  command -v yay >/dev/null 2>&1 && return 0
  step "Building yay (AUR helper)"
  run sudo pacman -S --needed $NOCONFIRM git base-devel
  if ((DRY)); then say "  [dry-run] git clone https://aur.archlinux.org/yay.git && makepkg -si"; return 0; fi
  local tmp; tmp="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay.git "$tmp/yay" && (cd "$tmp/yay" && makepkg -si $NOCONFIRM) \
    || { fail "could not build yay: AUR packages skipped"; rm -rf "$tmp"; return 1; }
  rm -rf "$tmp"
}

install_packages() {
  step "Installing packages from packages.txt"
  local kind name todo=() aur=() missing=() have=0
  while read -r kind name; do
    if pacman -Q "$name" >/dev/null 2>&1; then have=$((have+1)); continue; fi
    if [[ $kind == native ]]; then
      if pacman -Si "$name" >/dev/null 2>&1; then todo+=("$name"); else missing+=("$name"); fi
    else aur+=("$name"); fi
  done < <(read_packages)
  say "  already installed: $have   to install (repo): ${#todo[@]}   to build (AUR): ${#aur[@]}"
  ((${#missing[@]})) && fail "not in your enabled repos, skipped: ${missing[*]}"
  if ((${#todo[@]})); then
    run sudo pacman -S --needed $NOCONFIRM "${todo[@]}" || fail "pacman reported errors (see above)"
  fi
  if ((${#aur[@]})); then
    if ensure_yay; then
      local p
      for p in "${aur[@]}"; do run yay -S --needed $NOCONFIRM "$p" || fail "AUR build failed: $p"; done
    fi
  fi
}

check_packages() {
  step "Package check"
  local kind name wanted=() missing=()
  while read -r kind name; do wanted+=("$name"); pacman -Q "$name" >/dev/null 2>&1 || missing+=("$name"); done < <(read_packages)
  say "  in packages.txt but NOT installed: ${missing[*]:-none}"
  say "  installed on purpose but NOT in packages.txt:"
  comm -23 <(pacman -Qqe | sort -u) <(printf '%s\n' "${wanted[@]}" | sort -u) | sed 's/^/    - /' | tee -a "$LOG"
  say "  orphans: $(pacman -Qdtq 2>/dev/null | tr '\n' ' ')"
}

# ---------- config symlinks (repo -> ~/.config) ----------
link_path() {   # link_path SRC DEST
  local src="$1" dest="$2"
  [[ -e "$src" ]] || { warn "not in repo, skipped: $(basename "$src")"; return; }
  if [[ -L "$dest" ]]; then
    [[ "$(readlink "$dest")" == "$src" ]] && return
    run ln -sfn "$src" "$dest"
  elif [[ -e "$dest" ]]; then
    run mv "$dest" "$dest.bak-$STAMP"; run ln -s "$src" "$dest"
  else
    run mkdir -p "$(dirname "$dest")"; run ln -s "$src" "$dest"
  fi
}
placeholder() {   # files noctalia generates at runtime but kitty/niri include unconditionally
  [[ -f "$1" ]] && return
  say "  placeholder: $1"
  ((DRY)) || { mkdir -p "$(dirname "$1")"; printf '%s\n' "$2" > "$1"; }
}

link_dotfiles() {
  step "Linking your configs into ~/.config"
  local n
  placeholder "$DOTFILES/kitty/themes/noctalia.conf" "# placeholder, overwritten by noctalia theme sync"
  placeholder "$DOTFILES/niri/noctalia.kdl" "layout {}"
  for n in fish kitty nvim tmux lazygit lazydocker rofi niri; do link_path "$DOTFILES/$n" "$CONFIG/$n"; done
  # umbriel and noctalia write generated files next to their config, so link file by file
  run mkdir -p "$CONFIG/umbriel" "$CONFIG/noctalia"
  link_path "$DOTFILES/umbriel/config.toml"   "$CONFIG/umbriel/config.toml"
  link_path "$DOTFILES/umbriel/look.toml"     "$CONFIG/umbriel/look.toml"
  link_path "$DOTFILES/noctalia/config.toml"  "$CONFIG/noctalia/config.toml"
  link_path "$DOTFILES/noctalia/settings.toml" "$CONFIG/noctalia/settings.toml"
  link_path "$DOTFILES/wallpapers" "$HOME/Pictures/Wallpapers"
}

# ---------- plugins ----------
install_plugins() {
  step "tmux and nvim plugins"
  local tpm="$DOTFILES/tmux/plugins/tpm"
  if [[ ! -d "$tpm" ]]; then run git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm" || fail "could not clone tpm"; fi
  if [[ -x "$tpm/bin/install_plugins" ]] || ((DRY)); then
    run_sh "TMUX_PLUGIN_MANAGER_PATH='$DOTFILES/tmux/plugins/' '$tpm/bin/install_plugins' || true"
  fi
  if command -v nvim >/dev/null 2>&1; then
    run_sh "timeout 900 nvim --headless '+Lazy! sync' +qa || true"
  fi
}

# ---------- services ----------
enable_services() {
  step "Enabling services"
  local u
  for u in NetworkManager.service bluetooth.service thermald.service power-profiles-daemon.service \
           ufw.service cups.service paccache.timer docker.service; do
    if systemctl cat "$u" >/dev/null 2>&1; then run sudo systemctl enable --now "$u" || fail "could not enable $u"
    else say "  skip $u (not installed)"; fi
  done
  if getent group docker >/dev/null 2>&1; then run sudo usermod -aG docker "$USER"; fi
  # your weekly dev-tool cache cleanup (user timer, no sudo)
  if [[ -f "$DOTFILES/systemd/user/dev-cache-cleanup.timer" ]]; then
    run mkdir -p "$CONFIG/systemd/user"
    run ln -sf "$DOTFILES/systemd/user/dev-cache-cleanup.service" "$CONFIG/systemd/user/dev-cache-cleanup.service"
    run ln -sf "$DOTFILES/systemd/user/dev-cache-cleanup.timer" "$CONFIG/systemd/user/dev-cache-cleanup.timer"
    run systemctl --user daemon-reload
    run systemctl --user enable --now dev-cache-cleanup.timer || fail "could not enable dev-cache-cleanup.timer"
  fi
  # keep debug packages from being built for every AUR package
  if grep -qE '^OPTIONS=.* debug ' /etc/makepkg.conf 2>/dev/null; then
    run sudo cp /etc/makepkg.conf "/etc/makepkg.conf.bak-$STAMP"
    run sudo sed -i -E '/^OPTIONS=/ s/ debug / !debug /' /etc/makepkg.conf
  fi
}

# ---------- login screen + keyring unlock ----------
setup_login() {
  step "Login screen (greetd + noctalia-greeter) and keyring unlock"
  if [[ ! -x /usr/bin/noctalia-greeter-session ]] && ! ((DRY)); then
    fail "noctalia-greeter is not installed: login screen NOT changed (tty login still works)"; return
  fi
  local conf=$'[terminal]\nvt = 1\n\n[default_session]\ncommand = "/usr/bin/noctalia-greeter-session"\nuser = "greeter"\n'
  if ! { [[ -f /etc/greetd/config.toml ]] && grep -q noctalia-greeter-session /etc/greetd/config.toml; }; then
    [[ -f /etc/greetd/config.toml ]] && run sudo cp /etc/greetd/config.toml "/etc/greetd/config.toml.bak-$STAMP"
    run_sh "printf '%s' '$conf' | sudo tee /etc/greetd/config.toml >/dev/null"
  fi
  if ! grep -q pam_gnome_keyring /etc/pam.d/greetd 2>/dev/null; then
    [[ -f /etc/pam.d/greetd ]] && run sudo cp /etc/pam.d/greetd "/etc/pam.d/greetd.bak-$STAMP"
    local pam=$'#%PAM-1.0\n\nauth       required     pam_securetty.so\nauth       requisite    pam_nologin.so\nauth       include      system-local-login\n-auth      optional     pam_gnome_keyring.so\naccount    include      system-local-login\nsession    include      system-local-login\nsession    required     pam_systemd.so\n-session   optional     pam_gnome_keyring.so auto_start\n'
    run_sh "printf '%s' '$pam' | sudo tee /etc/pam.d/greetd >/dev/null"
  fi
  if ! grep -q pam_gnome_keyring /etc/pam.d/login 2>/dev/null; then
    run sudo cp /etc/pam.d/login "/etc/pam.d/login.bak-$STAMP"
    run_sh "sudo sed -i '/^auth .*system-local-login/a -auth       optional     pam_gnome_keyring.so' /etc/pam.d/login"
    run_sh "echo '-session    optional     pam_gnome_keyring.so auto_start' | sudo tee -a /etc/pam.d/login >/dev/null"
  fi
  systemctl is-enabled sddm.service >/dev/null 2>&1 && run sudo systemctl disable sddm.service
  run sudo systemctl enable greetd.service
}

# ---------- main ----------
: > "$LOG"
case "$MODE" in
  save)  save_configs; exit 0;;
  check) check_packages; exit 0;;
esac

say "restore.sh  dry-run=$DRY  unattended=$((1-ASK))   log: $LOG"
((DRY)) && say "DRY RUN: nothing below is executed."
if ! ((DRY)); then
  [[ $EUID -ne 0 ]] || { echo "Run as your normal user, not root."; exit 1; }
  sudo -v || { echo "sudo is required."; exit 1; }
  ( while kill -0 "$$" 2>/dev/null; do sudo -n true; sleep 50; done ) &   # keep sudo alive
  curl -fsI --max-time 8 https://archlinux.org >/dev/null 2>&1 || { echo "No internet connection."; exit 1; }
fi

step "Updating the system"
run sudo pacman -Syu $NOCONFIRM || fail "system update reported errors"
install_packages
restore_configs
link_dotfiles
install_plugins
enable_services
setup_login

step "Summary"
if ((${#FAILED[@]})); then
  say "  Things that need your attention:"
  printf '    - %s\n' "${FAILED[@]}" | tee -a "$LOG"
else
  say "  Everything finished without errors."
fi
say ""
say "  Next: reboot (login screen, keyring and microcode take effect), then run:  gh auth login"
say "  Your personal files, browser profiles and keys are not part of this script: restore them from your backup."
exit 0
