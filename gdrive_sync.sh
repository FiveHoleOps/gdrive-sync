#!/bin/bash

# 1. Documents
mullvad-exclude rclone bisync /home/ben/Documents googleDrive:Documents \
    --no-cleanup --force \
    --exclude "/SOS/**" \
    --exclude "/OneDrive/Bitcoin/**" \
    --exclude "**/.git/**" \
    --drive-import-formats docx,xlsx,pptx \
    --tpslimit 40 --quiet || exit 1

# 2. Pictures
mullvad-exclude rclone bisync /home/ben/Pictures googleDrive:Pictures \
    --no-cleanup --force \
    --tpslimit 40 --quiet || exit 1

# 3. Videos
mullvad-exclude rclone bisync /home/ben/Videos googleDrive:Videos \
    --no-cleanup --force \
    --drive-chunk-size 128M \
    --tpslimit 40 --quiet || exit 1

# 4. Backups
mullvad-exclude rclone bisync /home/ben/Backups googleDrive:Backups \
    --no-cleanup --force \
    --drive-chunk-size 128M \
    --tpslimit 40 --quiet || exit 1
