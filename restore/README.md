# restore

One command to rebuild your Arch setup after a fresh install.

```bash
cd ~/dotfiles && git pull
./restore/restore.sh
```

Do your normal Arch install first (partitions, btrfs, snapper, bootloader, a user with sudo, internet).
Then clone this repo and run the command above. On a terminal it opens a **numbered menu**: just type numbers
(Enter accepts the default shown in brackets). It asks what to do (restore, preview, save settings, check packages),
which desktop, which optional package groups, whether to enable services and the login screen, and how installs run,
then shows a summary and waits for your OK. Enter your sudo password once and wait.
When it finishes, reboot and run `gh auth login`.

## What it does, in order

1. **Updates the system** (`pacman -Syu`), so a stale mirror cannot break the installs.
2. **Installs every package** in `packages.txt`. Unknown names are reported at the end instead of cancelling the rest.
   AUR packages are built one at a time with `yay` (built first if missing).
3. **Restores your app settings** (GTK, Qt, mpv, btop, Dolphin, Cursor settings, `.gitconfig`, ...) from `restore/configs/`.
4. **Links your configs** from this repo into `~/.config`: fish, kitty, nvim, tmux, lazygit, lazydocker, rofi, niri,
   umbriel, noctalia and the wallpapers.
5. **Re-applies your Tide prompt settings** from `configs/tide-settings.fish`. Tide stores its choices in fish's
   untracked `fish_variables`, so they are saved as plain `set -U` lines instead.
6. **Installs plugins**: tmux plugins (tpm) and nvim plugins (lazy.nvim).
7. **Enables services**: NetworkManager, bluetooth, thermald, power-profiles-daemon, ufw, cups, docker (plus the
   `docker` group), paccache, and your weekly dev-cache-cleanup timer.
8. **Sets up the login screen and keyring unlock**: greetd with noctalia-greeter, and the PAM lines that unlock
   gnome-keyring with your login password. It only touches the login manager if noctalia-greeter is installed.
9. **Prints a summary** of anything that failed.

## Options (skip the menu)

With no options on a terminal you get the menu. These options do the same thing without asking:

| Command | What it does |
|---|---|
| `./restore/restore.sh` | Do everything above, unattended |
| `./restore/restore.sh --dry-run` | Show every command, change nothing. **Run this first if you are unsure** |
| `./restore/restore.sh --ask` | Same, but pacman and yay ask before installing (lets you review AUR builds) |
| `./restore/restore.sh --groups=apps,dev` | Optional package groups: `apps`, `dev`, `extras`, `btrfs`. Default: all four |
| `./restore/restore.sh --no-services` / `--no-login` | Skip the services step / the login screen and keyring step |
| `./restore/restore.sh --restore` | Do the full restore without showing the menu |
| `./restore/restore.sh --desktop umbriel\|niri\|both` | Which desktop **packages** to install. Default `umbriel`. Both configs are always linked, so you can switch later |
| `./restore/restore.sh --check` | Which packages are missing, and which installed packages are not in `packages.txt` |
| `./restore/restore.sh --save-configs` | Copy your live app settings **into** the repo, so the next restore has them |

## Choosing a desktop

Umbriel is the default. Niri is kept as a backup you can go back to.

```bash
./restore/restore.sh                      # Umbriel only (default)
./restore/restore.sh --desktop niri       # niri only
./restore/restore.sh --desktop both       # install both, pick one at the login screen
```

- **Packages** differ per choice: `packages.txt` has `@only umbriel` and `@only niri` blocks (`@all` ends a block).
  The noctalia shell, greeter and helpers are shared by both.
- **Configs are always linked** (`~/.config/niri`, `~/.config/umbriel`, `~/.config/noctalia`), even for a desktop you did
  not install. They are plain files, and it keeps noctalia's niri theme hook from warning about a missing `config.kdl`.
- **Switching later** needs no settings restore: run `./restore/restore.sh --desktop both` (or `niri`) to add the packages,
  then pick the session at the login screen.
- **tty1 safety:** `fish/config.fish` only auto-starts `niri-session` on tty1 when niri is installed, so with Umbriel alone
  a tty1 login gives a plain shell (a rescue login if the login screen fails).

## Keeping things in sync

- **Dotfiles you symlink** (fish, kitty, nvim, tmux, niri, umbriel, noctalia, ...): editing them edits the repo directly.
  Just `git commit` and `git push`.
- **Tide prompt**: after you run `tide configure` or change a `tide_*` setting, run `./restore/restore.sh --save-configs`
  and commit, otherwise a reinstall brings back the default prompt.
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
