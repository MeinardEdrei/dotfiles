# restore

One command to rebuild your Arch setup after a fresh install.

```bash
cd ~/dotfiles && git pull
./restore/restore.sh
```

Do your normal Arch install first (partitions, btrfs, snapper, bootloader, a user with sudo, internet).
Then clone this repo, run the command above, enter your sudo password once, and wait.
When it finishes, reboot and run `gh auth login`.

## What it does, in order

1. **Updates the system** (`pacman -Syu`), so a stale mirror cannot break the installs.
2. **Installs every package** in `packages.txt`. Unknown names are reported at the end instead of cancelling the rest.
   AUR packages are built one at a time with `yay` (built first if missing).
3. **Restores your app settings** (GTK, Qt, mpv, btop, Dolphin, Cursor settings, `.gitconfig`, ...) from `restore/configs/`.
4. **Links your configs** from this repo into `~/.config`: fish, kitty, nvim, tmux, lazygit, lazydocker, rofi, niri,
   umbriel, noctalia and the wallpapers.
5. **Installs plugins**: tmux plugins (tpm) and nvim plugins (lazy.nvim).
6. **Enables services**: NetworkManager, bluetooth, thermald, power-profiles-daemon, ufw, cups, docker (plus the
   `docker` group), paccache, and your weekly dev-cache-cleanup timer.
7. **Sets up the login screen and keyring unlock**: greetd with noctalia-greeter, and the PAM lines that unlock
   gnome-keyring with your login password. It only touches the login manager if noctalia-greeter is installed.
8. **Prints a summary** of anything that failed.

## Options

| Command | What it does |
|---|---|
| `./restore/restore.sh` | Do everything above, unattended |
| `./restore/restore.sh --dry-run` | Show every command, change nothing. **Run this first if you are unsure** |
| `./restore/restore.sh --ask` | Same, but pacman and yay ask before installing (lets you review AUR builds) |
| `./restore/restore.sh --check` | Which packages are missing, and which installed packages are not in `packages.txt` |
| `./restore/restore.sh --save-configs` | Copy your live app settings **into** the repo, so the next restore has them |

## Keeping things in sync

- **Dotfiles you symlink** (fish, kitty, nvim, tmux, niri, umbriel, noctalia, ...): editing them edits the repo directly.
  Just `git commit` and `git push`.
- **App settings that apps rewrite themselves** (GTK, Kvantum, qt5ct/qt6ct, mpv, btop, Dolphin, ...): these are copies, not symlinks.
  After you change them, run `./restore/restore.sh --save-configs`, then commit.
- **Packages**: add a line to `packages.txt` when you install something you want to keep, and remove it when you drop one.
  `--check` shows what you forgot.

To track another setting, add its path (relative to `~/.config`) to the `TRACKED` list at the top of `restore.sh`.

## What it does not do

- **Partitions, btrfs, snapper, the bootloader.** You set those up during the install; this never touches them.
- **Personal files**: Documents, projects, browser profiles, SSH and GPG keys, Claude and Cursor memories.
  Restore those from your backup separately.
- **Logins**: sign in again to Claude, Cursor, GitHub (`gh auth login`) and similar. No tokens are stored here.
- **OBS Studio settings**: left out on purpose, its config holds a websocket password.

## Safety

- Every system file it edits is copied to `<file>.bak-<date>` first. Replaced app settings keep `<file>.bak-<date>` too.
- A real folder in the way of a symlink is moved to `<name>.bak-<date>`, never deleted.
- It is safe to run again. Anything already done is skipped.
- A log is written to `~/restore.log`.
- Unattended mode installs AUR packages without showing you the build script. Use `--ask` if you want to review them.
- `.gitconfig` (your name and email) is one of the saved settings. Remove it from `TRACKED_HOME` in `restore.sh`
  if the repo is public and you do not want it there.

## Files

```
restore.sh        the script
packages.txt      every package, one per line ("aur:" = AUR). Heavy apps are commented out
configs/          saved app settings (dotconfig/ -> ~/.config, home/ -> ~)
```
