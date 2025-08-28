#!/bin/bash

DEST="$HOME/MyBackup"
REPO_URL_FILE="$DEST/.repo_url"

# Colors
GREEN="\e[32m"
RED="\e[31m"
CYAN="\e[36m"
RESET="\e[0m"

# Check if MyBackup exists
if [ ! -d "$DEST" ]; then
    echo -e "${RED}Error: $DEST does not exist. Run your backup script first.${RESET}"
    exit 1
fi

cd "$DEST" || exit

# First run setup
if [ ! -d ".git" ]; then
    echo -e "${CYAN}Git is not initialized for MyBackup. Setting it up now...${RESET}"
    git init
    git branch -M main

    echo -e "${CYAN}Enter your GitHub repo URL (SSH or HTTPS):${RESET}"
    read -r repo_url
    git remote add origin "$repo_url"
    echo "$repo_url" > "$REPO_URL_FILE"

    echo -e "${GREEN}Git setup complete. Repo linked to: $repo_url${RESET}"
else
    # Ensure remote exists
    if [ ! -f "$REPO_URL_FILE" ]; then
        echo -e "${CYAN}No stored repo URL. Please enter your GitHub repo URL:${RESET}"
        read -r repo_url
        git remote remove origin 2>/dev/null
        git remote add origin "$repo_url"
        echo "$repo_url" > "$REPO_URL_FILE"
    else
        repo_url=$(cat "$REPO_URL_FILE")
    fi
fi

# Commit & push
git add .
git commit -m "Backup update: $(date +"%H:%M %d-%m-%Y")" || echo -e "${CYAN}No changes to commit.${RESET}"
git push origin main

echo -e "${GREEN}Push to GitHub completed!${RESET}"

