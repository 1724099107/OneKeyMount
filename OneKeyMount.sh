#!/bin/bash
set -euo pipefail

# ============================================================
# OneKeyMount
# Interactive tool to mount unmounted disks on Linux
# Repository: https://github.com/1724099107/OneKeyMount
# License:    MIT
# ============================================================

# ---------- Colors ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ---------- i18n ----------
LANG_CHOICE=""

declare -A MSG_EN MSG_ZH

MSG_EN=(
    [lang_title]="Please select language"
    [lang_en]="1) English"
    [lang_zh]="2) Chinese"
    [lang_prompt]="Choice (1/2): "
    [lang_invalid]="Invalid choice"
    [root_required]="Please run this script as root"
    [missing_cmd]="Missing command: %s. Please install it first."
    [step1_title]="=== Step 1: Select a disk to mount ==="
    [scanning]="Scanning for unmounted disks..."
    [no_disks]="No unmounted disks detected"
    [all_disks]="Current status of all disks:"
    [found_disks]="Found %d unmounted disk(s):"
    [select_disk]="Please select the disk to operate on (1-%d):"
    [disk_label]="Disk"    
    [input_number]="Enter number: "
    [invalid_selection]="Invalid selection. Please enter a number between 1 and %d."
    [step2_title]="=== Step 2: Select operation mode ==="
    [existing_parts]="Disk %s has %d existing partition(s)"
    [mode1_desc]="  1) Mount an existing partition (keep data)"
    [mode2_desc]="  2) Wipe, repartition and format (WARNING: all data will be lost)"
    [mode_prompt]="Select operation mode (1 or 2): "
    [mode_invalid]="Invalid choice. Please enter 1 or 2."
    [no_parts_mode2]="Disk has no partitions. Will proceed with formatting."
    [step3_title]="=== Step 3: Enter mount directory ==="
    [mount_prompt]="Mount directory path (e.g. /data, /mnt/storage): "
    [mount_empty]="Mount directory cannot be empty"
    [mount_not_abs]="Mount directory must be an absolute path (start with /)"
    [mount_root_denied]="Mounting to / is not allowed"
    [mount_in_use]="Error: %s is already a mount point"
    [mount_subdir]="Error: %s is inside an existing mount. Please choose another directory."
    [mount_in_fstab]="Warning: %s already exists in /etc/fstab"
    [continue_ask]="Continue using this directory? (y/n): "
    [step4_title]="=== Step 4: Confirm operation ==="
    [about_to_exec]="About to perform the following:"
    [label_disk]="  Disk: %s (%s)"
    [label_mount]="  Mount point: %s"
    [label_mode1]="  Action: Mount existing partition %s (data preserved)"
    [label_mode2]="  Action: Wipe disk -> create partition -> format -> mount"
    [label_warn]="  WARNING: all data on the disk will be lost!"
    [confirm_prompt]="Confirm and continue? (type 'yes' to proceed): "
    [cancelled]="Operation cancelled"
    [step5_title]="=== Step 5: Executing ==="
    [backup_done]="Backed up /etc/fstab to: %s"
    [unmounting]="Unmounting existing partitions..."
    [unmounting_part]="  Unmounting: %s"
    [cleaning_fstab]="Cleaning stale /etc/fstab entries..."
    [removed_uuid]="  Removed UUID: %s"
    [removed_mount]="  Removed fstab entry for mount point: %s"
    [creating_parttable]="Creating partition table..."
    [waiting_part]="  Waiting for partition device..."
    [part_failed]="Partition creation failed: %s does not exist"
    [formatting]="Formatting partition..."
    [format_failed]="Formatting failed. Please check the device state."
    [creating_mount]="Creating mount directory: %s"
    [mounting]="Mounting partition..."
    [mount_failed]="Mount failed. Please check!"
    [mount_verify_failed]="Mount failed (mount point verification failed)"
    [uuid_failed]="Failed to obtain UUID or filesystem type"
    [mount_success]="Mount success: %s -> %s"
    [mount_success_uuid]="Mount success: UUID=%s -> %s"
    [fstab_written]="Written to /etc/fstab"
    [fstab_written_fs]="Written to /etc/fstab (fstype=%s)"
    [done_title]="=== Operation completed ==="
    [mount_info]="Mount information:"
    [disk_info]="Disk partition information:"
    [fstab_info]="fstab configuration:"
    [final_success]="Disk %s has been mounted to %s"
    [hint_mount_a]="Hint: run 'mount -a' to verify the fstab configuration"
    [hint_backup]="Hint: fstab backup file: %s"
    [err_trap]="Script exited with error at line %d"
    [interrupted]="Operation interrupted by user"
)

MSG_ZH=(
    [lang_title]="请选择语言"
    [lang_en]="1) English"
    [lang_zh]="2) 中文"
    [lang_prompt]="选择 (1/2): "
    [lang_invalid]="无效选择"
    [root_required]="请使用 root 用户运行此脚本"
    [missing_cmd]="缺少命令: %s，请先安装"
    [step1_title]="=== 步骤 1: 选择要挂载的磁盘 ==="
    [scanning]="正在扫描未挂载的磁盘..."
    [no_disks]="未检测到可用的未挂载磁盘"
    [all_disks]="当前所有磁盘状态:"
    [found_disks]="找到 %d 个未挂载的磁盘:"
    [select_disk]="请选择要操作的磁盘编号 (1-%d):"
    [disk_label]="磁盘"   
    [input_number]="输入编号: "
    [invalid_selection]="无效选择，请输入 1-%d 之间的数字"
    [step2_title]="=== 步骤 2: 选择操作方式 ==="
    [existing_parts]="检测到磁盘 %s 已有 %d 个分区"
    [mode1_desc]="  1) 挂载现有分区（不格式化，保留数据）"
    [mode2_desc]="  2) 清空并重新分区格式化（⚠️ 将丢失所有数据）"
    [mode_prompt]="请选择操作方式 (1 或 2): "
    [mode_invalid]="无效选择，请输入 1 或 2"
    [no_parts_mode2]="磁盘无分区，将进行格式化操作"
    [step3_title]="=== 步骤 3: 输入挂载目录 ==="
    [mount_prompt]="请输入挂载目录路径 (例如: /data, /mnt/storage): "
    [mount_empty]="挂载目录不能为空"
    [mount_not_abs]="挂载目录必须是绝对路径（以 / 开头）"
    [mount_root_denied]="不允许使用根目录 / 作为挂载目录"
    [mount_in_use]="错误: %s 已被挂载，请选择其他目录"
    [mount_subdir]="错误: %s 位于已挂载的文件系统内，请选择其他目录"
    [mount_in_fstab]="警告: %s 已在 /etc/fstab 中存在配置"
    [continue_ask]="是否继续使用此目录? (y/n): "
    [step4_title]="=== 步骤 4: 确认操作 ==="
    [about_to_exec]="即将执行以下操作:"
    [label_disk]="  磁盘: %s (%s)"
    [label_mount]="  挂载目录: %s"
    [label_mode1]="  操作: 挂载现有分区 %s（数据保留）"
    [label_mode2]="  操作: 清空磁盘 -> 创建分区 -> 格式化 -> 挂载"
    [label_warn]="  ⚠️ 所有数据将丢失！"
    [confirm_prompt]="确认继续? (输入 yes 继续): "
    [cancelled]="操作已取消"
    [step5_title]="=== 步骤 5: 执行操作 ==="
    [backup_done]="已备份 /etc/fstab 到: %s"
    [unmounting]="正在卸载旧分区..."
    [unmounting_part]="  卸载: %s"
    [cleaning_fstab]="清理 /etc/fstab 中的旧条目..."
    [removed_uuid]="  已删除 UUID: %s"
    [removed_mount]="  已从 fstab 移除挂载点条目: %s"
    [creating_parttable]="正在创建分区表..."
    [waiting_part]="  等待分区设备..."
    [part_failed]="分区创建失败: %s 不存在"
    [formatting]="正在格式化分区..."
    [format_failed]="✗ 格式化失败，请检查分区状态"
    [creating_mount]="创建挂载目录: %s"
    [mounting]="挂载分区..."
    [mount_failed]="✗ 挂载失败，请检查！"
    [mount_verify_failed]="✗ 挂载失败（挂载点校验未通过）"
    [uuid_failed]="无法获取分区 UUID 或文件系统类型"
    [mount_success]="✓ 挂载成功: %s -> %s"
    [mount_success_uuid]="✓ 挂载成功: UUID=%s -> %s"
    [fstab_written]="✓ 已写入 /etc/fstab"
    [fstab_written_fs]="✓ 已写入 /etc/fstab (fstype=%s)"
    [done_title]="=== 操作完成 ==="
    [mount_info]="挂载信息:"
    [disk_info]="磁盘分区信息:"
    [fstab_info]="fstab 配置:"
    [final_success]="✓ 磁盘 %s 已成功挂载到 %s"
    [hint_mount_a]="提示: 可以使用 'mount -a' 测试 fstab 配置是否正确"
    [hint_backup]="提示: fstab 备份文件: %s"
    [err_trap]="脚本在第 %d 行因错误退出"
    [interrupted]="操作被用户中断"
)

# Translate: print formatted message without trailing newline
t() {
    local key="$1"
    shift
    local template
    if [ "$LANG_CHOICE" = "zh" ]; then
        template="${MSG_ZH[$key]:-$key}"
    else
        template="${MSG_EN[$key]:-$key}"
    fi
    # shellcheck disable=SC2059
    printf "$template" "$@"
}

# Translate: print formatted message with trailing newline
say() {
    t "$@"
    echo
}

# ---------- Language selection ----------
select_language() {
    while true; do
        echo "Please select language / 请选择语言:"
        echo "  1) English"
        echo "  2) 中文"
        if ! read -rp "Choice / 选择 (1/2): " lang_choice; then
            echo "Input closed. Exiting."
            exit 1
        fi
        case "$lang_choice" in
            1) LANG_CHOICE="en"; break ;;
            2) LANG_CHOICE="zh"; break ;;
            *) echo -e "${RED}Invalid choice / 无效选择${NC}" ;;
        esac
    done
}

select_language

# ---------- Traps ----------
fstab_backup=""

cleanup_on_signal() {
    echo
    say interrupted
    exit 130
}
trap cleanup_on_signal INT TERM

trap 'say err_trap "$LINENO" >&2 || true' ERR

# ---------- Root check ----------
if [ "$EUID" -ne 0 ]; then
    say root_required
    exit 1
fi

# ---------- Dependency check ----------
for cmd in lsblk parted blkid findmnt mountpoint partprobe mkfs.ext4 wipefs awk sed grep; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        say missing_cmd "$cmd"
        exit 1
    fi
done

# ============================================================
# Helper functions
# ============================================================

# Return one disk name per line for all unmounted disks.
# Uses `lsblk -P` (key="value" pairs) for robust parsing.
get_unmounted_disks() {
    local line name size type mounted
    while IFS= read -r line; do
        [ -z "$line" ] && continue

        # Parse NAME/SIZE/TYPE from lsblk -P output
        name=$(printf '%s\n' "$line" | sed -n 's/.*NAME="\([^"]*\)".*/\1/p')
        size=$(printf '%s\n' "$line" | sed -n 's/.*SIZE="\([^"]*\)".*/\1/p')
        type=$(printf '%s\n' "$line" | sed -n 's/.*TYPE="\([^"]*\)".*/\1/p')

        [ -z "$name" ] && continue
        [[ "$name" =~ ^(sd|vd|nvme|mmcblk|hd) ]] || continue
        [ "$type" = "disk" ] || continue
        [ -z "$size" ] && continue
        [ "$size" = "0B" ] && continue

        # Any mountpoint anywhere under this disk? (partitions included)
        mounted=$(lsblk -nro MOUNTPOINT "/dev/$name" 2>/dev/null | awk 'NF{print; exit}' || true)
        if [ -z "$mounted" ]; then
            echo "$name"
        fi
    done < <(lsblk -Pdn -o NAME,SIZE,TYPE 2>/dev/null)
}

show_disk_info() {
    local dev="$1"
    echo -e "${BLUE}$(t disk_label) /dev/$dev:${NC}"
    lsblk "/dev/$dev" -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT 2>/dev/null | sed 's/^/  /'
}

# Count partitions on a disk with strict numeric validation
count_partitions() {
    local disk="$1"
    local n
    n=$(lsblk -nlo NAME "/dev/$disk" 2>/dev/null \
        | grep -Ec "^${disk}(p)?[0-9]+" || true)
    n=${n:-0}
    [[ "$n" =~ ^[0-9]+$ ]] || n=0
    echo "$n"
}

# Remove fstab entries that target a given mount point (exact field match)
remove_fstab_by_mountpoint() {
    local mnt="$1"
    if awk -v m="$mnt" '$2==m {found=1} END{exit !found}' /etc/fstab 2>/dev/null; then
        local tmp
        tmp=$(mktemp)
        awk -v m="$mnt" '$2!=m' /etc/fstab > "$tmp"
        cp "$tmp" /etc/fstab
        rm -f "$tmp"
        say removed_mount "$mnt"
    fi
}

# Extract first partition name of a disk (nvme/mmcblk aware)
first_partition_of() {
    local disk="$1"
    lsblk -nlo NAME "/dev/$disk" 2>/dev/null \
        | grep -E "^${disk}(p)?[0-9]+" | head -n1 || true
}

# List all partitions of a disk (nvme/mmcblk aware)
list_partitions_of() {
    local disk="$1"
    lsblk -nlo NAME "/dev/$disk" 2>/dev/null \
        | grep -E "^${disk}(p)?[0-9]+" || true
}

# ============================================================
# Step 1: Select disk
# ============================================================
say step1_title
say scanning

unmounted_disks=()
while IFS= read -r d; do
    [ -n "$d" ] && unmounted_disks+=("$d")
done < <(get_unmounted_disks)

if [ "${#unmounted_disks[@]}" -eq 0 ]; then
    say no_disks
    echo
    say all_disks
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
    exit 1
fi

say found_disks "${#unmounted_disks[@]}"
echo
for i in "${!unmounted_disks[@]}"; do
    echo -e "${BLUE}[$((i+1))]${NC} /dev/${unmounted_disks[$i]}"
    show_disk_info "${unmounted_disks[$i]}"
    echo
done

while true; do
    say select_disk "${#unmounted_disks[@]}"
    if ! read -rp "$(t input_number)" choice; then
        say interrupted
        exit 130
    fi
    if [[ "${choice:-}" =~ ^[0-9]+$ ]] \
        && [ "$choice" -ge 1 ] \
        && [ "$choice" -le "${#unmounted_disks[@]}" ]; then
        disk="${unmounted_disks[$((choice-1))]}"
        break
    fi
    say invalid_selection "${#unmounted_disks[@]}"
done

device="/dev/$disk"
existing_partitions=$(count_partitions "$disk")

# ============================================================
# Step 2: Operation mode
# ============================================================
echo
say step2_title
if [ "$existing_partitions" -gt 0 ]; then
    say existing_parts "$device" "$existing_partitions"
    say mode1_desc
    say mode2_desc
    echo
    while true; do
        if ! read -rp "$(t mode_prompt)" operation_mode; then
            say interrupted
            exit 130
        fi
        if [ "$operation_mode" = "1" ] || [ "$operation_mode" = "2" ]; then
            break
        fi
        say mode_invalid
    done
else
    operation_mode="2"
    say no_parts_mode2
fi

# ============================================================
# Step 3: Mount directory
# ============================================================
echo
say step3_title
while true; do
    if ! read -rp "$(t mount_prompt)" mount_dir; then
        say interrupted
        exit 130
    fi

    if [ -z "$mount_dir" ]; then
        say mount_empty
        continue
    fi
    if [[ "$mount_dir" != /* ]]; then
        say mount_not_abs
        continue
    fi
    if [ "$mount_dir" = "/" ]; then
        say mount_root_denied
        continue
    fi
    if mountpoint -q "$mount_dir" 2>/dev/null; then
        say mount_in_use "$mount_dir"
        continue
    fi
    # Reject directories that live inside an already-mounted filesystem
    parent_mount=$(findmnt -n -o TARGET --target "$mount_dir" 2>/dev/null | head -n1 || true)
    if [ -n "$parent_mount" ] && [ "$parent_mount" != "/" ] && [ "$parent_mount" != "$mount_dir" ]; then
        say mount_subdir "$mount_dir"
        continue
    fi
    if awk -v m="$mount_dir" '$2==m {found=1} END{exit !found}' /etc/fstab 2>/dev/null; then
        say mount_in_fstab "$mount_dir"
        if ! read -rp "$(t continue_ask)" continue_choice; then
            say interrupted
            exit 130
        fi
        if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
            continue
        fi
    fi
    break
done

# ============================================================
# Step 4: Confirm
# ============================================================
echo
say step4_title
say about_to_exec
disk_size=$(lsblk -dn -o SIZE "$device" 2>/dev/null || echo "?")
[ -z "$disk_size" ] && disk_size="?"
say label_disk "$device" "$disk_size"
say label_mount "$mount_dir"

partition=""
if [ "$operation_mode" = "1" ]; then
    fp=$(first_partition_of "$disk")
    if [ -z "$fp" ]; then
        say part_failed "/dev/${disk}1"
        exit 1
    fi
    partition="/dev/$fp"
    say label_mode1 "$partition"
else
    say label_mode2
    say label_warn
fi
echo
if ! read -rp "$(t confirm_prompt)" confirm; then
    say interrupted
    exit 130
fi
if [ "$confirm" != "yes" ]; then
    say cancelled
    exit 0
fi

# ============================================================
# Step 5: Execute
# ============================================================
echo
say step5_title

# Backup fstab for both modes
fstab_backup="/etc/fstab.backup.$(date +%Y%m%d_%H%M%S)"
cp /etc/fstab "$fstab_backup"
say backup_done "$fstab_backup"

if [ "$operation_mode" = "1" ]; then
    # ---------- Mode 1: mount existing partition ----------
    say mounting
    remove_fstab_by_mountpoint "$mount_dir"

    mkdir -p "$mount_dir"
    if ! mount "$partition" "$mount_dir"; then
        say mount_failed
        exit 1
    fi
    if ! mountpoint -q "$mount_dir"; then
        say mount_verify_failed
        exit 1
    fi

    uuid=$(blkid -s UUID -o value "$partition" || true)
    fstype=$(blkid -s TYPE -o value "$partition" || true)
    if [ -z "$uuid" ] || [ -z "$fstype" ]; then
        say uuid_failed
        exit 1
    fi

    printf 'UUID=%s %s %s defaults,noatime 0 0\n' "$uuid" "$mount_dir" "$fstype" >> /etc/fstab
    say mount_success "$partition" "$mount_dir"
    say fstab_written_fs "$fstype"

else
    # ---------- Mode 2: wipe, partition, format ----------
    say unmounting
    while IFS= read -r part; do
        [ -z "$part" ] && continue
        part_dev="/dev/$part"
        if findmnt -n -S "$part_dev" >/dev/null 2>&1; then
            say unmounting_part "$part_dev"
            umount -f "$part_dev" 2>/dev/null || true
        fi
    done < <(list_partitions_of "$disk")

    say cleaning_fstab
    while IFS= read -r part; do
        [ -z "$part" ] && continue
        old_uuid=$(blkid -s UUID -o value "/dev/$part" 2>/dev/null || true)
        if [ -n "$old_uuid" ]; then
            if awk -v u="UUID=$old_uuid" '$1==u {found=1} END{exit !found}' /etc/fstab 2>/dev/null; then
                tmp=$(mktemp)
                awk -v u="UUID=$old_uuid" '$1!=u' /etc/fstab > "$tmp"
                cp "$tmp" /etc/fstab
                rm -f "$tmp"
                say removed_uuid "$old_uuid"
            fi
        fi
    done < <(list_partitions_of "$disk")

    remove_fstab_by_mountpoint "$mount_dir"

    say creating_parttable
    wipefs -a "$device" >/dev/null 2>&1 || true
    parted -s "$device" mklabel gpt
    parted -s "$device" mkpart primary 0% 100%

    if [[ "$device" =~ /dev/(nvme|mmcblk) ]]; then
        partition="${device}p1"
    else
        partition="${device}1"
    fi

    say waiting_part
    sleep 2
    partprobe "$device" 2>/dev/null || true
    if command -v udevadm >/dev/null 2>&1; then
        udevadm settle 2>/dev/null || true
    fi
    sleep 1

    if [ ! -b "$partition" ]; then
        say part_failed "$partition"
        exit 1
    fi

    say formatting
    if ! mkfs.ext4 -F "$partition"; then
        say format_failed
        exit 1
    fi

    uuid=$(blkid -s UUID -o value "$partition" || true)
    if [ -z "$uuid" ]; then
        say uuid_failed
        exit 1
    fi

    say creating_mount "$mount_dir"
    mkdir -p "$mount_dir"

    say mounting
    if ! mount -U "$uuid" "$mount_dir"; then
        say mount_failed
        exit 1
    fi
    if ! mountpoint -q "$mount_dir"; then
        say mount_verify_failed
        exit 1
    fi

    say mount_success_uuid "$uuid" "$mount_dir"
    printf 'UUID=%s %s ext4 defaults,noatime 0 0\n' "$uuid" "$mount_dir" >> /etc/fstab
    say fstab_written
fi

# ============================================================
# Result
# ============================================================
echo
say done_title
say mount_info
df -h "$mount_dir" || true
echo
say disk_info
lsblk "$device"
echo
say fstab_info
awk -v u="UUID=$uuid" '$1==u' /etc/fstab || true
echo
say final_success "$disk" "$mount_dir"
say hint_mount_a
if [ -n "$fstab_backup" ]; then
    say hint_backup "$fstab_backup"
fi
