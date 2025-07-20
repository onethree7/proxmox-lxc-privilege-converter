# LXC Container Privilege Converter

## Overview

Convert LXC containers between privileged and unprivileged modes in Proxmox VE. Automates vzdump backup, container restore, and privilege switch with interactive selection.

## Features

- Interactive menu for container and storage selection.
- Validates new container ID against all cluster VMs and LXCs.
- Automatic vzdump backup and restore / PBS backup and restore. 
- Detects and switches privilege mode from unprivileged to priviliged and vise versa.
- Handles Proxmox Backup Server (PBS) and local Backup Storage for the conversion Temp Files.
- Optional shutdown/start logic for containers, including force kill.
- Prompts for cleanup of backup files after conversion.
- Root check, strict error handling.

## Prerequisites

- Proxmox VE with root access
- Sufficient storage for local vzdump / Proxmox Backup Server
- LXC containers set up

## Installation & Usage

```bash
# The boring way:
git clone https://github.com/onethree7/proxmox-lxc-privilege-converter
cd proxmox-lxc-privilege-converter
chmod +x lxc_privilege_converter.sh
./lxc_privilege_converter.sh

# Quickstart:
bash <(curl -L https://github.com/onethree7/proxmox-lxc-privilege-converter/raw/main/lxc_privilege_converter.sh)
```

- Follow the menu to select container, backup storage, target storage, and new ID.
- Script will handle all steps and print a summary at the end. 
- PBS as Backupstorage is supported, but limited when cgroups or devices (like hw-passthrough) exist (on conversions to unprivileged).
- Local Backupstorage is recommended in most cases and not similarily limited.

## Workflow

- Banner
- Root check
- Select source container
- Select backup storage (Temp File)
- Perform vzdump/PBS backup -> backup storage
- Select target storage
- Select or confirm new container ID (validated)
- Restore with updated privilege state -> target storage
- Optionally shutdown/start containers (with force kill option/3min)
- Optionally delete backup (only local vzdumps)
- Shows a summary

## Changelog

See CHANGELOG.md for version info.

## License

GPL-3.0

## Author

Florian Kefferpuetz

## Contributors

haemka, ebertland

## Disclaimer

No relation to Proxmox Server Solutions GmbH.

## Thanks

Proxmox team, Community Scripts and tteck (RIP 11/2024), see: https://github.com/tteck/Proxmox & https://community-scripts.github.io/ProxmoxVE/
Please let me know with an Issue report if you find bugs or have a feature request.
