#!/bin/bash

# === COLORS ===
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
RESET="\e[0m"

# === PATHS ===
SRC="$HOME/.config"
DEST="$HOME/MyBackup"
LOGFILE="$DEST/backup_log.txt"
DATESTAMP=$(date +"%H%M_%d%m_%Y")
PUSHTOGIT="$HOME/pushtogit.sh"

mkdir -p "$DEST"

# --- Progress Bar (integer-based, no bc required) ---
progress_bar() {
    local duration=$1
    local total=20
    local sleep_time=$((duration * 100 / total))  # hundredths of sec

    echo -n "["
    for ((i=0;i<total;i++)); do
        echo -n "#"
        sleep $(awk "BEGIN {print $sleep_time/100}")
    done
    echo "]"
}

# --- Backup Function ---
backup() {
    echo -e "${CYAN}Creating backup with timestamp $DATESTAMP...${RESET}"
    echo -e "${YELLOW}Versioning format: filename_HHMM_DDMM_YYYY${RESET}"

    files_to_backup=()

    # Backup folders
    for folder in "$SRC"/*/; do
        [ -d "$folder" ] || continue
        base_folder=$(basename "$folder")
        mkdir -p "$DEST/$base_folder"

        while IFS= read -r file; do
            filename=$(basename "$file")
            newname="${filename}_${DATESTAMP}"
            cp "$file" "$DEST/$base_folder/$newname"
            echo "$DATESTAMP | $base_folder | $filename -> $newname" >> "$LOGFILE"
            files_to_backup+=("$filename")
        done < <(find "$folder" -type f \( -name "*.conf" -o -name "*.list" -o -name "*.dirs" -o -name "*.locale" -o -name "*.ttf" -o -name "*.toml" \))
    done

    # Backup loose files in .config
    while IFS= read -r file; do
        filename=$(basename "$file")
        newname="${filename}_${DATESTAMP}"
        cp "$file" "$DEST/$newname"
        echo "$DATESTAMP | .config_root | $filename -> $newname" >> "$LOGFILE"
        files_to_backup+=("$filename")
    done < <(find "$SRC" -maxdepth 1 -type f \( -name "*.conf" -o -name "*.list" -o -name "*.dirs" -o -name "*.locale" -o -name "*.ttf" -o -name "*.toml" \))

    echo -e "${GREEN}Backing up ${#files_to_backup[@]} files...${RESET}"
    progress_bar 2
    echo -e "${GREEN}Backup complete. Log saved to $LOGFILE${RESET}"
}

# --- Restore Function ---
restore() {
    echo -e "${CYAN}Available backups (timestamps):${RESET}"
    cut -d"|" -f1 "$LOGFILE" | sort -u
    echo
    read -p "Enter timestamp to restore (format HHMM_DDMM_YYYY): " choice

    read -p "Are you sure you want to restore this backup? [Yes/NO]: " confirm
    if [[ ! "$confirm" =~ ^[Yy] ]]; then
        echo -e "${RED}Restore cancelled.${RESET}"
        return
    fi

    files_to_restore=()
    grep "$choice" "$LOGFILE" | while IFS="|" read -r ts folder orig renamed; do
        ts=$(echo "$ts" | xargs)
        folder=$(echo "$folder" | xargs)
        orig=$(echo "$orig" | xargs)
        renamed=$(echo "$renamed" | xargs)

        if [ "$folder" = ".config_root" ]; then
            src_file="$DEST/$renamed"
            dest_file="$SRC/$orig"
        else
            src_file="$DEST/$folder/$renamed"
            dest_file="$SRC/$folder/$orig"
            mkdir -p "$SRC/$folder"
        fi

        if [ -f "$src_file" ]; then
            rm -f "$dest_file"
            cp "$src_file" "$dest_file"
            files_to_restore+=("$orig")
        fi
    done

    echo -e "${GREEN}Restoring ${#files_to_restore[@]} files...${RESET}"
    progress_bar 2
    echo -e "${GREEN}Restore complete!${RESET}"
}

# --- Git Push Function ---
pushtogit() {
    if [ -f "$PUSHTOGIT" ]; then
        bash "$PUSHTOGIT"
    else
        echo -e "${RED}Push-to-Git script not found at $PUSHTOGIT${RESET}"
        echo -e "${YELLOW}Please save pushtogit.sh in your home folder.${RESET}"
    fi
}

# --- Main Menu ---
echo -e "${BLUE}=== MyConfig Backup & Restore Tool ===${RESET}"

if [ -f "$LOGFILE" ]; then
    echo -e "${YELLOW}A backup log already exists.${RESET}"
    echo -e "${CYAN}1) Create new backup${RESET}"
    echo -e "${CYAN}2) Restore configuration${RESET}"
    echo -e "${CYAN}3) Push backups to GitHub${RESET}"
    read -p "Choose an option (1/2/3): " opt
    case $opt in
        1) backup ;;
        2) restore ;;
        3) pushtogit ;;
        *) echo -e "${RED}Invalid choice${RESET}" ;;
    esac
else
    backup
fi

