# LXC Container Privilege Converter

## Overview
The LXC Container Privilege Converter is a Bash script designed for Proxmox Virtual Environment. It facilitates the conversion of LXC containers between privileged and unprivileged states. This script automates the process of backing up an existing container, restoring it to a new container with the desired privilege level, and managing the state of both the source and target containers.

## Features
- **Interactive Selection**: Easy-to-use interactive prompts for selecting containers, backup, and target storages.
- **Automated Backup and Restore**: Automates the vzdump backup process and restores to a new container.
- **Privilege Level Conversion**: Converts containers from unprivileged to privileged and vice versa.
- **State Management**: Manages the states of the source and target containers, including shutdown and startup.
- **Cleanup Options**: Offers options to clean up temporary backup files after conversion.

## Prerequisites
- **Proxmox Virtual Environment**
- **Root access on the Proxmox server**
- **LXC containers set up within Proxmox**
- **Enough free space on Backup and Target Storage**
- **LXC containers can be snapshotted in general**

## Installation
1. **Clone the repository:**

git clone https://github.com/onethree7/proxmox-lxc-privilege-converter

2. **Navigate to the script directory:**

cd proxmox-lxc-privilege-converter

3. **Make the script executable:**

chmod +x lxc_privilege_converter.sh

4. **Run the script with root credentials**

sudo ./lxc_privilege_converter.sh

5. **Or Quickstart as below:**

wget -qO- https://github.com/onethree7/proxmox-lxc-privilege-converter/raw/main/lxc_privilege_converter.sh | sudo bash

Follow the interactive prompts to select the source container, backup storage, target storage, and manage the conversion process.

## Script Workflow
- **Check Root Access**: Ensures the script is run with root privileges.
- **Select Source Container**: Choose an LXC container to convert.
- **Backup Container**: Backs up the selected container.
- **Select Target Storage**: Choose storage for the new container.
- **Find Next Free ID**: Automatically finds the next available ID for the new container.
- **Perform Conversion**: Converts the container to the desired privilege level.
- **Manage LXC States**: Option to shut down the source and start the target container.
- **Cleanup Temporary Files**: Option to remove temporary backup files.

## Disclaimer
I am in no way related to Proxmox Server Solutions GmbH

## Contributing
Contributions to improve the script or add new features are welcome.

## License
This project is licensed under the GPL-3.0 License

## Author
**Florian Kefferpuetz**  - Initial work.

## Contributors
haemka

## Acknowledgments
Thanks to Proxmox Team and tteck for the useful scripts at https://github.com/tteck/Proxmox 

