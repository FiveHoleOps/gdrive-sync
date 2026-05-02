#!/bin/bash

# Function to run bisync with your specific tweaks and auto-resync logic
run_bisync() {
    local local_path=$1
    local remote_path=$2
    local extra_args=$3

    echo "Checking sync for $local_path..."
    
    # Attempt normal sync with your original flags
    mullvad-exclude rclone bisync "$local_path" "$remote_path" \
        --no-cleanup --force --tpslimit 40 --quiet $extra_args

    # Capture the exit code. If it's 1 (critical/lost baseline), auto-fix it.
    if [ $? -eq 1 ]; then
        echo "Baseline lost for $local_path. Forcing resync from Fedora..."
        mullvad-exclude rclone bisync "$local_path" "$remote_path" \
            --resync --resync-mode Path1 --no-cleanup --force --tpslimit 40 $extra_args
    fi
}

# 1. Documents (Preserving your excludes and docx tweaks)
run_bisync "/home/ben/Documents" "googleDrive:Documents" \
    "--exclude /SOS/** --exclude /OneDrive/Bitcoin/** --exclude **/.git/** --drive-import-formats docx,xlsx,pptx"

# 2. Pictures
run_bisync "/home/ben/Pictures" "googleDrive:Pictures" ""

# 3. Videos (Preserving your 128M chunk size)
run_bisync "/home/ben/Videos" "googleDrive:Videos" "--drive-chunk-size 128M"

# 4. Backups (Preserving your 128M chunk size)
run_bisync "/home/ben/Backups" "googleDrive:Backups" "--drive-chunk-size 128M"
