#!/bin/bash

# -----------------------------
# CONFIGURATION
# -----------------------------

USER_HOME="/home/your-user-name"
MOUNT_BASE="$USER_HOME/mounts"
LOG_BASE="$USER_HOME/apfs-backup/logs"
DEST="$USER_HOME/your-destination/"
APFS_FUSE="/usr/local/bin/apfs-fuse"
FLUSH_INTERVAL=100         # Flush every 100 files (safer for large RAM)
SAFE_MIN_FREE_MEM_MB=16384 # Trigger flush if less than 16GB free
ENABLE_FLUSH=true
RSYNC_NICENESS=15
mkdir -p "$LOG_BASE"

DATE=$(date +%Y%m%d_%H%M%S)
LOGFILE="$LOG_BASE/backup_$DATE.log"
CSVLOG="$LOG_BASE/backup_$DATE.csv"

# -----------------------------
# UTILITY FUNCTIONS
# -----------------------------

info() { echo -e "\e[35m$1\e[0m"; }
success() { echo -e "\e[32m$1\e[0m"; }
warn() { echo -e "\e[33m$1\e[0m"; }
error() { echo -e "\e[31m$1\e[0m"; }

check_memory_and_flush() {
    local free_mem=$(awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo)
    if (( free_mem < SAFE_MIN_FREE_MEM_MB )); then
        warn "⚡ Free RAM critically low (${free_mem}MB). Flushing page cache."
        sudo sh -c 'sync; echo 1 > /proc/sys/vm/drop_caches'
    fi
}

# -----------------------------
# STEP 1: MANUAL DEVICE SELECTION
# -----------------------------

info "🔍 Available block devices:"
lsblk -pn -o NAME,SIZE,TYPE,MOUNTPOINT

echo ""
read -p "👉 Enter the full device path you want to mount (e.g., /dev/sda1): " DEVICE

if [ ! -b "$DEVICE" ]; then
    error "❌ Invalid block device."
    exit 1
fi

read -p "⚠️  Confirm you are sure this is an APFS partition? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    error "❌ Aborted by user."
    exit 1
fi

success "✅ Selected device: $DEVICE"

# -----------------------------
# STEP 2: Mount
# -----------------------------

MOUNTPOINT="$MOUNT_BASE/manual_apfs"

if grep -qs "$MOUNTPOINT" /proc/mounts; then
    success "✅ Device is already mounted at $MOUNTPOINT"
else
    info "📂 Creating mountpoint: $MOUNTPOINT"
    mkdir -p "$MOUNTPOINT"
    info "🔄 Mounting $DEVICE as APFS"
    sudo "$APFS_FUSE" -o allow_other,uid=$(id -u),gid=$(id -g),ro "$DEVICE" "$MOUNTPOINT" || {
        error "❌ Mount failed. Exiting."
        exit 1
    }
    success "✅ Mounted successfully."
fi

# -----------------------------
# STEP 3: Backup Setup
# -----------------------------

mkdir -p "$DEST"

info "\n🚀 Starting crash-safe backup"
echo "Source       : $MOUNTPOINT"
echo "Destination  : $DEST"
echo "CSV Log      : $CSVLOG"
echo "Full Log     : $LOGFILE"

echo "timestamp,action,relative_path,size(bytes)" > "$CSVLOG"

# -----------------------------
# STEP 4: SAFE BATCHED RSYNC
# -----------------------------

FILE_COUNTER=0

for sub in "$MOUNTPOINT"/*; do
    if [ -d "$sub" ] || [ -f "$sub" ]; then
        info "\n📦 Copying $(basename "$sub") ..."

        ionice -c2 -n7 nice -n $RSYNC_NICENESS rsync -ah --partial --append-verify --no-inc-recursive --ignore-existing --info=progress2 --out-format="%t,%o,%n,%l" "$sub" "$DEST"/ | tee -a "$LOGFILE"

        FILE_COUNTER=$((FILE_COUNTER + 1))

        if [ "$ENABLE_FLUSH" = true ] && (( FILE_COUNTER % FLUSH_INTERVAL == 0 )); then
            info "\n🟣 Flushing Linux page cache after $FILE_COUNTER batches..."
            sudo sh -c 'sync; echo 1 > /proc/sys/vm/drop_caches'
        fi
    fi

done

success "\n✅ rsync finished."

# -----------------------------
# STEP 5: Final Cache Flush
# -----------------------------

if [ "$ENABLE_FLUSH" = true ]; then
    info "🟣 Final cache flush..."
    sudo sh -c 'sync; echo 1 > /proc/sys/vm/drop_caches'
fi

# -----------------------------
# STEP 6: Report
# -----------------------------

COPIED_FILES=$(grep ',send,' "$LOGFILE" | wc -l)
SKIPPED_FILES=$(grep ',recv,' "$LOGFILE" | wc -l)
TOTAL_SIZE=$(grep ',send,' "$LOGFILE" | awk -F',' '{s+=$4} END {print s}')

echo ""
echo "--------------------------------------------"
success "✅ Backup completed safely"
echo "📄 Files copied: $COPIED_FILES"
echo "📄 Files skipped: $SKIPPED_FILES"
echo "💾 Total copied size: $(numfmt --to=iec $TOTAL_SIZE)B"
echo "🟣 Log File: $LOGFILE"
echo "--------------------------------------------"

