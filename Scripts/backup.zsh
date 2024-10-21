#!/bin/zsh

# Source zshrc
source ~/.zshrc

# Logging
echo "Current user: $(whoami)"
echo "Script started at $(date)"

# Homebrew Path for Intel Macs
HOMEBREW_PATH="/usr/local/bin"
HOMEBREW_SBIN="/usr/local/sbin"
SCRIPT_DIR="/Users/$(whoami)/New-Setup"
WALLPAPER_BACKUP_DIR="${SCRIPT_DIR}"
TIMESTAMP_FILE="${SCRIPT_DIR}/last_wallpaper_change.txt"

# Ensuring Homebrew paths are always correct and available
export PATH="$HOMEBREW_PATH:$HOMEBREW_SBIN:$PATH"

# Navigate to script directory
cd $SCRIPT_DIR

# Create the timestamp file if it doesn't exist
if [ ! -f "$TIMESTAMP_FILE" ]; then
    touch "$TIMESTAMP_FILE"
    echo "0" > "$TIMESTAMP_FILE"

    # Git commit for creation of last_wallpaper_change.txt file
    git add "$TIMESTAMP_FILE"
    git commit -m "Create timestamp file for wallpaper changes"
fi

# Get timestamp of last wallpaper change
last_change_timestamp=$(cat "$TIMESTAMP_FILE")

# Get path of current desktop wallpaper using osascript
wallpaper_path=$(osascript -e 'tell application "System Events" to tell current desktop to get picture' 2>/dev/null) 

if [ -z "$wallpaper_path" ]; then
    echo "No wallpaper change detected."
else
    echo "Wallpaper path: $wallpaper_path"
    
    # Current modification time of desktop wallpaper
    current_timestamp=$(stat -f "%m" "$wallpaper_path" 2>/dev/null)

    # Check if wallpaper has been changed
    if [ "$last_change_timestamp" != "$current_timestamp" ]; then
        # Copy original file to backup directory and rename to Desktop.png
        cp "$wallpaper_path" "$WALLPAPER_BACKUP_DIR" || { echo "Failed to copy wallpaper"; exit 1; }
        new_wallpaper_path="${WALLPAPER_BACKUP_DIR}/Desktop.png"
        mv "${WALLPAPER_BACKUP_DIR}/$(basename "$wallpaper_path")" "$new_wallpaper_path" || { echo "Failed to rename wallpaper"; exit 1; }

        # Update timestamp of last wallpaper change
        echo "$current_timestamp" > "$TIMESTAMP_FILE"
        
        # Add new wallpaper to git
        git add "$new_wallpaper_path"
    fi
fi

# Diagnose potential issues with the Homebrew installation
brew doctor

# Update Homebrew
brew update

# Check for outdated packages
brew outdated

# Upgrade Homebrew packages
brew upgrade

# Upgrade cask applications
brew upgrade --cask

# Cleanup Homebrew packages
brew cleanup

# Run the brew bundle dump
brew bundle dump --describe --force

# Run Mackup
mackup backup --force
mackup uninstall --force

# Git commit for Brewfile
if git status --porcelain | grep .; then
    git add .
    git commit -m "Auto-update"
    git push
else
    echo "No changes to commit"
fi
