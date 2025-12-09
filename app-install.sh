#!/bin/bash

# Configuration
INSTALL_DIR="$HOME/ArduinoApps"
mkdir -p "$INSTALL_DIR"

# 1. DOWNLOAD
# ------------------------------------------------
echo "🔍 Searching for the latest release on GitHub..."
ZIP_URL=$(curl -s "https://api.github.com/repos/akash73/arduino-uno-q-apps/releases/latest" | \
grep '"browser_download_url": "[^"]*\.zip"' | \
cut -d'"' -f4 | head -n1)

if [ -z "$ZIP_URL" ]; then
    echo "❌ Error: No zip file found in the latest release."
    exit 1
fi

ZIP_NAME=$(basename "$ZIP_URL")
echo "⬇️  Downloading: $ZIP_NAME"

cd /tmp
rm -f app.zip 
curl -sL "$ZIP_URL" -o app.zip

echo "📦 Extracting files..."
unzip -q app.zip
rm -f app.zip

# Find the extracted folder
EXTRACTED_DIR=$(ls -d arduino-uno-q-apps-*)
cd "$EXTRACTED_DIR" || exit 1

# 2. INTERACTIVE SELECTION
# ------------------------------------------------

# Get list of subdirectories (apps)
APPS=($(ls -d */ 2>/dev/null | sed 's/\///'))

if [ ${#APPS[@]} -eq 0 ]; then
    echo "⚠️  No applications found inside the package ($EXTRACTED_DIR)."
    # Debug info: list content to see what went wrong
    ls -la
    exit 1
fi

echo ""
echo "========================================="
echo "   AVAILABLE APPLICATIONS"
echo "========================================="
i=1
for app in "${APPS[@]}"; do
    echo "[$i] $app"
    ((i++))
done
echo "========================================="
echo "Enter the numbers of the apps you want to install, separated by spaces."
echo "Example: 1 3 (to install the first and third apps)"
echo "Or type 'all' to install them all."
echo ""

# FIX: Force reading from terminal even if script is piped
if [ -t 0 ]; then
    read -p "Selection: " SELECTION
else
    # Fallback for curl | bash usage
    read -p "Selection: " SELECTION < /dev/tty
fi

APPS_TO_INSTALL=()

if [ "$SELECTION" == "all" ]; then
    APPS_TO_INSTALL=("${APPS[@]}")
else
    for index in $SELECTION; do
        if [[ "$index" =~ ^[0-9]+$ ]] && [ "$index" -ge 1 ] && [ "$index" -le "${#APPS[@]}" ]; then
            REAL_INDEX=$((index-1))
            APPS_TO_INSTALL+=("${APPS[$REAL_INDEX]}")
        fi
    done
fi

if [ ${#APPS_TO_INSTALL[@]} -eq 0 ]; then
    echo "❌ No valid selection. Exiting without installing anything."
    # Cleanup
    cd ..
    rm -rf "$EXTRACTED_DIR"
    exit 0
fi

# 3. INSTALLATION
# ------------------------------------------------
echo ""
echo "🚀 Installation in progress at: $INSTALL_DIR"

for app_name in "${APPS_TO_INSTALL[@]}"; do
    DEST_PATH="$INSTALL_DIR/$app_name"
    
    if [ -d "$DEST_PATH" ]; then
        echo "   Updating $app_name (overwriting)..."
        rm -rf "$DEST_PATH"
    else
        echo "   Installing $app_name..."
    fi
    
    mv "$app_name" "$INSTALL_DIR/"
done

# 4. FINAL CLEANUP
# ------------------------------------------------
cd ..
rm -rf "$EXTRACTED_DIR"

echo ""
echo "✅ Operation completed! Selected apps are located in $INSTALL_DIR"
