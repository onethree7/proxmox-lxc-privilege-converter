# LXC Container Privilege Converter

## Overview

The LXC Container Privilege Converter is a Bash script designed for the Proxmox Virtual Environment (PVE). It facilitates the conversion of LXC containers between privileged and unprivileged states. This script automates the process of backing up an existing container, restoring it to a new container with the desired privilege mode, and manages container states seamlessly.

## Features

- **Interactive Selection**: Easy-to-use interactive prompts for selecting containers, backup storage, and target storage.
- **Custom Container ID Selection**: Specify a new container ID during the conversion process, with validation to prevent ID conflicts across the cluster.
- **Cluster-Aware ID Retrieval**: Automatically retrieves all used VM and LXC IDs across the cluster to prevent ID conflicts.
- **Automated Backup and Restore**: Automates the `vzdump` backup process and restores to a new container.
- **Privilege Level Conversion**: Converts containers from unprivileged to privileged and vice versa.
- **State Management**: Manages the states of the source and target containers, including shutdown and startup options.
- **Cleanup Options**: Offers options to clean up temporary backup files after conversion.
- **Enhanced Help Message**: Access detailed usage instructions via `-h` or `--help` flags.

## Prerequisites

- **Proxmox Virtual Environment**
- **Root access on the Proxmox server**
- **LXC containers set up within Proxmox**
- **Enough free space on Backup and Target Storage**
- **LXC containers can be snapshotted in general**

## Installation1. **Clone the repository:**

git clone https://github.com/onethree7/proxmox-lxc-privilege-converter

2. **Navigate to the script directory:**

cd proxmox-lxc-privilege-converter

3. **Make the script executable:**

chmod +x lxc_privilege_converter.sh

4. **Run the script with root credentials**

sudo ./lxc_privilege_converter.sh

5. **Or Quickstart as below:**

bash <(curl -L https://github.com/onethree7/proxmox-lxc-privilege-converter/raw/main/lxc_privilege_converter.sh)

Follow the interactive prompts to select the source container, backup storage, target storage, and manage the conversion process.

## Script Workflow
- **Check Root Access**: Ensures the script is run with root privileges.
- **Display Banner**: Shows a detailed banner with script information.
- **Select Source Container**: Choose an LXC container to convert.
- **Select Backup Storage**: Choose the storage location for the backup file.
- **Backup Container**: Backs up the selected container.
- **Select Target Storage**: Choose storage for the new container.
- **Specify New Container ID**:
  - Prompts you to enter a new container ID.
  - Validates the ID against existing IDs across the cluster to prevent conflicts.
  - Offers the next free ID as the default option.
- **Perform Conversion**:
  - Determines the current privilege status of the container.
  - Converts the container to the opposite privilege mode.
- **Manage LXC States**: Option to shut down the source and start the target container.
- **Cleanup Temporary Files**: Option to remove temporary backup files.
- **Summary Report**: Displays a summary of all actions performed.

## Disclaimer
I am in no way related to Proxmox Server Solutions GmbH

## Contributing
Contributions to improve the script or add new features are welcome.

## License
This project is licensed under the GPL-3.0 License

## Author
**Florian Kefferpuetz**  - Initial work.

## Contributors
haemka - added extended Cluster support.
ebertland - suggested select_container_id and provided code draft.

## Acknowledgments
Thanks to Proxmox Team and tteck (RIP 11/2024) for the useful scripts at https://github.com/tteck/Proxmox
