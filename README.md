# OneKeyMount

A safe, interactive Bash script for mounting unmounted block devices on Linux — with optional partitioning, formatting, and automatic `/etc/fstab` persistence.

![Shell](https://img.shields.io/badge/shell-bash-4EAA25?logo=gnu-bash&logoColor=white)
![Platform](https://img.shields.io/badge/platform-Linux-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![ShellCheck](https://img.shields.io/badge/shellcheck-passing-brightgreen)

> **中文文档：** [CREADME.md](CREADME.md)

---

## Table of Contents

- [Quick Start](#quick-start)
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

## Quick Start

```bash
git clone https://github.com/1724099107/OneKeyMount.git
cd OneKeyMount
chmod +x OneKeyMount.sh
sudo ./OneKeyMount.sh
```

That's it — the script will guide you through the rest and ask whether you want English or Chinese.

> **Language:** The script supports **English** and **Chinese** prompts. You will be asked to choose at startup.

---

## Features

- 🔍 **Auto-detects unmounted disks** — scans `sd*`, `vd*`, `nvme*`, `mmcblk*`, and `hd*` devices
- 🌐 **Bilingual interface** — English and Chinese prompts, selected at runtime
- 🧭 **Two operation modes**
  - **Mount existing partition** — preserves data, detects the real filesystem type
  - **Repartition & format** — wipes the disk, creates a GPT partition, and formats it as `ext4`
- 💾 **Persistent mounts** — automatically writes a `UUID=`-based entry to `/etc/fstab`
- 🛡️ **Safety first**
  - Requires root
  - Backs up `/etc/fstab` before every change
  - Refuses to mount on `/`, non-absolute paths, or directories inside an existing mount
  - Cleans stale `fstab` entries by UUID or mount point using field-exact matching
- 🧩 **Broad device support** — correct partition naming for `nvme*` and `mmcblk*` (`pN` suffix)
- 🎨 **Readable colored output** with interactive prompts and confirmation

---

## Requirements

- Linux with `bash` 4.0+ (for associative arrays)
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
| `udevadm`    | Wait for device node settlement (optional)|
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
git clone https://github.com/1724099107/OneKeyMount.git
cd OneKeyMount
chmod +x OneKeyMount.sh
```

Or download the script directly:

```bash
curl -fsSL -o OneKeyMount.sh https://raw.githubusercontent.com/1724099107/OneKeyMount/main/OneKeyMount.sh
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

### Example session (English)

```
Please select language / 请选择语言:
  1) English
  2) 中文
Choice / 选择 (1/2): 1

=== Step 1: Select a disk to mount ===
Scanning for unmounted disks...
Found 1 unmounted disk(s):

[1] /dev/sdb
Disk /dev/sdb:
  NAME   SIZE TYPE FSTYPE MOUNTPOINT
  sdb    100G disk
  └─sdb1 100G part ext4

Please select the disk to operate on (1-1):
Enter number: 1

=== Step 2: Select operation mode ===
Disk /dev/sdb has 1 existing partition(s)
  1) Mount an existing partition (keep data)
  2) Wipe, repartition and format (WARNING: all data will be lost)

Select operation mode (1 or 2): 1

=== Step 3: Enter mount directory ===
Mount directory path (e.g. /data, /mnt/storage): /data

=== Step 4: Confirm operation ===
About to perform the following:
  Disk: /dev/sdb (100G)
  Mount point: /data
  Action: Mount existing partition /dev/sdb1 (data preserved)

Confirm and continue? (type 'yes' to proceed): yes

=== Step 5: Executing ===
Backed up /etc/fstab to: /etc/fstab.backup.20250101_120000
Mounting partition...
Mount success: /dev/sdb1 -> /data
Written to /etc/fstab (fstype=ext4)

=== Operation completed ===
Mount information:
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdb1        98G   24K   93G   1% /data

Disk partition information:
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sdb      8:16   0  100G  0 disk
└─sdb1   8:17   0  100G  0 part /data

fstab configuration:
UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx /data ext4 defaults,noatime 0 0

Disk sdb has been mounted to /data
Hint: run 'mount -a' to verify the fstab configuration
Hint: fstab backup file: /etc/fstab.backup.20250101_120000
```

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

| Device pattern | Partition name   |
|----------------|------------------|
| `/dev/sdX`     | `/dev/sdX1`      |
| `/dev/vdX`     | `/dev/vdX1`      |
| `/dev/hdX`     | `/dev/hdX1`      |
| `/dev/nvmeXnY` | `/dev/nvmeXnYp1` |
| `/dev/mmcblkX` | `/dev/mmcblkXp1` |

---

## Safety Notes

- ⚠️ **Data loss warning:** Mode 2 irreversibly destroys all data on the selected disk. Always double-check your target before typing `yes`.
- 💾 **Backups:** `/etc/fstab` is backed up to `/etc/fstab.backup.YYYYmmdd_HHMMSS` on every run, in both modes.
- ✅ **Verification:** After the script completes, validate the new `fstab` entry with:

  ```bash
  sudo mount -a
  ```

  If the command produces no output and exits successfully, the configuration is valid.
- 🔧 **Recovery:** If `/etc/fstab` becomes corrupted, restore from the backup file:

  ```bash
  sudo cp /etc/fstab.backup.YYYYmmdd_HHMMSS /etc/fstab
  ```
- 🛑 **Interrupts:** If you press `Ctrl+C`, the script aborts immediately. If you abort in Mode 2 during the partitioning step, re-run the script to complete the operation.

---

## Limitations

- Mode 2 formats new partitions as **ext4** only. Support for `xfs`, `btrfs`, and others is not yet implemented.
- Mode 1 mounts only the **first partition** found on the disk. Multi-partition disks require manual handling.
- Not designed for LVM, LUKS, RAID, or ZFS volumes.
- The script assumes the target disk is not in use by any LVM/RAID subsystem.
- Interactive prompts are bilingual (EN/ZH). Additional locales are on the roadmap.

---

## Roadmap

- [ ] Additional language packs (Japanese, Korean, …)
- [ ] Support `xfs` and `btrfs` for Mode 2
- [ ] Optional LVM volume creation
- [ ] Dry-run mode (`--dry-run`)
- [ ] Non-interactive mode for provisioning tools (Ansible, cloud-init)
- [x] `shellcheck` CI workflow
- [x] Bilingual interface (EN / ZH)

---

## Contributing

Issues and pull requests are welcome! Please:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Run `shellcheck OneKeyMount.sh` and fix any warnings
4. Commit your changes: `git commit -am 'Add my feature'`
5. Push to the branch: `git push origin feature/my-feature`
6. Open a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

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
