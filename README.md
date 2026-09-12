# OneKeyMount

A safe, interactive Bash script for mounting unmounted block devices on Linux — with optional partitioning, formatting, and automatic `/etc/fstab` persistence.

![Shell](https://img.shields.io/badge/shell-bash-4EAA25?logo=gnu-bash&logoColor=white)
![Platform](https://img.shields.io/badge/platform-Linux-blue)
![License](https://img.shields.io/badge/license-MIT-green)

---

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [How It Works](#how-it-works)
- [Safety Notes](#safety-notes)
- [Limitations](#limitations)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)
- [Disclaimer](#disclaimer)

---

## Features

- 🔍 **Auto-detects unmounted disks** — scans `sd*`, `vd*`, `nvme*`, `mmcblk*`, and `hd*` devices
- 🧭 **Two operation modes**
  - **Mount existing partition** — preserves data, detects the real filesystem type
  - **Repartition & format** — wipes the disk, creates a GPT partition, and formats it as `ext4`
- 💾 **Persistent mounts** — automatically writes a `UUID=`-based entry to `/etc/fstab`
- 🛡️ **Safety first**
  - Requires root
  - Backs up `/etc/fstab` before every change
  - Refuses to mount on `/` or non-absolute paths
  - Cleans stale `fstab` entries by UUID or mount point
- 🧩 **Broad device support** — correct partition naming for `nvme*` and `mmcblk*` (`pN` suffix)
- 🎨 **Readable colored output** with interactive prompts and confirmations

---

## Requirements

- Linux with `bash` 4.0+
- Root privileges (or `sudo`)
- The following utilities available in `$PATH`:

| Tool         | Purpose                                   |
|--------------|-------------------------------------------|
| `lsblk`      | Enumerate block devices                   |
| `parted`     | Create partition tables                   |
| `blkid`      | Read UUID / filesystem type               |
| `findmnt`    | Detect mount status by source device      |
| `mountpoint` | Verify a directory is a mount point       |
| `partprobe`  | Re-read the partition table               |
| `udevadm`    | Wait for device node settlement           |
| `mkfs.ext4`  | Format new partitions                     |
| `awk`, `sed`, `grep` | Text processing                   |

### Install dependencies

**Debian / Ubuntu**

```bash
sudo apt-get update
sudo apt-get install -y parted util-linux e2fsprogs
```

**RHEL / CentOS / Fedora**

```bash
sudo dnf install -y parted util-linux e2fsprogs
```

**Arch Linux**

```bash
sudo pacman -S parted util-linux e2fsprogs
```

---

## Installation

Clone the repository:

```bash
git clone https://github.com/<your-username>/OneKeyMount.git
cd OneKeyMount
chmod +x OneKeyMount.sh
```

Or download the script directly:

```bash
curl -fsSL -o OneKeyMount.sh https://raw.githubusercontent.com/<your-username>/OneKeyMount/main/OneKeyMount.sh
chmod +x OneKeyMount.sh
```

---

## Usage

Run the script as **root**:

```bash
sudo ./OneKeyMount.sh
```

The script walks through five interactive steps:

1. **Select a disk** — from the list of unmounted block devices
2. **Choose an operation mode**
   - `1` — Mount an existing partition (data preserved)
   - `2` — Wipe, partition, format, and mount (**destructive**)
3. **Enter a mount directory** — e.g. `/data` or `/mnt/storage`
4. **Confirm** — type `yes` to proceed
5. **Done** — the script mounts the device and appends an `fstab` entry

### Example session

```
=== 步骤 1: 选择要挂载的磁盘 ===
正在扫描未挂载的磁盘...
找到 1 个未挂载的磁盘:

[1] /dev/sdb
磁盘 /dev/sdb:
  NAME   SIZE TYPE FSTYPE MOUNTPOINT
  sdb    100G disk
  └─sdb1 100G part ext4

请选择要操作的磁盘编号 (1-1):
输入编号: 1

=== 步骤 2: 选择操作方式 ===
检测到磁盘 /dev/sdb 已有 1 个分区
  1) 挂载现有分区（不格式化，保留数据）
  2) 清空并重新分区格式化（⚠️ 将丢失所有数据）

请选择操作方式 (1 或 2): 1

=== 步骤 3: 输入挂载目录 ===
请输入挂载目录路径 (例如: /data, /mnt/storage): /data

=== 步骤 4: 确认操作 ===
即将执行以下操作:
  磁盘: /dev/sdb (100G)
  挂载目录: /data
  操作: 挂载现有分区 /dev/sdb1（数据保留）

确认继续? (输入 yes 继续): yes

=== 步骤 5: 执行操作 ===
已备份 /etc/fstab 到: /etc/fstab.backup.20250101_120000
挂载现有分区 /dev/sdb1...
✓ 挂载成功: /dev/sdb1 -> /data
✓ 已写入 /etc/fstab (fstype=ext4)

=== 操作完成 ===
✓ 磁盘 sdb 已成功挂载到 /data
```

> **Note:** The interactive prompts are currently in Chinese. Contributions to add i18n support are welcome — see the [Roadmap](#roadmap).

---

## How It Works

### Mode 1 — Mount an existing partition

1. Removes any stale `/etc/fstab` entry targeting the same mount point
2. Creates the mount directory if it does not exist
3. Mounts the first partition on the disk
4. Reads the partition's **UUID** and real **filesystem type** via `blkid`
5. Appends a line to `/etc/fstab`:

   ```
   UUID=<uuid> <mount_dir> <fstype> defaults,noatime 0 0
   ```

### Mode 2 — Repartition and format

1. Unmounts any partitions currently on the disk
2. Removes stale `/etc/fstab` entries by UUID and mount point
3. Backs up `/etc/fstab`
4. Wipes signatures (`wipefs`), then creates a fresh **GPT** table
5. Creates a single partition spanning the whole disk
6. Formats it as **ext4**
7. Mounts it and appends the `fstab` entry

### Device naming rules

| Device pattern | Partition name |
|----------------|----------------|
| `/dev/sdX`     | `/dev/sdX1`    |
| `/dev/vdX`     | `/dev/vdX1`    |
| `/dev/hdX`     | `/dev/hdX1`    |
| `/dev/nvmeXnY` | `/dev/nvmeXnYp1` |
| `/dev/mmcblkX` | `/dev/mmcblkXp1` |

---

## Safety Notes

- ⚠️ **Data loss warning:** Mode 2 irreversibly destroys all data on the selected disk. Always double-check your target before typing `yes`.
- 💾 **Backups:** `/etc/fstab` is backed up to `/etc/fstab.backup.YYYYmmdd_HHMMSS` on every run.
- ✅ **Verification:** After the script completes, validate the new `fstab` entry with:

  ```bash
  sudo mount -a
  ```

  If the command produces no output and exits successfully, the configuration is valid.
- 🔧 **Recovery:** If `/etc/fstab` becomes corrupted, boot into rescue mode or use a live USB and restore from the backup file:

  ```bash
  sudo cp /etc/fstab.backup.YYYYmmdd_HHMMSS /etc/fstab
  ```

---

## Limitations

- The script currently only formats new partitions as **ext4**. Support for `xfs`, `btrfs`, and other filesystems is not yet implemented.
- Only the **first partition** is mounted in Mode 1. Multi-partition disks require manual handling.
- Not designed for LVM, LUKS, RAID, or ZFS volumes.
- The script uses `parted` and assumes the target disk is not in use by any LVM/RAID subsystem.
- Interactive prompts are currently Chinese-only.

---

## Roadmap

- [ ] Add i18n / English prompts
- [ ] Support `xfs` and `btrfs` for Mode 2
- [ ] Optional LVM volume creation
- [ ] Dry-run mode (`--dry-run`)
- [ ] Non-interactive mode for provisioning tools (Ansible, cloud-init)
- [ ] `shellcheck` CI workflow

---

## Contributing

Issues and pull requests are welcome! Please:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Run `shellcheck OneKeyMount.sh` and fix any warnings
4. Commit your changes: `git commit -am 'Add my feature'`
5. Push to the branch: `git push origin feature/my-feature`
6. Open a Pull Request

### Code style

- POSIX-friendly `bash` where possible
- Quote all variable expansions: `"$var"`
- Prefer `[[ ]]` over `[ ]`
- Use `set -euo pipefail`
- Keep functions small and self-documenting
- No trailing whitespace; use LF line endings

---

## License

This project is licensed under the [MIT License](LICENSE).

---

## Disclaimer

This script performs **destructive disk operations** when Mode 2 is selected. The authors are not responsible for any data loss or system damage caused by its use. **Always review the script and back up your data before running it.**

---

## Acknowledgements

Built with standard Linux utilities — no external dependencies beyond what ships with a typical distribution.
