#!/bin/bash

# -----------------------------
# Apple → External Drive Export
# -----------------------------

# 📂 CONFIGURATION
SRC="/Users/your-user-name/directory" #source for files that need backup.
DEST="/Volumes/BACKUP-GABE/photos" #destination where your external USB is mounted. 
LOGFILE="$HOME/rsync_backup_$(date +%Y%m%d_%H%M%S).log"
RSYNC_BIN="$(which rsync)"

# -----------------------------
# PRE-CHECKS
# -----------------------------

# Validate rsync
if [ -z "$RSYNC_BIN" ]; then
    echo "❌ rsync not found. Please install it using: brew install rsync"
    exit 1
fi

# Check source directory
if [ ! -d "$SRC" ]; then
    echo "❌ Source directory not found: $SRC"
    exit 1
fi

# Check destination drive is mounted
if [ ! -d "$(dirname "$DEST")" ]; then
    echo "❌ Destination base path not found: $(dirname "$DEST")"
    echo "💡 Make sure your external drive is mounted and visible under /Volumes"
    exit 1
fi

# Create DEST folder if missing
if [ ! -d "$DEST" ]; then
    echo "📁 Creating destination folder: $DEST"
    mkdir -p "$DEST"
fi

# -----------------------------
# BACKUP START
# -----------------------------

echo "🚀 Starting macOS → External Drive export"
echo "From: $SRC"
echo "To:   $DEST"
echo "Log:  $LOGFILE"
echo "------------------------------------------" | tee -a "$LOGFILE"

# The backup (skip already copied files)
"$RSYNC_BIN" -avh --progress --ignore-existing --update "$SRC"/ "$DEST"/ | tee -a "$LOGFILE"

# -----------------------------
# DONE
# -----------------------------

echo "✅ Export completed at $(date)" | tee -a "$LOGFILE"
