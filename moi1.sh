#!/bin/bash

# Initialisation des variables pour les options
use_fork=false
use_thread=false
use_subshell=false
use_log=false
use_restore=false
log_dir="/var/log/script"
script_name=$(basename "$0")

# Fonction pour enregistrer les messages dans le fichier de journalisation
log_message() {
    local type=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d-%H-%M-%S")
    local username=$(whoami)
    echo "$timestamp : $username : $type : $message" >> "$log_dir/history.log"
}

# Redirection des sorties standard et d'erreur vers le terminal et le fichier de journalisation
exec > >(tee >(log_message "INFOS") >&1)
exec 2> >(tee >(log_message "ERROR") >&2)

# Fonction d'affichage de l'aide
display_help() {
    echo "Usage: $script_name NbHeure [options] source_directory backup_directory"
    echo "Options:"
    echo "  Sans option          Execution simple faire un backup"
    echo "  -h, --help           Affiche l'aide"
    echo "  -f, --fork           Exécution par création de sous-processus avec fork"
    echo "  -t, --thread         Exécution par threads"
    echo "  -s, --subshell       Exécute le programme dans un sous-shell"
    echo "  -l, --log            Spécifie un répertoire pour le fichier de journalisation"
    echo "  -r, --restore        Réinitialise les paramètres par défaut (réservé aux administrateurs)"

    echo "  Pour le bon fonctionnement de l'automatisation donner le chemin complet pour chaque argument "
    echo "il faut obligatoirement donner les deux options si tu specifie les options le nombre d'heures est optionnel "
}

# Nombre d'heures spécifié par l'utilisateur
if [[  "$1" =~ ^[0-9]+$ ]]; then
    heures="$1"
    shift  # Ignorer le premier argument (le nombre d'heures)
fi

# Boucle pour traiter les options
while [[ $# -gt 2 ]]; do
    case $1 in
        -h | --help )
            display_help
            exit 0 # execution normal 
            ;;
        -f | --fork )
            use_fork=true
            ;;
        -t | --thread )
            use_thread=true
            ;;
        -s | --subshell )
            use_subshell=true
            ;;
        -l | --log )
            use_log=true
            shift
            log_dir=$1
            ;;
        -r | --restore )
            use_restore=true
            ;;
        *)
            echo "Option non reconnue: $1"
            display_help
            exit 103 # argument inconue 
            ;;
    esac
    shift  # Passer à l'argument suivant
done

# Vérification du nombre d'arguments
if [ "$#" -lt 2 ]; then
    echo "Erreur : Le nombre d'arguments est insuffisant."
    display_help
    exit 101
fi

# Vérification de l'existence du répertoire source
if [ ! -d "$1" ] ; then 
    log_message "ERROR" "Le répertoire source '$1' n'existe pas."
    exit 100 
fi 

# Vérification de l'existence du répertoire de destination
if [ ! -d "$2" ] ; then 
    log_message "ERROR" "Le répertoire de destination '$2' n'existe pas."
    mkdir -p "$2"
    if [ $? -ne 0 ] ; then
        log_message "ERROR" "Erreur lors de la création du répertoire de destination '$2'."
        exit 102
    else
        log_message "INFOS" "Répertoire de destination '$2' créé avec succès."
    fi
fi 

# Backup Operation based on Options
# if [ "$use_fork" = true ]; then
#     # Backup using fork
#     log_message "INFOS" "Execution avec fork"
#     # Your backup logic with fork
# fi

if [ "$use_fork" = true ]; then
    # Backup using fork
    log_message "INFOS" "Execution avec fork"
    
    # Forking a child process
    if ! child_pid=$(fork); then
        log_message "ERROR" "Erreur lors de la création du processus fils avec fork()"
        exit 1
    fi
    
    # Inside the child process
    if [ "$child_pid" -eq 0 ]; then
        # Your backup logic with fork
        log_message "INFOS" "Processus fils en cours d'exécution pour la copie des fichiers"
        
        # Loop for copying files
        for file in "$1"/*; do
            timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
            if [ -d "$file" ]; then
                cp -r "$file" "$2/$(basename "$file")_$timestamp"
                log_message "INFOS" "Dossier '$file' copié avec succès."
            else
                extension="${file##*.}"
                dossier="${extension}Files"
                if [ ! -d "$2/$dossier" ]; then
                    mkdir -p "$2/$dossier"
                fi
                cp "$file" "$2/$dossier/$(basename "$file")_$timestamp"
                log_message "INFOS" "Fichier '$file' copié avec succès."
            fi
        done
        exit 0
    fi
fi

# if [ "$use_thread" = true ]; then
#     # Backup using threads
#     log_message "INFOS" "Execution avec threads"
#     # Your backup logic with threads
# fi

if [ "$use_thread" = true ]; then
    # Backup using threads
    log_message "INFOS" "Execution avec threads"

    # Fonction pour la copie des fichiers
    backup_files() {
        local source_dir=$1
        local destination_dir=$2
        
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
    
    # Lancer la fonction en arrière-plan
    backup_files "$1" "$2" &
fi


# if [ "$use_subshell" = true ]; then
#     # Backup using subshell
#     log_message "INFOS" "Execution avec un sous shell"
#     # Your backup logic with subshell
# fi

if [ "$use_subshell" = true ]; then
    # Backup using subshell
    log_message "INFOS" "Execution avec un sous shell"
    
    # Exécuter le script de sauvegarde dans un sous-shell
    (bash backup_script.sh "$1" "$2")
fi



if  [ "$use_log" = true ]; then
    # Backup using log
    log_message "INFOS" "Execution en utilisant un fichier de journalisation"
    if [ ! -d "$log_dir" ] ; then 
        log_message "ERROR" "Le répertoire de journalisation '$log_dir' n'existe pas."
        mkdir -p "$log_dir"
        if [ $? -ne 0 ] ; then
            log_message "ERROR" "Erreur lors de la création du répertoire de journalisation '$log_dir'."
            exit 102
        else
            log_message "INFOS" "Répertoire de journalisation '$log_dir' créé avec succès."
        fi
    fi 
    # Your backup logic with subshell
fi
if [ "$use_restore" = true ]; then
    # Backup using restore
    log_message "INFOS" "Restaurer les paramètres par défaut: Execution avec Restore."
    # Your backup logic with subshell
fi

if ! $use_fork && ! $use_thread && ! $use_subshell && ! $use_log && ! $use_restore; then   
    log_message "INFOS" "Execution normal"
    log_message "INFOS" "Copie des fichiers"
    for file in "$1"/* ; do 
        # Ajouter un timestamp au nom du fichier pour le différencier
        timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
        if [ -d "$file" ] ; then
            cp -r "$file" "$2/$(basename "$file")_$timestamp" 
            log_message "INFOS" "Dossier '$file' copié avec succès."
        else  # si c'est un fichier 
            # Extraire l'extension du fichier
            extension="${file##*.}"   
            # Concaténer le nom de l'extension avec "files"
            dossier="${extension}Files"
            # Créer le répertoire de destination pour cette extension si il n'existe pas encore
            if [ ! -d "$2/$dossier" ] ; then
                mkdir -p "$2/$dossier"
            fi
            # Déplacer le fichier vers le répertoire correspondant à son extension
            cp "$file" "$2/$dossier/$(basename "$file")_$timestamp"
            log_message "INFOS" "Fichier '$file' copié avec succès."
        fi
    done
fi

# Ajout du script avec ses arguments dans le crontab pour l'exécution automatique chaque NbHeures
# Étape 1 : Créer un fichier temporaire contenant la configuration cron
cron_config=$(mktemp)
# Sauvegarder le contenu actuel du crontab dans un fichier temporaire
crontab -l > "$cron_config"
echo "0 */$heures * * * $script_name" >> "$cron_config"
# Étape 2 : Ajouter la configuration cron à la crontab
crontab "$cron_config"
# Étape 3 : Nettoyer le fichier temporaire
rm "$cron_config"

log_message "INFOS" "La tâche cron pour exécuter '$script_name' toutes les $heures heures a été configurée."