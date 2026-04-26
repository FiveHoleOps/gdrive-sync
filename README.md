# GDrive Sync (rclone bisync)

A robust automation script for bi-directional synchronization between a Fedora local environment and Google Drive. This utility is designed for sysadmins who prioritize data integrity and network privacy.

## Features
* **Bi-directional Sync:** Uses `rclone bisync` to ensure changes on both local and cloud endpoints are merged safely.
* **VPN Split-Tunneling:** Integrated with `mullvad-exclude` to allow high-bandwidth sync traffic to bypass the VPN tunnel for maximum speed while keeping the rest of the system secure.
* **Optimized for Media:** Custom chunk sizes and TPS limits configured specifically for Google Drive's API.
* **Directory Scoping:** Handles Documents, Pictures, Videos, and Backups as distinct sync jobs.

## Prerequisites
* [rclone](https://rclone.org/) configured with a remote named `googleDrive`.
* [Mullvad VPN](https://mullvad.net/) (optional, if using the bypass feature).

## Installation
1. Clone the repository:
   ```bash
   git clone [https://github.com/FiveHoleOps/gdrive-sync.git](https://github.com/FiveHoleOps/gdrive-sync.git)
