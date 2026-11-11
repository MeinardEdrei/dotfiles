#!/usr/bin/env bash
# backup.sh: back up YOUR data (not the system) to an external drive.
#
#   ./backup/backup.sh                 on a terminal: numbered menu, just type numbers
#   ./backup/backup.sh --dest PATH     back up to PATH without asking where
#   ./backup/backup.sh --dry-run       show what WOULD be copied and how big it is, copy nothing
#   ./backup/backup.sh --list          show existing backups and saved older versions
#   ./backup/backup.sh --verify        compare the last backup with your files
#   ./backup/backup.sh --no-secrets    skip SSH/GPG keys, keyrings and browser profiles
#   ./backup/backup.sh --downloads     also back up ~/Downloads
#   ./backup/backup.sh --no-docker     skip Docker volumes
#   ./backup/backup.sh --docker-only   back up only the Docker volumes
#   ./backup/backup.sh --only PATH     back up just this path under your home (repeatable; for testing)
#
# What is backed up lives in include-*.txt, what is skipped in exclude.txt: edit them freely.
# Packages, caches, node_modules and other reinstallable things are NOT backed up. The package
# list is saved instead, so a reinstall brings the same software back.
# It never uses sudo and never touches system files.
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$HOME/backup.log"
STAMP="$(date +%F-%H%M)"
HOST="$(hostname 2>/dev/null || cat /etc/hostname)"
DRY=0; YES=0; DEST=""; DO_SECRETS=1; DO_DOWNLOADS=0; DO_DOCKER=1; DOCKER_ONLY=0; MODE=backup; ONLY=(); ARGC=$#
FAILED=()

# ---------- helpers ----------
say()  { printf '%s\n' "$*" | tee -a "$LOG"; }
warn() { say "  ! $*"; }
fail() { FAILED+=("$*"); warn "$*"; }

ask_one() {   # ask_one "Question" DEFAULT "option 1" "option 2" ...   -> REPLY_N (1-based)
  local q="$1" def="$2"; shift 2
  local i=1 o ans
  echo; echo "$q"
  for o in "$@"; do printf '  %d) %s\n' "$i" "$o"; i=$((i+1)); done
  while true; do
    read -r -p "Number [$def]: " ans; ans="${ans:-$def}"
    if [[ "$ans" =~ ^[0-9]+$ ]] && ((ans>=1 && ans<=$#)); then REPLY_N=$ans; return; fi
    echo "  please type a number from 1 to $#"
  done
}

human() { numfmt --to=iec --suffix=B "${1:-0}" 2>/dev/null || echo "${1:-0}B"; }

read_list() {   # print non-comment, non-empty lines of a list file
  [[ -f "$1" ]] || return 0
  sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e 's/^[[:space:]]*//' "$1" | grep -v '^$'
}

fs_of()      { findmnt -no FSTYPE -T "$1" 2>/dev/null | head -1; }
dev_of()     { findmnt -no SOURCE -T "$1" 2>/dev/null | head -1 | sed 's/\[.*//'; }
is_posix_fs() { case "$(fs_of "$1")" in ext2|ext3|ext4|btrfs|xfs|f2fs|zfs|bcachefs) return 0;; *) return 1;; esac; }

# ---------- what to back up ----------
build_sources() {   # fills SOURCES[] with existing paths relative to $HOME
  SOURCES=()
  ((DOCKER_ONLY)) && return
  local p
  if ((${#ONLY[@]})); then
    for p in "${ONLY[@]}"; do [[ -e "$HOME/$p" ]] && SOURCES+=("$p") || warn "not found, skipped: $p"; done
    return
  fi
  local lists=("$HERE/include-data.txt")
  ((DO_SECRETS))   && lists+=("$HERE/include-secrets.txt")
  ((DO_DOWNLOADS)) && lists+=("$HERE/include-downloads.txt")
  local f
  for f in "${lists[@]}"; do
    while IFS= read -r p; do [[ -e "$HOME/$p" ]] && SOURCES+=("$p"); done < <(read_list "$f")
  done
}

# ---------- destination ----------
pick_destination() {
  local cands=() labels=() line tgt fs avail
  while IFS= read -r line; do
    tgt="$(echo "$line" | awk '{print $1}')"; fs="$(echo "$line" | awk '{print $2}')"; avail="$(echo "$line" | awk '{print $3}')"
    [[ -w "$tgt" ]] || continue
    cands+=("$tgt"); labels+=("$tgt   [$fs, $(human "$avail") free]")
  done < <(findmnt -rno TARGET,FSTYPE,AVAIL -b 2>/dev/null | grep -E "^(/run/media/$USER|/media/$USER|/mnt)/" )
  labels+=("Type a path myself")
  ask_one "Where should the backup go?" 1 "${labels[@]}"
  if ((REPLY_N<=${#cands[@]})); then DEST="${cands[$((REPLY_N-1))]}"
  else read -r -p "Folder path: " DEST; fi
}

check_destination() {
  [[ -n "$DEST" ]] || { echo "No destination chosen."; exit 1; }
  DEST="${DEST%/}"
  [[ -d "$DEST" && -w "$DEST" ]] || { echo "'$DEST' is not a writable folder."; exit 1; }
  case "$(realpath "$DEST")" in "$(realpath "$HOME")"|"$(realpath "$HOME")"/*) echo "The destination is inside your home folder: that is not a backup."; exit 1;; esac
  if [[ "$(dev_of "$DEST")" == "$(dev_of /)" ]]; then
    warn "This is on the same disk as your system. If the disk dies, the backup dies with it."
    if ! ((YES)) && [[ -t 0 ]]; then ask_one "Continue anyway?" 2 "Yes" "No, cancel"; ((REPLY_N==2)) && exit 0; fi
  fi
  ROOT="$DEST/arch-backup-$HOST"
  if is_posix_fs "$DEST"; then
    POSIX=1; RSYNC_OPTS=(-aHAX)
  else
    POSIX=0; RSYNC_OPTS=(-rtH --no-perms --no-owner --no-group --no-links --modify-window=1)
    warn "The drive is $(fs_of "$DEST"): it cannot store Linux permissions or symlinks. Files are saved,"
    warn "but SSH key permissions are lost (a list is saved so they can be fixed). ext4 or btrfs is better."
    if ! ((YES)) && [[ -t 0 ]]; then ask_one "Continue with this drive?" 1 "Yes" "No, cancel"; ((REPLY_N==2)) && exit 0; fi
  fi
}

# ---------- estimate ----------
declare -A PATH_BYTES
estimate() {   # sets EST_FILES, EST_BYTES and PATH_BYTES[path] for what would be transferred
  local p out f b
  EST_FILES=0; EST_BYTES=0
  for p in "${SOURCES[@]}"; do
    out="$(rsync "${RSYNC_OPTS[@]}" --relative -n --stats --exclude-from="$HERE/exclude.txt" "$HOME/./$p" "$ROOT/current/" 2>/dev/null)"
    f="$(echo "$out" | awk -F': ' '/Number of regular files transferred/{gsub(/[,.]/,"",$2); print $2}')"
    b="$(echo "$out" | awk -F': ' '/Total transferred file size/{split($2,a," "); gsub(/[,.]/,"",a[1]); print a[1]}')"
    PATH_BYTES["$p"]=${b:-0}
    EST_FILES=$((EST_FILES + ${f:-0})); EST_BYTES=$((EST_BYTES + ${b:-0}))
  done
}

print_breakdown() {   # the biggest paths first, so you can see where the space goes
  local p
  say "  biggest parts:"
  for p in "${!PATH_BYTES[@]}"; do echo "${PATH_BYTES[$p]} $p"; done | sort -rn | head -8 | while read -r b p; do
    printf '    %8s  ~/%s\n' "$(human "$b")" "$p" | tee -a "$LOG"
  done
}

# ---------- the backup itself ----------
write_meta() {
  mkdir -p "$ROOT/meta"
  pacman -Qqen > "$ROOT/meta/pkglist-explicit.txt" 2>/dev/null
  pacman -Qqem > "$ROOT/meta/pkglist-aur.txt" 2>/dev/null
  systemctl list-unit-files --state=enabled --no-legend 2>/dev/null | awk '{print $1}' > "$ROOT/meta/services-enabled.txt"
  systemctl --user list-unit-files --state=enabled --no-legend 2>/dev/null | awk '{print $1}' > "$ROOT/meta/services-enabled-user.txt"
  if ((DO_SECRETS)); then
    find "$HOME/.ssh" "$HOME/.gnupg" -printf '%m %u:%g %p\n' 2>/dev/null > "$ROOT/meta/permissions-ssh-gnupg.txt"
  fi
  {
    echo "backup: $STAMP   host: $HOST   user: $USER"
    echo "filesystem: $(fs_of "$DEST") (permissions kept: $([[ $POSIX == 1 ]] && echo yes || echo NO))"
    echo "secrets included: $DO_SECRETS   downloads: $DO_DOWNLOADS   docker volumes: $DO_DOCKER"
    echo "paths: ${SOURCES[*]}"
  } > "$ROOT/meta/backup-info.txt"
  cat > "$ROOT/RESTORE.txt" <<EOF
How to get things back
======================
Your files are in:   $ROOT/current/<path relative to your home>
Older/changed files: $ROOT/changes/<date>/...   (kept when a file was changed or deleted)
Docker volumes:      $ROOT/docker-volumes/<name>.tar.gz
Package lists:       $ROOT/meta/

One folder:   rsync -a "$ROOT/current/Documents/" ~/Documents/
Everything:   rsync -a "$ROOT/current/" ~/
A volume:     docker volume create NAME
              docker run --rm -v NAME:/v -v $ROOT/docker-volumes:/in alpine:3 tar -C /v -xzf /in/NAME.tar.gz
SSH keys, if the drive lost permissions:  chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_*  (see meta/permissions-ssh-gnupg.txt)
EOF
}

backup_docker() {
  command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1 || { say "  Docker not available: volumes skipped"; return; }
  local v n=0 running out="$ROOT/docker-volumes"
  mkdir -p "$out"
  while IFS= read -r v; do
    [[ "$v" =~ ^[0-9a-f]{64}$ ]] && continue          # anonymous leftovers
    running="$(docker ps -q --filter "volume=$v" | wc -l)"
    ((running)) && warn "volume '$v' is used by a running container: the copy may be mid-write (databases recover, but stop them first for a clean copy)"
    say "  volume: $v"
    docker run --rm -v "$v":/v:ro -v "$out":/out alpine:3 sh -c "tar -C /v -czf /out/$v.tar.gz.part . && mv -f /out/$v.tar.gz.part /out/$v.tar.gz" 2>&1 | tail -2 \
      || fail "could not back up Docker volume $v"
    n=$((n+1))
  done < <(docker volume ls -q)
  say "  $n Docker volume(s) archived"
}

do_backup() {
  mkdir -p "$ROOT/current" "$ROOT/changes/$STAMP"
  say "Backing up ${#SOURCES[@]} paths to $ROOT/current ..."
  local p rc
  for p in "${SOURCES[@]}"; do
    say "  -> $p"
    rsync "${RSYNC_OPTS[@]}" --relative --delete --backup --backup-dir="$ROOT/changes/$STAMP" \
      --exclude-from="$HERE/exclude.txt" --human-readable --info=stats1,progress2 \
      "$HOME/./$p" "$ROOT/current/" 2>&1 | grep -vE '^(sending incremental|total size|$)' | tail -4 | tee -a "$LOG" >/dev/null
    rc=${PIPESTATUS[0]}
    case $rc in 0|24) ;; *) fail "rsync exit $rc for $p (some files may not have copied)";; esac
  done
  write_meta
  { ((DO_DOCKER)) && ((${#ONLY[@]}==0)) || ((DOCKER_ONLY)); } && backup_docker
  # remove empty "changes" folder for this run if nothing was replaced/deleted
  rmdir "$ROOT/changes/$STAMP" 2>/dev/null
}

verify() {
  [[ -d "$ROOT/current" ]] || { echo "No backup found at $ROOT"; exit 1; }
  build_sources
  local p n total=0
  say "Comparing your files with the backup (sizes and times; nothing is changed)..."
  for p in "${SOURCES[@]}"; do
    n="$(rsync "${RSYNC_OPTS[@]}" --relative -n --itemize-changes --exclude-from="$HERE/exclude.txt" "$HOME/./$p" "$ROOT/current/" 2>/dev/null | grep -c '^>f')"
    total=$((total + n))
    ((n)) && say "  $p: $n file(s) changed since the backup (new or edited)"
  done
  say "Done: $total file(s) differ from the backup. That is normal if you worked since the last run."
}

list_backups() {
  [[ -d "$ROOT" ]] || { echo "No backup at $ROOT"; exit 1; }
  echo "Backup folder: $ROOT"
  cat "$ROOT/meta/backup-info.txt" 2>/dev/null
  echo "--- older versions kept (changed or deleted files):"
  ls -1 "$ROOT/changes" 2>/dev/null | while read -r d; do printf '  %s  %s\n' "$d" "$(du -sh "$ROOT/changes/$d" 2>/dev/null | cut -f1)"; done
  echo "--- docker volumes:"; ls -1 "$ROOT/docker-volumes" 2>/dev/null | sed 's/^/  /'
}

show_plan() {
  echo "Included:"; build_sources; printf '  ~/%s\n' "${SOURCES[@]}"
  echo "Skipped everywhere (examples): $(read_list "$HERE/exclude.txt" | head -12 | tr '\n' ' ') ..."
  echo "Full lists: $HERE/include-*.txt and exclude.txt"
}

# ---------- menu ----------
run_menu() {
  echo "=== Backup ==="
  ask_one "What do you want to do?" 1 \
    "Back up now" \
    "Preview only (shows the size, copies nothing)" \
    "Verify the last backup" \
    "List backups and saved older versions" \
    "Show what is included and excluded" \
    "Quit"
  case $REPLY_N in
    3) MODE=verify;; 4) MODE=list;; 5) MODE=plan;; 6) echo "Bye."; exit 0;;
    2) DRY=1;;
  esac
  [[ $MODE == plan ]] && return
  pick_destination
  if [[ $MODE == backup ]]; then
    ask_one "Include SSH/GPG keys, keyrings and browser profiles (saved logins)? Keep the drive private if yes." 1 "Yes" "No, skip them"
    ((REPLY_N==2)) && DO_SECRETS=0
    ask_one "Include ~/Downloads?" 2 "Yes" "No (usually installers and temporary files)"
    ((REPLY_N==1)) && DO_DOWNLOADS=1
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
      ask_one "Include your named Docker volumes (database data)?" 1 "Yes" "No"
      ((REPLY_N==2)) && DO_DOCKER=0
    else DO_DOCKER=0; fi
  fi
}

# ---------- arguments ----------
while (($#)); do
  case "$1" in
    --dest)       shift; DEST="${1:-}";;
    --dest=*)     DEST="${1#--dest=}";;
    --dry-run)    DRY=1;;
    --yes|-y)     YES=1;;
    --list)       MODE=list;;
    --verify)     MODE=verify;;
    --no-secrets) DO_SECRETS=0;;
    --downloads)  DO_DOWNLOADS=1;;
    --no-docker)  DO_DOCKER=0;;
    --docker-only) DOCKER_ONLY=1;;
    --only)       shift; ONLY+=("${1:-}");;
    --only=*)     ONLY+=("${1#--only=}");;
    --menu)       ARGC=0;;
    -h|--help)    sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *)            echo "unknown option: $1 (try --help)"; exit 1;;
  esac
  shift
done
command -v rsync >/dev/null 2>&1 || { echo "rsync is required (sudo pacman -S rsync)."; exit 1; }
: > "$LOG"
if ((ARGC==0)) && [[ -t 0 ]]; then run_menu; fi

case "$MODE" in
  plan) show_plan; exit 0;;
esac
[[ -n "$DEST" ]] || { echo "Where should it go? Use --dest PATH, or run without options for the menu."; exit 1; }
check_destination
case "$MODE" in
  list)   list_backups; exit 0;;
  verify) verify; exit 0;;
esac

build_sources
((${#SOURCES[@]})) || ((DOCKER_ONLY)) || { echo "Nothing to back up."; exit 1; }
say "Estimating size (reads file lists only)..."
estimate
FREE="$(df -B1 --output=avail "$DEST" | tail -1 | tr -d ' ')"
say "  ${#SOURCES[@]} paths, about $EST_FILES file(s) to copy, $(human "$EST_BYTES") ($(human "$FREE") free on the drive)"
print_breakdown
if ((EST_BYTES > FREE)); then echo "Not enough free space on the drive."; exit 1; fi
if ((DRY)); then say "Preview only: nothing was copied."; exit 0; fi
if ! ((YES)) && [[ -t 0 ]]; then
  ask_one "Start the backup to $DEST/arch-backup-$HOST ?" 1 "Yes, start" "Cancel"
  ((REPLY_N==2)) && { echo "Cancelled."; exit 0; }
fi

START=$SECONDS
do_backup
say ""
if ((${#FAILED[@]})); then
  say "Finished with problems:"; printf '  - %s\n' "${FAILED[@]}" | tee -a "$LOG"
else
  say "Backup finished without errors in $((SECONDS-START))s."
fi
say "Where: $ROOT   |   How to restore: $ROOT/RESTORE.txt   |   Log: $LOG"
exit 0
