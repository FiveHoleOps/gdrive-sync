#!/bin/bash
set -euo pipefail

# Function to send desktop notifications and log to stderr
notify_error() {
    local msg="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $msg" >&2
    if command -v notify-send &> /dev/null; then
        notify-send "Google Drive Sync Error" "$msg" --urgency=critical
    fi
}

# Catch any unhandled script crashes (e.g., if the auto-resync fails)
trap 'notify_error "Script failed unexpectedly on line $LINENO"' ERR

# Ensure required dependencies are installed before continuing
for cmd in rclone mullvad-exclude; do
    if ! command -v "$cmd" &> /dev/null; then
        notify_error "Error: $cmd is required but not installed."
        exit 1
    fi
done

# Function to run bisync with your specific tweaks and auto-resync logic
run_bisync() {
    local local_path="$1"
    local remote_path="$2"
    shift 2
    local extra_args=("$@")

    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Checking sync for $local_path..."
    
    # Attempt normal sync with your original flags
    local exit_code=0
    mullvad-exclude rclone bisync "$local_path" "$remote_path" \
        --no-cleanup --force --tpslimit 40 --quiet "${extra_args[@]}" || exit_code=$?

    # Capture the exit code. If it's 1 (lost baseline) or 7 (fatal error/missing listings), auto-fix it.
    if [ $exit_code -eq 1 ] || [ $exit_code -eq 7 ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Sync state issue (Exit code $exit_code) for $local_path. Forcing resync from Fedora..."
        mullvad-exclude rclone bisync "$local_path" "$remote_path" \
            --resync --resync-mode Path1 --no-cleanup --force --tpslimit 40 "${extra_args[@]}"
    elif [ $exit_code -ne 0 ]; then
        # Catch any other unexpected non-zero rclone errors
        notify_error "Warning: rclone returned exit code $exit_code for $local_path"
    fi
}

# 1. Documents (Preserving your excludes and docx tweaks)
run_bisync "/home/ben/Documents" "googleDrive:Documents" \
    --exclude "/SOS/**" \
    --exclude "/OneDrive/Bitcoin/**" \
    --exclude "**/.git/**" \
    --drive-import-formats "docx,xlsx,pptx"

# 2. Pictures
run_bisync "/home/ben/Pictures" "googleDrive:Pictures"

# 3. Videos (Preserving your 128M chunk size)
run_bisync "/home/ben/Videos" "googleDrive:Videos" --drive-chunk-size "128M"

# 4. Backups (Preserving your 128M chunk size)
run_bisync "/home/ben/Backups" "googleDrive:Backups" --drive-chunk-size "128M"
