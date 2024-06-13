#!/bin/bash

source_dir=$1
destination_dir=$2

# Fonction pour la copie des fichiers et la journalisation
backup_files_and_log() {
    local source_dir=$1
    local destination_dir=$2
    
    # Journalisation
    log_message() {
        local type=$1
        local message=$2
        local timestamp=$(date +"%Y-%m-%d-%H-%M-%S")
        local username=$(whoami)
        echo "$timestamp : $username : $type : $message" >> "$log_dir/history.log"
    }
    
    # Loop for copying files
    for file in "$source_dir"/*; do
        timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
        if [ -d "$file" ]; then
            cp -r "$file" "$destination_dir/$(basename "$file")_$timestamp"
            log_message "INFOS" "Dossier '$file' copié avec succès."
        else
            extension="${file##*.}"
            dossier="${extension}Files"
            if [ ! -d "$destination_dir/$dossier" ]; then
                mkdir -p "$destination_dir/$dossier"
            fi
            cp "$file" "$destination_dir/$dossier/$(basename "$file")_$timestamp"
            log_message "INFOS" "Fichier '$file' copié avec succès."
        fi
    done
}

# Appel de la fonction de sauvegarde et de journalisation
backup_files_and_log "$source_dir" "$destination_dir"
