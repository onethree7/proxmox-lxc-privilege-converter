#!/bin/bash

banner() {
clear
cat <<'EOF'
              (LXC)  .__      .__.__                                  
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
          \/           \/          \/                 \/ v1.0.6     
                   1. Choose an LXC container
                    2. Select backup storage
               3. Backup and select target storage
             4. Convert and manage container states

  details: https://github.com/onethree7/proxmox-lxc-privilege-converter
EOF
}

show_help() { banner; exit 0; }
[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help

yes_choice() { [[ "$1" =~ ^[Yy]([Ee][Ss])?$ ]]; }

check_root() {
    [[ $EUID -ne 0 ]] && { echo "This script must be run as root"; exit 1; }
}

select_container() {
    echo -e "\nChoose a container to convert:\n"
    IFS=$'\n'
    lxc_list=$(pct list | awk 'NR>1{print $1 " " $3}')
    PS3="Select LXC (number): "
    select opt in $lxc_list; do
        [[ -n "${opt:-}" ]] && {
            CONTAINER_ID=$(awk '{print $1}' <<<"$opt")
            CONTAINER_NAME=$(awk '{print $2}' <<<"$opt")
            echo -e "Selected container: $CONTAINER_ID ($CONTAINER_NAME)\n"
            break
        }
        echo "Invalid selection. Please try again."
    done
}

select_backup_storage() {
    echo -e "Select backup storage (for vzdump archive):"
    backup_storages=$(pvesm status --content backup | awk 'NR>1{print $1}')
    PS3="Backup storage (number): "
    select opt in $backup_storages; do
        [[ -n "${opt:-}" ]] && {
            BACKUP_STORAGE="$opt"
            BACKUP_STORAGE_TYPE=$(pvesm status | awk -v s="$BACKUP_STORAGE" '$1==s {print $2}')
            echo -e "Selected backup storage: $BACKUP_STORAGE"
            break
        }
        echo "Invalid selection. Please try again."
    done
}

backup_container() {
    echo -e "Performing backup of container $CONTAINER_ID...\n"
    vzdump_output=$(mktemp)
    vzdump "$CONTAINER_ID" --compress zstd --storage "$BACKUP_STORAGE" --mode snapshot | tee "$vzdump_output"
    grep -q "Backup job finished successfully" "$vzdump_output" || { rm -f "$vzdump_output"; echo "Backup of container $CONTAINER_ID failed or was incomplete."; exit 1; }
    if [[ "$BACKUP_STORAGE_TYPE" = "pbs" ]]; then
        BACKUP_VOLID=$(awk -F"'" '/creating Proxmox Backup Server archive/ {print $2}' "$vzdump_output")
        [[ -z "${BACKUP_VOLID:-}" ]] && { rm -f "$vzdump_output"; echo "Could not parse PBS backup ID."; exit 1; }
    else
        BACKUP_PATH=$(awk '/tar.zst/ {print $NF}' "$vzdump_output" | tr -d "'")
        [[ -z "${BACKUP_PATH:-}" ]] && { rm -f "$vzdump_output"; echo "Could not parse backup path."; exit 1; }
    fi
    rm -f "$vzdump_output"
}

select_target_storage() {
    echo -e "\nSelect target storage for the new container:\n"
    target_storages=$(pvesm status --content images | awk 'NR>1{print $1}')
    PS3="Target storage (number): "
    select opt in $target_storages; do
        [[ -n "${opt:-}" ]] && {
            TARGET_STORAGE="$opt"
            echo -e "Selected target storage: $TARGET_STORAGE\n"
            break
        }
        echo "Invalid selection. Please try again."
    done
}

get_used_ids() {
    USED_IDS=()
    IDS_OUTPUT=$(pvesh get /cluster/resources --type vm --output-format json | grep -Eo '"vmid":[ ]*[0-9]+' | grep -Eo '[0-9]+')
    while read -r vmid; do USED_IDS+=("$vmid"); done <<< "$IDS_OUTPUT"
}

select_container_id() {
    next_free_id=$(pvesh get /cluster/nextid)
    get_used_ids
    while true; do
        read -r -p "Enter a new container ID (or press Enter to use next free ID [$next_free_id]): " NEW_CONTAINER_ID
        NEW_CONTAINER_ID="${NEW_CONTAINER_ID:-$next_free_id}"
        [[ "$NEW_CONTAINER_ID" =~ ^[0-9]+$ ]] || { echo "Invalid input. Please enter a valid numeric container ID."; continue; }
        for used in "${USED_IDS[@]}"; do [[ "$used" = "$NEW_CONTAINER_ID" ]] && { echo "Already used container ID. Please try again."; continue 2; }; done
        break
    done
}

restore_container() {
    if pct config "$CONTAINER_ID" | grep -q 'unprivileged: 1'; then
        UNPRIVILEGED_FLAG=true
        echo "Container $CONTAINER_ID is currently unprivileged."
        RESTORE_FLAG="--unprivileged false"
        MSG="Converting unprivileged container $CONTAINER_ID to privileged container $NEW_CONTAINER_ID..."
    else
        UNPRIVILEGED_FLAG=false
        echo "Container $CONTAINER_ID is currently privileged."
        RESTORE_FLAG="--unprivileged"
        MSG="Converting privileged container $CONTAINER_ID to unprivileged container $NEW_CONTAINER_ID..."
    fi

    if [[ "$BACKUP_STORAGE_TYPE" = "pbs" ]]; then
        RESTORE_SRC="$BACKUP_STORAGE:backup/$BACKUP_VOLID"
        RESTORE_ARGS="\"$NEW_CONTAINER_ID\" \"$RESTORE_SRC\" --storage \"$TARGET_STORAGE\""
    else
        RESTORE_SRC="$BACKUP_PATH"
        RESTORE_ARGS="\"$NEW_CONTAINER_ID\" \"$RESTORE_SRC\" --storage \"$TARGET_STORAGE\" -ignore-unpack-errors 1"
    fi

    echo -e "$MSG\n"
    eval pct restore $RESTORE_ARGS $RESTORE_FLAG || { echo "Conversion to container $NEW_CONTAINER_ID failed"; exit 1; }
    echo -e "\nConversion to container $NEW_CONTAINER_ID successful\n"
}

manage_lxc_states() {
    read -r -p "Shutdown source and start target container? [Y/n]: " statechange_choice
    statechange_choice="${statechange_choice:-Y}"
    if yes_choice "$statechange_choice"; then
        echo "Shutting down container $CONTAINER_ID (max 3 minutes)..."
        pct shutdown "$CONTAINER_ID" || true
        local counter=0 timeout=180
        while [[ $counter -lt $timeout ]]; do
            if ! pct status "$CONTAINER_ID" | grep -q "running"; then
                echo -e "Container $CONTAINER_ID shutdown successful"
                break
            fi
            printf "Waiting for shutdown... (%ss/%ss)\r" "$counter" "$timeout"
            sleep 5
            ((counter+=5))
        done
        echo
        [[ $counter -ge $timeout ]] && prompt_for_forced_shutdown
        pct start "$NEW_CONTAINER_ID" || { echo -e "Failed to start container $NEW_CONTAINER_ID\n"; exit 1; }
        echo -e "Container $NEW_CONTAINER_ID started successfully\n"
    else
        echo -e "Skipping shutdown of source and start of target container.\n"
    fi
}

prompt_for_forced_shutdown() {
    read -r -p "Timeout reached. Forcefully kill container? [Y/n]: " force_shutdown_choice
    force_shutdown_choice="${force_shutdown_choice:-Y}"
    if yes_choice "$force_shutdown_choice"; then
        echo "kill -9: Forcing termination of container $CONTAINER_ID"
        pkill -9 -f "lxc-start -F -n $CONTAINER_ID" && \
            echo "Container $CONTAINER_ID killed." || \
            { echo "Failed to kill $CONTAINER_ID"; exit 1; }
    else
        echo "No forced termination. Handle container state manually."
    fi
}

cleanup_temp_files() {
    if [[ "$BACKUP_STORAGE_TYPE" = "pbs" ]]; then
        echo "No local backup file to cleanup (PBS storage)."
        cleanup_choice="N"
        return
    fi
    read -r -p "Do you want to clean up temporary backup files? \"$BACKUP_PATH\" [Y/n]: " cleanup_choice
    cleanup_choice="${cleanup_choice:-Y}"
    if yes_choice "$cleanup_choice"; then
        rm -f -- "$BACKUP_PATH" && echo "Temporary backup files cleaned up successfully." || echo "Failed to clean up temporary backup files."
    else
        echo "Skipping cleanup of temporary backup files."
    fi
    echo
}

summarize_actions() {
    echo -e "\n=================================================="
    echo "Conversion Summary Report"
    echo "=================================================="
    echo "Source Container: $CONTAINER_ID ($CONTAINER_NAME)"
    echo "Backup Storage: $BACKUP_STORAGE"
    [[ "$BACKUP_STORAGE_TYPE" = "pbs" ]] && echo "Backup ID: $BACKUP_VOLID" || echo "Backup Path: $BACKUP_PATH"
    echo "Target Storage for New Container: $TARGET_STORAGE"
    echo "New Container: $NEW_CONTAINER_ID ($CONTAINER_NAME)"
    echo "Privilege Conversion: $( [[ "$UNPRIVILEGED_FLAG" = true ]] && echo "Unprivileged to Privileged" || echo "Privileged to Unprivileged" )"
    echo "Container State Changes: $( yes_choice "${statechange_choice:-Y}" && echo "Source Stopped, Target Started" || echo "No Changes Made" )"
    echo "Cleanup of Temporary Files: $( yes_choice "${cleanup_choice:-Y}" && echo "Performed" || echo "Skipped" )"
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
    restore_container
    manage_lxc_states
    cleanup_temp_files
    summarize_actions
}
main
