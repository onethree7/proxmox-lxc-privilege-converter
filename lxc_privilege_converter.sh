#!/bin/bash

# help message
show_help() {
    cat << EOF

Converts LXC containers between privileged and unprivileged modes using vzdump. Ensure sufficient Proxmox VE storage.

Run:
- bash ${0##*/}
- chmod +x ${0##*/} && ./${0##*/}

Steps:
1. Choose an LXC.
2. Select backup storage.
3. Backup and choose new container's storage.
4. Convert and manage states.

-h, --help   Show this message

Details: https://github.com/onethree7/proxmox-lxc-privilege-converter
EOF
}

# Did user use -h or --help?
while :; do
    case $1 in
        -h|--help)
            show_help
            exit
            ;;
        *)
            break
    esac
    shift
done

# print banner
banner() {
    clear
    cat << "EOF"
______________   _______________         .____     ____  ____________  
\______   \   \ /   /\_   _____/         |    |    \   \/  /\_   ___ \ 
 |     ___/\   Y   /  |    __)_   ______ |    |     \     / /    \  \/ 
 |    |     \     /   |        \ /_____/ |    |___  /     \ \     \____
 |____|      \___/   /_______  /         |_______ \/___/\  \ \______  /
                             \/                  \/      \_/        \/ 
                      .__      .__.__                                  
         _____________|__|__  _|__|  |   ____   ____   ____            
         \____ \_  __ \  \  \/ /  |  | _/ __ \ / ___\_/ __ \           
         |  |_> >  | \/  |\   /|  |  |_\  ___// /_/  >  ___/           
         |   __/|__|  |__| \_/ |__|____/\___  >___  / \___  >          
         |__|                               \/_____/      \/           
                                             __                        
       ____  ____   _______  __ ____________/  |_  ___________         
     _/ ___\/  _ \ /    \  \/ // __ \_  __ \   __\/ __ \_  __ \        
     \  \__(  <_> )   |  \   /\  ___/|  | \/|  | \  ___/|  | \/        
      \___  >____/|___|  /\_/  \___  >__|   |__|  \___  >__|           
          \/           \/          \/                 \/       v1.0.4  
         Welcome to the Proxmox LXC Privilege Converter Script!
    This script simplifies the process of converting LXC containers for
privileged and unprivileged modes using the vzdump backup and restore method. 
   Ensure that your PVE has enough free space in backup and target storage.
    GitHub: https://github.com/onethree7/proxmox-lxc-privilege-converter
EOF
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root"
        exit 1
    fi
}

# list and select LXC containers
select_container() {
    echo -e "\n\nChoose a Container to convert:\n"
    IFS=$'\n'
    lxc_list=$(pct list | awk '{if(NR>1)print $1 " " $3}')
    select opt in $lxc_list; do
        if [ -n "$opt" ]; then
            CONTAINER_ID=$(echo "$opt" | awk '{print $1}')
            CONTAINER_NAME=$(echo "$opt" | awk '{print $2}')
            echo -e "Selected container: $CONTAINER_ID ($CONTAINER_NAME)\n"
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done
}

# select backup storage
select_backup_storage() {
    echo -e "Select backup storage (this is just for the tmp-file we create LXC from):"
    backup_storages=$(pvesm status --content backup | awk '{if(NR>1)print $1}')
    select opt in $backup_storages; do
        if [ -n "$opt" ]; then
            BACKUP_STORAGE=$opt
            echo -e "Selected backup storage: $BACKUP_STORAGE"
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done
}

# perform backup, grab path and success status
backup_container() {
    echo -e "Performing backup of container $CONTAINER_ID...\n"
    vzdump_output=$(mktemp)
    vzdump "$CONTAINER_ID" --compress zstd --storage "$BACKUP_STORAGE" --mode snapshot | tee "$vzdump_output"
    BACKUP_PATH=$(awk '/tar.zst/ {print $NF}' "$vzdump_output" | tr -d "'")

    if [ -z "$BACKUP_PATH" ] || ! grep -q "Backup job finished successfully" "$vzdump_output"; then
        rm "$vzdump_output"
        echo "Backup of container $CONTAINER_ID failed or was incomplete."
        exit 1
    fi

    rm "$vzdump_output"
}

# select target storage for the new container
select_target_storage() {
    echo -e "\nSelect target storage for the new container:\n"
    target_storages=$(pvesm status --content images | awk '{if(NR>1)print $1}')
    select opt in $target_storages; do
        if [ -n "$opt" ]; then
            TARGET_STORAGE=$opt
            echo -e "Selected target storage: $TARGET_STORAGE\n"
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done
}

# find the next free ID using pvesh
find_next_free_id() {
    pvesh get /cluster/nextid
}

# select ID for the new container
select_container_id() {
    next_free_id=$(find_next_free_id)
    while true; do
	read -r -p "Select the new container ID [$next_free_id]: " NEW_CONTAINER_ID

	if [ -z "$NEW_CONTAINER_ID" ]; then
	    NEW_CONTAINER_ID=$next_free_id
	    break
	fi

	if pct list | grep -q "^$NEW_CONTAINER_ID "; then
	    echo "Already used container ID. Please try again."
	else
	    break
	fi
    done
}

# perform conversion
perform_conversion() {
    if pct config "$CONTAINER_ID" | grep -q 'unprivileged: 1'; then
        UNPRIVILEGED_FLAG=true
        echo "Container $CONTAINER_ID is currently unprivileged."
    else
        UNPRIVILEGED_FLAG=false
        echo "Container $CONTAINER_ID is currently privileged."
    fi

    if $UNPRIVILEGED_FLAG; then
        echo -e "Converting unprivileged container $CONTAINER_ID to privileged container $NEW_CONTAINER_ID...\n"
        if ! pct restore "$NEW_CONTAINER_ID" "$BACKUP_PATH" --storage "$TARGET_STORAGE" --unprivileged false -ignore-unpack-errors 1; then
            echo "Conversion to container $NEW_CONTAINER_ID failed"
            exit 1
        fi
    else
        echo -e "Converting privileged container $CONTAINER_ID to unprivileged container $NEW_CONTAINER_ID...\n"
        if ! pct restore "$NEW_CONTAINER_ID" "$BACKUP_PATH" --storage "$TARGET_STORAGE" --unprivileged -ignore-unpack-errors 1; then
            echo "Conversion to container $NEW_CONTAINER_ID failed"
            exit 1
        fi
    fi
    echo -e "\nConversion to container $NEW_CONTAINER_ID successful\n"
}

# manage LXC states
manage_lxc_states() {
    read -r -p "Shutdown source and start target container? [Y/n]: " statechange_choice
    statechange_choice=${statechange_choice:-Y}

    if [[ $statechange_choice =~ ^[Yy]([Ee][Ss])?$ ]]; then
        echo "Please note: If the container does not shut down within 3 minutes, you can choose to force the shutdown."
        pct shutdown "$CONTAINER_ID"
        local counter=0
        local timeout=180

        while [ $counter -lt $timeout ]; do
            if ! pct status "$CONTAINER_ID" | grep -q "running"; then
                echo -e "Container $CONTAINER_ID shutdown successful"
                break
            fi
            sleep 5
            ((counter+=5))
        done

        if [ $counter -ge $timeout ]; then
            prompt_for_forced_shutdown
        fi

        if ! pct start "$NEW_CONTAINER_ID"; then
            echo -e "Failed to start container $NEW_CONTAINER_ID\n"
            exit 1
        fi
        echo -e "Container $NEW_CONTAINER_ID started successfully\n"
    else
        echo -e "Skipping shutdown of source and start of target container.\n"
    fi
}

# Prompt for forced shutdown, modular for manage_lxc_states
prompt_for_forced_shutdown() {
    read -r -p "Timeout reached. Forcefully shutdown the container? [Y/n]: " force_shutdown_choice
    force_shutdown_choice=${force_shutdown_choice:-Y}

    if [[ $force_shutdown_choice =~ ^[Yy]([Ee][Ss])?$ ]]; then
        echo "Initiating forced termination of container $CONTAINER_ID."
        if ! pkill -9 -f "lxc-start -F -n $CONTAINER_ID"; then
            echo -e "Failed to force shutdown container $CONTAINER_ID\n"
            exit 1
        fi
        echo "Forced termination of container $CONTAINER_ID completed."
    else
        echo "Skipping forced termination. Please manually manage the container state."
    fi
}

# ask for cleanup of temporary backup files
cleanup_temp_files() {
    read -r -p "Do you want to clean up temporary backup files? $BACKUP_PATH [Y/n]: " cleanup_choice
    cleanup_choice=${cleanup_choice:-Y}

    if [[ $cleanup_choice =~ ^[Yy]([Ee][Ss])?$ ]]; then
        if rm -f "$BACKUP_PATH"; then
            echo "Temporary backup files cleaned up successfully."
        else
            echo "Failed to clean up temporary backup files."
        fi
    else
        echo "Skipping cleanup of temporary backup files."
    fi
    echo
}

# Summary function
summarize_actions() {
    echo -e "\n=================================================="
    echo "Conversion Summary Report"
    echo "=================================================="
    echo "Source Container: $CONTAINER_ID ($CONTAINER_NAME)"
    echo "Backup Storage: $BACKUP_STORAGE"
    echo "Backup Path: $BACKUP_PATH"
    echo "Target Storage for New Container: $TARGET_STORAGE"
    echo "New Container: $NEW_CONTAINER_ID ($CONTAINER_NAME)"
    echo "Privilege Conversion: $(if [ "$UNPRIVILEGED_FLAG" = true ]; then echo "Unprivileged to Privileged"; else echo "Privileged to Unprivileged"; fi)"
    echo "Container State Changes: $(if [[ $statechange_choice =~ ^[Yy]([Ee][Ss])?$ ]]; then echo "Source Stopped, Target Started"; else echo "No Changes Made"; fi)"
    echo "Cleanup of Temporary Files: $(if [[ $cleanup_choice =~ ^[Yy]([Ee][Ss])?$ ]]; then echo "Performed"; else echo "Skipped"; fi)"
    echo -e "==================================================\n"
}

main() {
    banner
    check_root
    select_container
    select_backup_storage
    backup_container
    select_target_storage
    select_container_id
    perform_conversion
    manage_lxc_states
    cleanup_temp_files
    summarize_actions
}

# Main script execution
main
