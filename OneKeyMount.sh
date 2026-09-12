#!/bin/bash
set -euo pipefail

# 错误位置提示
trap 'echo -e "${RED}脚本在第 $LINENO 行因错误退出${NC}" >&2' ERR

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

fstab_backup=""

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}请使用 root 用户运行此脚本${NC}"
    exit 1
fi

# 检查依赖
for cmd in lsblk parted blkid findmnt mountpoint partprobe mkfs.ext4 awk sed grep udevadm; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${RED}缺少命令: $cmd，请先安装${NC}"
        exit 1
    fi
done

# 获取所有未挂载的磁盘（每行输出一个磁盘名）
get_unmounted_disks() {
    local name size type mounted
    while read -r name size type; do
        [ -z "$name" ] && continue
        [[ "$name" =~ ^(sd|vd|nvme|mmcblk|hd) ]] || continue
        [ "$type" = "disk" ] || continue
        [ "$size" = "0B" ] && continue
        [ -z "$size" ] && continue
        # 递归检查该磁盘及其子分区是否有挂载点
        mounted=$(lsblk -nro MOUNTPOINT "/dev/$name" 2>/dev/null | awk 'NF{print; exit}' || true)
        if [ -z "$mounted" ]; then
            echo "$name"
        fi
    done < <(lsblk -dn -o NAME,SIZE,TYPE 2>/dev/null)
}

# 显示磁盘详细信息
show_disk_info() {
    local dev="$1"
    echo -e "${BLUE}磁盘 /dev/$dev:${NC}"
    lsblk "/dev/$dev" -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT 2>/dev/null | sed 's/^/  /'
}

# 计算磁盘已有分区数
count_partitions() {
    local disk="$1"
    local n
    n=$(lsblk -nlo NAME "/dev/$disk" 2>/dev/null \
        | grep -Ec "^${disk}(p)?[0-9]+" || true)
    echo "${n:-0}"
}

# 安全地从 fstab 移除指定挂载点的条目
remove_fstab_by_mountpoint() {
    local mnt="$1"
    if awk -v m="$mnt" '$2==m {found=1} END{exit !found}' /etc/fstab 2>/dev/null; then
        local tmp
        tmp=$(mktemp)
        awk -v m="$mnt" '$2!=m' /etc/fstab > "$tmp"
        cp "$tmp" /etc/fstab
        rm -f "$tmp"
        echo "  已从 fstab 移除挂载点条目: $mnt"
    fi
}

# ==================== 步骤 1: 选择磁盘 ====================
echo -e "${GREEN}=== 步骤 1: 选择要挂载的磁盘 ===${NC}"
echo -e "${GREEN}正在扫描未挂载的磁盘...${NC}"

unmounted_disks=()
while IFS= read -r d; do
    [ -n "$d" ] && unmounted_disks+=("$d")
done < <(get_unmounted_disks)

if [ "${#unmounted_disks[@]}" -eq 0 ]; then
    echo -e "${RED}未检测到可用的未挂载磁盘${NC}"
    echo ""
    echo -e "${YELLOW}当前所有磁盘状态:${NC}"
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
    exit 1
fi

echo -e "${GREEN}找到 ${#unmounted_disks[@]} 个未挂载的磁盘:${NC}"
echo ""
for i in "${!unmounted_disks[@]}"; do
    echo -e "${BLUE}[$((i+1))]${NC} /dev/${unmounted_disks[$i]}"
    show_disk_info "${unmounted_disks[$i]}"
    echo ""
done

while true; do
    echo -e "${YELLOW}请选择要操作的磁盘编号 (1-${#unmounted_disks[@]}):${NC}"
    read -rp "输入编号: " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#unmounted_disks[@]}" ]; then
        disk="${unmounted_disks[$((choice-1))]}"
        break
    else
        echo -e "${RED}无效选择，请输入 1-${#unmounted_disks[@]} 之间的数字${NC}"
    fi
done

device="/dev/$disk"
existing_partitions=$(count_partitions "$disk")

# ==================== 步骤 2: 选择操作模式 ====================
echo ""
echo -e "${GREEN}=== 步骤 2: 选择操作方式 ===${NC}"
if [ "$existing_partitions" -gt 0 ]; then
    echo -e "${YELLOW}检测到磁盘 $device 已有 $existing_partitions 个分区${NC}"
    echo "  1) 挂载现有分区（不格式化，保留数据）"
    echo "  2) 清空并重新分区格式化（⚠️ 将丢失所有数据）"
    echo ""
    while true; do
        read -rp "请选择操作方式 (1 或 2): " operation_mode
        if [ "$operation_mode" = "1" ] || [ "$operation_mode" = "2" ]; then
            break
        fi
        echo -e "${RED}无效选择，请输入 1 或 2${NC}"
    done
else
    operation_mode="2"
    echo -e "${YELLOW}磁盘无分区，将进行格式化操作${NC}"
fi

# ==================== 步骤 3: 输入挂载目录 ====================
echo ""
echo -e "${GREEN}=== 步骤 3: 输入挂载目录 ===${NC}"
while true; do
    read -rp "请输入挂载目录路径 (例如: /data, /mnt/storage): " mount_dir
    if [ -z "$mount_dir" ]; then
        echo -e "${RED}挂载目录不能为空${NC}"
        continue
    fi
    if [[ "$mount_dir" != /* ]]; then
        echo -e "${RED}挂载目录必须是绝对路径（以 / 开头）${NC}"
        continue
    fi
    if [ "$mount_dir" = "/" ]; then
        echo -e "${RED}不允许使用根目录 / 作为挂载目录${NC}"
        continue
    fi
    if mountpoint -q "$mount_dir" 2>/dev/null; then
        echo -e "${RED}错误: $mount_dir 已被挂载，请选择其他目录${NC}"
        continue
    fi
    if awk -v m="$mount_dir" '$2==m {found=1} END{exit !found}' /etc/fstab 2>/dev/null; then
        echo -e "${YELLOW}警告: $mount_dir 已在 /etc/fstab 中存在配置${NC}"
        read -rp "是否继续使用此目录? (y/n): " continue_choice
        if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
            continue
        fi
    fi
    break
done

# ==================== 步骤 4: 确认操作 ====================
echo ""
echo -e "${GREEN}=== 步骤 4: 确认操作 ===${NC}"
echo -e "${YELLOW}即将执行以下操作:${NC}"
disk_size=$(lsblk -dn -o SIZE "$device" 2>/dev/null || echo "未知大小")
echo "  磁盘: $device ($disk_size)"
echo "  挂载目录: $mount_dir"

partition=""
if [ "$operation_mode" = "1" ]; then
    first_part=$(lsblk -nlo NAME "$device" 2>/dev/null \
        | grep -E "^${disk}(p)?[0-9]+" | head -n1 || true)
    if [ -z "$first_part" ]; then
        echo -e "${RED}未能找到可挂载的分区${NC}"
        exit 1
    fi
    partition="/dev/$first_part"
    echo "  操作: 挂载现有分区 $partition（数据保留）"
else
    echo "  操作: 清空磁盘 -> 创建分区 -> 格式化 -> 挂载"
    echo "  ⚠️ 所有数据将丢失！"
fi
echo ""
read -rp "确认继续? (输入 yes 继续): " confirm
if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}操作已取消${NC}"
    exit 0
fi

# ==================== 步骤 5: 执行操作 ====================
echo ""
echo -e "${GREEN}=== 步骤 5: 执行操作 ===${NC}"

# 备份 fstab（两种模式都备份）
fstab_backup="/etc/fstab.backup.$(date +%Y%m%d_%H%M%S)"
cp /etc/fstab "$fstab_backup"
echo -e "${YELLOW}已备份 /etc/fstab 到: $fstab_backup${NC}"

if [ "$operation_mode" = "1" ]; then
    # ---------- 模式1: 挂载现有分区 ----------
    echo -e "${YELLOW}挂载现有分区 $partition...${NC}"

    remove_fstab_by_mountpoint "$mount_dir"

    mkdir -p "$mount_dir"
    if ! mount "$partition" "$mount_dir"; then
        echo -e "${RED}✗ 挂载失败，请检查！${NC}"
        exit 1
    fi

    if ! mountpoint -q "$mount_dir"; then
        echo -e "${RED}✗ 挂载失败（挂载点校验未通过）${NC}"
        exit 1
    fi

    uuid=$(blkid -s UUID -o value "$partition" || true)
    fstype=$(blkid -s TYPE -o value "$partition" || true)
    if [ -z "$uuid" ] || [ -z "$fstype" ]; then
        echo -e "${RED}无法获取分区 UUID 或文件系统类型${NC}"
        exit 1
    fi

    # 使用实际文件系统类型写入 fstab
    printf 'UUID=%s %s %s defaults,noatime 0 0\n' "$uuid" "$mount_dir" "$fstype" >> /etc/fstab
    echo -e "${GREEN}✓ 挂载成功: $partition -> $mount_dir${NC}"
    echo -e "${GREEN}✓ 已写入 /etc/fstab (fstype=$fstype)${NC}"

else
    # ---------- 模式2: 清空并重新分区格式化 ----------
    echo -e "${YELLOW}正在卸载旧分区...${NC}"
    while IFS= read -r part; do
        [ -z "$part" ] && continue
        part_dev="/dev/$part"
        # findmnt 按源设备查询挂载状态（原脚本这里用 mountpoint 判断设备是错的）
        if findmnt -n -S "$part_dev" >/dev/null 2>&1; then
            echo "  卸载: $part_dev"
            umount -f "$part_dev" 2>/dev/null || true
        fi
    done < <(lsblk -nlo NAME "$device" 2>/dev/null | grep -E "^${disk}(p)?[0-9]+" || true)

    echo -e "${YELLOW}清理 /etc/fstab 中的旧条目...${NC}"
    while IFS= read -r part; do
        [ -z "$part" ] && continue
        old_uuid=$(blkid -s UUID -o value "/dev/$part" 2>/dev/null || true)
        if [ -n "$old_uuid" ]; then
            if awk -v u="UUID=$old_uuid" '$1==u {found=1} END{exit !found}' /etc/fstab 2>/dev/null; then
                tmp=$(mktemp)
                awk -v u="UUID=$old_uuid" '$1!=u' /etc/fstab > "$tmp"
                cp "$tmp" /etc/fstab
                rm -f "$tmp"
                echo "  已删除 UUID: $old_uuid"
            fi
        fi
    done < <(lsblk -nlo NAME "$device" 2>/dev/null | grep -E "^${disk}(p)?[0-9]+" || true)

    remove_fstab_by_mountpoint "$mount_dir"

    echo -e "${YELLOW}正在创建分区表...${NC}"
    wipefs -a "$device" >/dev/null 2>&1 || true
    parted -s "$device" mklabel gpt
    parted -s "$device" mkpart primary 0% 100%

    # 分区命名：nvme/mmcblk 用 pN，其它用 N
    if [[ "$device" =~ /dev/(nvme|mmcblk) ]]; then
        partition="${device}p1"
    else
        partition="${device}1"
    fi

    echo "  等待分区设备..."
    sleep 2
    partprobe "$device" 2>/dev/null || true
    udevadm settle 2>/dev/null || true
    sleep 1

    if [ ! -b "$partition" ]; then
        echo -e "${RED}分区创建失败: $partition 不存在${NC}"
        exit 1
    fi

    echo -e "${YELLOW}正在格式化分区...${NC}"
    mkfs.ext4 -F "$partition" > /dev/null 2>&1

    uuid=$(blkid -s UUID -o value "$partition" || true)
    if [ -z "$uuid" ]; then
        echo -e "${RED}获取 UUID 失败${NC}"
        exit 1
    fi

    echo -e "${YELLOW}创建挂载目录: $mount_dir${NC}"
    mkdir -p "$mount_dir"

    echo -e "${YELLOW}挂载分区...${NC}"
    if ! mount -U "$uuid" "$mount_dir"; then
        echo -e "${RED}✗ 挂载失败，请检查！${NC}"
        exit 1
    fi

    if mountpoint -q "$mount_dir"; then
        echo -e "${GREEN}✓ 挂载成功: UUID=$uuid -> $mount_dir${NC}"
    else
        echo -e "${RED}✗ 挂载失败（挂载点校验未通过）${NC}"
        exit 1
    fi

    printf 'UUID=%s %s ext4 defaults,noatime 0 0\n' "$uuid" "$mount_dir" >> /etc/fstab
    echo -e "${GREEN}✓ 已写入 /etc/fstab${NC}"
fi

# ==================== 显示结果 ====================
echo ""
echo -e "${GREEN}=== 操作完成 ===${NC}"
echo -e "${BLUE}挂载信息:${NC}"
df -h "$mount_dir" || true
echo ""
echo -e "${BLUE}磁盘分区信息:${NC}"
lsblk "$device"
echo ""
echo -e "${BLUE}fstab 配置:${NC}"
grep "$uuid" /etc/fstab || true
echo ""
echo -e "${GREEN}✓ 磁盘 $disk 已成功挂载到 $mount_dir${NC}"
echo -e "${YELLOW}提示: 可以使用 'mount -a' 测试 fstab 配置是否正确${NC}"
if [ -n "$fstab_backup" ]; then
    echo -e "${YELLOW}提示: fstab 备份文件: $fstab_backup${NC}"
fi