# OneKeyMount

> An interactive Bash script to safely mount unmounted disks on Linux.

[![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Linux-blue)](#)

OneKeyMount is a simple, interactive script that helps you mount disks on Linux without manually dealing with `parted`, `mkfs`, `blkid`, or `/etc/fstab`. It scans for unmounted disks, shows detailed information, and guides you through the entire process.

## Features

- Automatically detects unmounted disks (`sd`, `vd`, `nvme`, `mmcblk`)
- Displays disk size, partitions, filesystem type, and mount status
- Two operation modes:
  - **Mode 1:** Mount an existing partition without formatting (keeps data)
  - **Mode 2:** Wipe the disk, create a GPT partition table, format as ext4, and mount (erases all data)
- Automatically backs up `/etc/fstab` before making changes
- Writes a UUID-based entry to `/etc/fstab` for persistent mounting
- Colorized interactive prompts with input validation
- Checks for root privileges and mount-point conflicts

## Supported Systems

- Linux with Bash 4+
- Tested on Debian/Ubuntu, CentOS/RHEL, and ARM boards (Raspberry Pi, Hinlink, etc.)
- Requires the following tools:
  - `parted`
  - `lsblk`
  - `blkid`
  - `mount`
  - `mkfs.ext4`

Install missing dependencies:

```bash
# Debian/Ubuntu
sudo apt update && sudo apt install -y parted util-linux e2fsprogs

# CentOS/RHEL
sudo yum install -y parted util-linux e2fsprogs
```

## Installation

```bash
git clone https://github.com/yourusername/OneKeyMount.git
cd OneKeyMount
chmod +x mount_disk.sh
```

## Usage

Run the script as root:

```bash
sudo ./mount_disk.sh
```

Follow the interactive prompts:

1. **Select a disk** – choose from the list of unmounted disks.
2. **Choose operation mode** – `1` for mounting an existing partition, `2` for wiping and reformatting.
3. **Enter a mount directory** – e.g., `/data` or `/mnt/storage`.
4. **Confirm** – type `yes` to proceed.

The script will then partition, format, mount, and update `/etc/fstab` automatically.

### Example

```text
=== Step 1: Select disk ===
Scanning for unmounted disks...
Found 1 unmounted disk:

[1] /dev/sdb
  sdb      100G disk
  └─sdb1   100G part ext4

Enter disk number: 1

=== Step 2: Select operation mode ===
Disk /dev/sdb has 1 partition.
  1) Mount existing partition (keep data)
  2) Wipe and reformat (⚠️ data loss)
Choose (1 or 2): 1

=== Step 3: Enter mount directory ===
Mount directory: /data

=== Step 4: Confirm ===
Disk: /dev/sdb (100G)
Mount directory: /data
Operation: Mount existing partition /dev/sdb1 (data preserved)

Type 'yes' to continue: yes
...
✓ Mounted successfully: /dev/sdb1 -> /data
✓ Entry added to /etc/fstab
```

## Important Notes

- **Mode 2 erases all data on the selected disk.** Always back up important data first.
- The script creates a backup of `/etc/fstab` at `/etc/fstab.backup.YYYYMMDD_HHMMSS`.
- After completion, test the fstab configuration with:
  ```bash
  sudo mount -a
  ```
- **Do not reboot** if `/etc/fstab` contains errors, or the system may fail to boot.
- This script currently formats partitions as `ext4` only. Other filesystems are not supported.

## Project Structure

```
OneKeyMount/
├── mount_disk.sh   # Main script
├── README.md       # Documentation
└── LICENSE         # MIT License (optional)
```

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by the need for a beginner-friendly disk mounting tool on Linux.
- Thanks to all contributors and testers.
