#!/bin/bash

# Configuration
INSTALL_DIR="$HOME/ArduinoApps"
mkdir -p "$INSTALL_DIR"

# Check if whiptail is installed
if ! command -v whiptail &> /dev/null; then
    echo "❌ Error: 'whiptail' is required for the GUI."
    echo "Please install it (e.g., sudo apt install whiptail) or use the previous script."
    exit 1
fi

# 1. DOWNLOAD
# ------------------------------------------------
# Using a gauge to show progress (purely cosmetic/fake progress for UI feel)
{
    echo 10; sleep 1
    echo 30; sleep 1
    echo 50; 
} | whiptail --gauge "Searching and preparing download..." 6 50 0

ZIP_URL=$(curl -s "https://api.github.com/repos/akash73/arduino-uno-q-apps/releases/latest" | \
grep '"browser_download_url": "[^"]*\.zip"' | \
cut -d'"' -f4 | head -n1)

if [ -z "$ZIP_URL" ]; then
    whiptail --title "Error" --msgbox "No zip file found in the latest release." 8 45
    exit 1
fi

ZIP_NAME=$(basename "$ZIP_URL")

# Download with visual feedback is hard with curl inside whiptail, 
# so we drop to terminal for the heavy lifting then clear.
echo "⬇️  Downloading $ZIP_NAME..."
cd /tmp
rm -f app.zip 
curl -sL "$ZIP_URL" -o app.zip

echo "📦 Extracting files..."
unzip -q app.zip
rm -f app.zip

# Find the extracted folder
EXTRACTED_DIR=$(ls -d arduino-uno-q-apps-*)
cd "$EXTRACTED_DIR" || exit 1

# 2. INTERACTIVE SELECTION (GUI)
# ------------------------------------------------

# Get list of subdirectories
APPS=($(ls -d */ 2>/dev/null | sed 's/\///'))

if [ ${#APPS[@]} -eq 0 ]; then
    whiptail --title "Error" --msgbox "No applications found inside the package." 8 45
    exit 1
fi

# Prepare arguments for whiptail checklist
# Format: "Tag" "Description" "Status"
MENU_ARGS=()
for app in "${APPS[@]}"; do
    MENU_ARGS+=("$app" "" "OFF") 
done

# Show the Checklist Dialog
# 3>&1 1>&2 2>&3 is magic to redirect whiptail output (stderr) to a variable
SELECTION=$(whiptail --title "App Installer" \
                     --checklist "Select the applications to install:\n(Press SPACE to select, ENTER to confirm)" \
                     20 70 10 \
                     "${MENU_ARGS[@]}" \
                     3>&1 1>&2 2>&3)

# Check if user cancelled (Exit status != 0)
if [ $? -ne 0 ]; then
    echo "User cancelled."
    cd ..
    rm -rf "$EXTRACTED_DIR"
    exit 0
fi

# Remove quotes from the result (whiptail returns "App1" "App2")
SELECTION_CLEAN=$(echo "$SELECTION" | tr -d '"')

if [ -z "$SELECTION_CLEAN" ]; then
    whiptail --title "Warning" --msgbox "No applications selected." 8 45
    cd ..
    rm -rf "$EXTRACTED_DIR"
    exit 0
fi

# 3. INSTALLATION
# ------------------------------------------------
# Convert string to array
read -r -a APPS_TO_INSTALL <<< "$SELECTION_CLEAN"

# Progress bar loop
TOTAL=${#APPS_TO_INSTALL[@]}
CURRENT=0

for app_name in "${APPS_TO_INSTALL[@]}"; do
    # Calculate progress percentage
    PCT=$((CURRENT * 100 / TOTAL))
    
    # Send info to gauge
    echo "XXX"
    echo "$PCT"
    echo "Installing: $app_name"
    echo "XXX"

    DEST_PATH="$INSTALL_DIR/$app_name"
    
    if [ -d "$DEST_PATH" ]; then
        rm -rf "$DEST_PATH"
    fi
    
    mv "$app_name" "$INSTALL_DIR/"
    
    CURRENT=$((CURRENT + 1))
    sleep 0.5 # Just to let the user see the progress bar
done | whiptail --title "Installation in Progress" --gauge "Initializing..." 8 50 0

# 4. FINAL CLEANUP
# ------------------------------------------------
cd ..
rm -rf "$EXTRACTED_DIR"

whiptail --title "Success" --msgbox "Operation completed!\n\nApps installed in:\n$INSTALL_DIR" 10 60

clear
