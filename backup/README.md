# backup

Back up **your data** to an external drive. Not the system, and not anything you can reinstall.

```bash
cd ~/dotfiles
./backup/backup.sh          # on a terminal: a numbered menu, just type numbers
```

The menu asks what to do (back up, preview, verify, list, show what is included), where to put it, and whether to
include secrets, Downloads and Docker volumes. It then shows the estimated size and waits for your OK.
No sudo is used, and system files are never touched.

## What is backed up

Listed in `include-data.txt`, `include-secrets.txt` and `include-downloads.txt` (edit them freely):

- Documents, Desktop projects, Pictures, Videos, Music, and your other project folders
- The dotfiles repo (so commits that are not pushed yet are safe) and `.gitconfig`
- AI memories, sessions and history: `~/.claude`, Cursor chats and plans, Gemini, HyperFrames, Claude desktop sessions
- Shell history, zoxide, nvim sessions, tmux saves
- **Secrets** (skip with `--no-secrets`): `~/.ssh`, `~/.gnupg`, keyrings, Zen / Chrome / Thunderbird profiles
- **Docker volumes**: each named volume becomes one `.tar.gz` (keeps database ownership even on a drive that cannot)
- Package lists (`pacman -Qqen`, `-Qqem`) and the enabled services, so a reinstall gets the same software back

## What is NOT backed up

`exclude.txt`: `node_modules`, `.venv`, `__pycache__`, `.next`, Android/Gradle build output, `.cache`, npm/yarn/pnpm caches,
Rust/Go/nvm toolchains, browser caches and extension code, Docker images, the Android SDK, logs, temp and lock files,
AI-tool leftovers that are not memories. Anonymous (hash-named) Docker volumes are skipped too.

Run `./backup/backup.sh --dry-run --dest PATH` to see the size and the biggest parts before copying anything.

## Where the backup goes and how it is laid out

```
<drive>/arch-backup-<hostname>/
  current/            a mirror of your files (same paths as under your home folder)
  changes/<date>/     the OLD version of any file that was changed or deleted since the last run
  docker-volumes/     one .tar.gz per named volume
  meta/               package lists, enabled services, permission list for ~/.ssh and ~/.gnupg
  RESTORE.txt         how to get things back
```

Runs are incremental: only new and changed files are copied, so the second run is quick. Old versions are
kept under `changes/` instead of being thrown away. Nothing is pruned automatically: delete old `changes/<date>` folders
yourself when you want the space back.

## Choose the right drive

- **Use ext4 or btrfs.** The script keeps permissions, ownership, symlinks and extended attributes there.
- **exFAT, FAT and NTFS drop permissions and symlinks.** The script warns, still saves your files, and writes
  `meta/permissions-ssh-gnupg.txt` so SSH key permissions can be fixed after restoring. Docker volumes are fine
  anywhere, because they are archives.
- **Keep the drive private.** With secrets included, the backup holds SSH keys and saved browser logins.
  An encrypted drive is best. Use `--no-secrets` for a backup you will hand around.
- The script refuses a destination inside your home folder, and warns if it is on the same disk as your system.

## Options

| Option | What it does |
|---|---|
| `--dest PATH` | Back up to PATH without asking |
| `--dry-run` | Show the size and the biggest parts, copy nothing |
| `--verify` | Compare the last backup with your files (sizes and times) |
| `--list` | Show backups and the older versions kept |
| `--no-secrets` | Skip keys, keyrings and browser profiles |
| `--downloads` | Also back up `~/Downloads` |
| `--no-docker` / `--docker-only` | Skip Docker volumes / back up only them |
| `--only PATH` | Back up just that path under your home (repeatable, handy for testing) |
| `--yes` | Do not ask for confirmation |

## Getting things back

`RESTORE.txt` inside the backup has the exact commands. In short:

```bash
rsync -a /path/to/arch-backup-arch/current/Documents/ ~/Documents/     # one folder
rsync -a /path/to/arch-backup-arch/current/ ~/                          # everything
```

For a reinstall, run `restore/restore.sh` first (packages and configs), then restore your files from this backup.

## Not covered

- **The wedding footage and other things outside your home folder.** They are not backed up here. Keep a second copy of anything irreplaceable.
- **A schedule.** Run it by hand, for example weekly. Tell me if you want a timer.
