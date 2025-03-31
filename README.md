# apple-to-linux
If you need to transfer large directories with lots of files this worflow is for you. If you are exporting your photos, icloud or any files from IOS to Linux this will help you. 

Perfect! Here's a professional, GitHub-friendly, and fully styled version:

---

# 🍏 Apple-to-Linux Backup Toolkit

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE) ![Status](https://img.shields.io/badge/status-stable-blue) ![Linux](https://img.shields.io/badge/compatible-Linux%20%7C%20macOS-lightgrey)

Safely transfer large directories, photos, iCloud exports, and any large datasets (>4GB files) from Apple devices to Linux machines without file corruption or interruption.

---

## ✨ Features
- ✅ Supports APFS-formatted drives (Apple File System)
- ✅ Handles large files (>4GB) natively
- ✅ Crash-resilient
- ✅ Automatically flushes memory to prevent system freezes
- ✅ Progress and ETA in terminal
- ✅ Resume-friendly (`rsync --append-verify`)
- ✅ Beginner-friendly step-by-step guide

---

## 📂 Official Repository
The official repository and latest scripts are available at:

➡️ [MantleKey GitHub](https://github.com/mantlekey/apple-to-linux) ← *replace with your actual link*

---

## 📋 Table of Contents
1. [Requirements](#requirements)
2. [Step 1 - Setup on macOS](#step-1---setup-on-macos)
3. [Step 2 - Setup on Linux](#step-2---setup-on-linux)
4. [Step 3 - Compile apfs-fuse](#step-3---compile-apfs-fuse)
5. [Step 4 - Prepare External Drive](#step-4---prepare-external-drive)
6. [Step 5 - Run the Script](#step-5---run-the-script)
7. [Recommended Workflow (macOS → External → Linux)](#recommended-workflow)
8. [Notes](#notes)

---

## ✅ Requirements

| Dependency | macOS | Linux |
|------------|-------|-------|
| `rsync` | ✔️ | ✔️ |
| `findutils` | ✔️ | ✔️ |
| `coreutils` | ✔️ | Optional |
| `apfs-fuse` | ❌ | ✔️ |
| `gcc`, `make`, `cmake`, `fuse-devel` | ❌ | ✔️ |

---

## 🟣 Step 1: Install Dependencies on macOS

1️⃣ Install Homebrew

Homebrew is the package manager for macOS and is used to install the required software packages, like rsync. Run the following command to install Homebrew:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2️⃣ Install rsync

Once Homebrew is installed, run this command to install rsync, which will be used for the backup:

```bash
brew install rsync
```

3️⃣ Verify Installation

Check if rsync is installed correctly by running:

```bash
rsync --version
```

You should see the version number of rsync. If you see errors like Error: No such file or directory - getcwd, make sure you’re in a valid directory (run cd ~ to go to your home directory), and retry the installation.
---

## 🟣 Step 2 - Setup on Linux

### Rocky Linux 8

```bash
sudo dnf install rsync findutils util-linux gcc make cmake \
                 fuse3-devel git zlib-devel bzip2-devel
```
### Ubuntu 24

```bash
sudo apt update
sudo apt install rsync findutils util-linux build-essential cmake \
                 libfuse3-dev git zlib1g-dev libbz2-dev
```

---

## 🟣 Step 3 - Compile `apfs-fuse` on Linux

### Only move to step 3 after all the pakcages are installed. 

```bash

git clone https://github.com/sgan81/apfs-fuse.git
cd apfs-fuse

# Initialize and update submodules
git submodule update --init --recursive

# Create a separate build directory
mkdir build
cd build

# Generate build files with CMake
cmake ..

# Build apfs-fuse
make

# Install apfs-fuse
sudo make install

```

### ✅ Verify:

```bash
apfs-fuse --help
```

---

## 🟣 Step 4 - Prepare External Drive

### Find the drive:

```bash
lsblk -o NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINT
```

Look for:
- Your device (e.g., `/dev/sda1`)
- Check that it is unmounted (`MOUNTPOINT` is empty)

### Confirm APFS:

```bash
sudo file -s /dev/sdX1
```

Expected output:

```
Apple File System (APFS)
```

Mount Drive

```bash
sudo apfs-fuse -o allow_other,uid=1000,gid=1000 /dev/sdxx /mnt/your-directory
```
---

## 🟣 Step 5 - Run the Script

1️⃣ Clone the script from [MantleKey GitHub]([https://github.com/mantlekey/apple-to-linux-backup](https://github.com/mantlekey/apple-to-linux))

2️⃣ Make it executable:

```bash
chmod +x apple_backup.sh
```

3️⃣ (Optional) Adjust parameters:

```bash
FLUSH_INTERVAL=500
SAFE_MIN_FREE_MEM_MB=8192
DEST="/home/youruser/Documents/icloud"
```

4️⃣ Start the transfer:

```bash
sudo ./apple_backup.sh
```

---

## ✅ Recommended Workflow (macOS → External → Linux)

**Scenario**: You want 100% compatibility, even for Apple-specific files

1️⃣ On macOS:
```bash
rsync -ah --progress --partial --append-verify ~/Pictures /Volumes/YourAPFSDrive/
```

2️⃣ Unplug the external drive, connect to your Linux machine.

3️⃣ Use this repository's script to backup into your Linux system.

This method gives you:
- Native Apple support during the first copy
- Fast rsync transfer on Linux
- Full Unicode and Apple attributes properly handled by macOS itself

---

## 🟣 Notes

- APFS is recommended for drives used between macOS and Linux (via `apfs-fuse`)
- Avoid using FAT32 for large (>4GB) files
- For extremely large folders, increase:
    - `FLUSH_INTERVAL`
    - `SAFE_MIN_FREE_MEM_MB`
- Interrupting the script is safe (`rsync --append-verify`)
- Logs are saved in:
    ```
    ~/apfs-backup/logs/
    ```
### Here are a couple of basic **apfs-fuse** usage examples with explanations you can include in your README:

---

#### Basic Mount

```bash
sudo apfs-fuse -o allow_other,uid=1000,gid=1000 /dev/sdxx /mnt/your-directory

```

- **apfs-fuse** is the command provided by the FUSE driver for Apple APFS.
- **`/dev/sdxx`** is the APFS partition you want to mount.  
- **`/mnt/your-directory`** is your chosen mount point.

### Mount with Allowing Other Users to Access the Filesystem

```bash
sudo apfs-fuse -o allow_other /dev/sdxx /mnt/your-directory
```

Explanation:

    allow_other: Permits all users on the system to access files within this mount.

    uid=1000,gid=1000: Sets the numeric user ID and group ID as the owner of all files. Replace 1000:1000 with the actual UID:GID of the user who should own the files (you can find it by running id username).

---

**Notes**:

1. **Mounting via `mount -t apfs`** does **not** work with apfs-fuse because it’s a FUSE driver, not a kernel module. Always use the **`apfs-fuse`** command directly.
2. Depending on how **apfs-fuse** was compiled, write support may be incomplete or disabled. You may need to confirm the read/write capabilities in your specific environment.
3. Unmounting is handled with **`fusermount -u /mnt/your-directory`** (on most Linux distributions) or **`umount /mnt/your-directory`** in some cases. 
4. Ensure the **fuse** module is loaded (generally it’s loaded by default on modern distributions).

Feel free to adjust paths and device names to match your environment.

---

## Contribute
Feel free to fork and improve! PRs are welcome.

