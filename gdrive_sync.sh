#!/bin/bash
set -euo pipefail

# Load config file safely based on script location
CONFIG_FILE="$(dirname "$0")/gdrive_sync.conf"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Function to send desktop notifications, ntfy alerts, and log to stderr
notify_error() {
    local msg="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $msg" >&2
    if command -v notify-send &> /dev/null; then
        notify-send "Google Drive Sync Error" "$msg" --urgency=critical || true
    fi
    if [ -n "${NTFY_TOPIC:-}" ]; then
        curl -s -H "Title: Google Drive Sync Error" -H "Tags: warning" -d "$msg" "https://ntfy.sh/$NTFY_TOPIC" > /dev/null || true
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
    
    local exit_code=0
    mullvad-exclude rclone bisync "$local_path" "$remote_path" \
        --no-cleanup --force --tpslimit 40 --quiet "${extra_args[@]}" || exit_code=$?

    # Capture exit code: 1 (lost baseline), 2 (lock file found), or 7 (fatal error)
    if [ $exit_code -ne 0 ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Sync issue (Exit code $exit_code) for $local_path. Clearing lock and forcing resync from Fedora..."
        
        # Format path names to match rclone's bisync lock filename pattern
        local safe_local safe_remote lock_file
        safe_local=$(echo "$local_path" | tr '/' '_')
        safe_remote=$(echo "$remote_path" | tr ':/' '_')
        lock_file="$HOME/.cache/rclone/bisync/${safe_local}..${safe_remote}.lck"
        
        # Clear stale lock if present
        if [ -f "$lock_file" ]; then
            rm -f "$lock_file"
        fi

        mullvad-exclude rclone bisync "$local_path" "$remote_path" \
            --resync --resync-mode Path1 --no-cleanup --force --tpslimit 40 "${extra_args[@]}"
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

# Print a green success message at the end of the script
GREEN='\033[1;32m' # Bold Green
NC='\033[0m' # No Color
echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] ${GREEN}All sync operations completed successfully!${NC}"
