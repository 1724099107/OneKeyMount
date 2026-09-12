# OneKeyMount

一个安全、交互式的 Bash 脚本，用于在 Linux 上挂载未挂载的块设备——支持可选的分区、格式化，并自动写入 `/etc/fstab` 实现开机自动挂载。

![Shell](https://img.shields.io/badge/shell-bash-4EAA25?logo=gnu-bash&logoColor=white)
![Platform](https://img.shields.io/badge/platform-Linux-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![ShellCheck](https://img.shields.io/badge/shellcheck-passing-brightgreen)

> **English docs:** [README.md](README.md)

---

## 目录

- [快速开始](#快速开始)
- [特性](#特性)
- [环境要求](#环境要求)
- [安装](#安装)
- [使用](#使用)
- [工作原理](#工作原理)
- [安全提示](#安全提示)
- [已知限制](#已知限制)
- [路线图](#路线图)
- [参与贡献](#参与贡献)
- [许可证](#许可证)
- [免责声明](#免责声明)

---

## 快速开始

```bash
git clone https://github.com/1724099107/OneKeyMount.git
cd OneKeyMount
chmod +x OneKeyMount.sh
sudo ./OneKeyMount.sh
```

剩下的步骤按提示操作即可，脚本启动时会先询问使用**中文**还是**英文**。

> **语言：** 脚本内置**中英文**双语提示，启动时选择。

---

## 特性

- 🔍 **自动识别未挂载磁盘** — 扫描 `sd*`、`vd*`、`nvme*`、`mmcblk*`、`hd*` 设备
- 🌐 **中英双语界面** — 启动时选择语言
- 🧭 **两种操作模式**
  - **挂载现有分区** — 保留数据，自动识别真实文件系统类型
  - **清空并重新分区格式化** — 清空磁盘、创建 GPT 分区、格式化为 `ext4`
- 💾 **开机自动挂载** — 自动写入基于 `UUID=` 的 `/etc/fstab` 条目
- 🛡️ **安全优先**
  - 必须以 root 运行
  - 每次修改前自动备份 `/etc/fstab`
  - 拒绝挂载到 `/`、相对路径、或已挂载文件系统内部
  - 通过字段精确匹配清理 fstab 中的旧条目
- 🧩 **广泛的设备兼容** — 正确处理 `nvme*` 和 `mmcblk*` 的 `pN` 分区命名
- 🎨 **彩色输出**，配合交互式提示与二次确认

---

## 环境要求

- Linux 系统，`bash` 4.0+（依赖关联数组）
- root 权限（或 `sudo`）
- 以下命令需在 `$PATH` 中可用：

| 命令         | 用途                         |
|--------------|------------------------------|
| `lsblk`      | 枚举块设备                   |
| `parted`     | 创建分区表                   |
| `blkid`      | 读取 UUID / 文件系统类型     |
| `findmnt`    | 按源设备检测挂载状态         |
| `mountpoint` | 判断目录是否为挂载点         |
| `partprobe`  | 重新读取分区表               |
| `udevadm`    | 等待设备节点就绪（可选）     |
| `mkfs.ext4`  | 格式化新分区                 |
| `awk`、`sed`、`grep` | 文本处理             |

### 安装依赖

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

## 安装

克隆仓库：

```bash
git clone https://github.com/1724099107/OneKeyMount.git
cd OneKeyMount
chmod +x OneKeyMount.sh
```

或直接下载脚本：

```bash
curl -fsSL -o OneKeyMount.sh https://raw.githubusercontent.com/1724099107/OneKeyMount/main/OneKeyMount.sh
chmod +x OneKeyMount.sh
```

---

## 使用

以 **root** 身份运行：

```bash
sudo ./OneKeyMount.sh
```

脚本通过五个交互步骤完成挂载：

1. **选择磁盘** — 从检测到的未挂载块设备中选择
2. **选择操作方式**
   - `1` — 挂载现有分区（保留数据）
   - `2` — 清空、分区、格式化并挂载（**危险操作**）
3. **输入挂载目录** — 例如 `/data` 或 `/mnt/storage`
4. **确认操作** — 输入 `yes` 继续
5. **完成** — 脚本自动挂载并写入 `fstab`

### 示例会话（中文）

```
请选择语言:
  1) English
  2) 中文
选择 (1/2): 2

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
挂载分区...
✓ 挂载成功: /dev/sdb1 -> /data
✓ 已写入 /etc/fstab (fstype=ext4)

=== 操作完成 ===
挂载信息:
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdb1        98G   24K   93G   1% /data

磁盘分区信息:
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sdb      8:16   0  100G  0 disk
└─sdb1   8:17   0  100G  0 part /data

fstab 配置:
UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx /data ext4 defaults,noatime 0 0

✓ 磁盘 sdb 已成功挂载到 /data
提示: 可以使用 'mount -a' 测试 fstab 配置是否正确
提示: fstab 备份文件: /etc/fstab.backup.20250101_120000
```

---

## 工作原理

### 模式 1 — 挂载现有分区

1. 删除 `/etc/fstab` 中指向同一挂载目录的旧条目
2. 若挂载目录不存在则创建
3. 挂载磁盘上的第一个分区
4. 通过 `blkid` 读取分区的 **UUID** 和真实 **文件系统类型**
5. 追加一行到 `/etc/fstab`：

   ```
   UUID=<uuid> <mount_dir> <fstype> defaults,noatime 0 0
   ```

### 模式 2 — 清空并重新分区格式化

1. 卸载磁盘上所有已挂载的分区
2. 按 UUID 和挂载点删除 `/etc/fstab` 中的旧条目
3. 备份 `/etc/fstab`
4. 清除分区签名（`wipefs`），创建新的 **GPT** 分区表
5. 创建单个占满整盘的分区
6. 格式化为 **ext4**
7. 挂载并写入 `fstab`

### 设备命名规则

| 设备模式         | 分区名           |
|------------------|------------------|
| `/dev/sdX`       | `/dev/sdX1`      |
| `/dev/vdX`       | `/dev/vdX1`      |
| `/dev/hdX`       | `/dev/hdX1`      |
| `/dev/nvmeXnY`   | `/dev/nvmeXnYp1` |
| `/dev/mmcblkX`   | `/dev/mmcblkXp1` |

---

## 安全提示

- ⚠️ **数据丢失警告：** 模式 2 会**不可恢复地**清除所选磁盘上的所有数据。请在输入 `yes` 前再次确认目标磁盘。
- 💾 **自动备份：** 每次运行脚本（无论模式 1 还是模式 2）都会将 `/etc/fstab` 备份到 `/etc/fstab.backup.YYYYmmdd_HHMMSS`。
- ✅ **验证：** 脚本执行完成后，可用以下命令验证 `fstab` 配置：

  ```bash
  sudo mount -a
  ```

  若无任何输出且退出码为 0，则配置正确。
- 🔧 **恢复：** 若 `/etc/fstab` 被破坏，可从备份恢复：

  ```bash
  sudo cp /etc/fstab.backup.YYYYmmdd_HHMMSS /etc/fstab
  ```
- 🛑 **中断：** 按下 `Ctrl+C` 会立即中止脚本。若在模式 2 的分区操作阶段中止，请重新运行脚本以完成操作。

---

## 已知限制

- 模式 2 目前仅支持格式化为 **ext4**。`xfs`、`btrfs` 等文件系统尚未支持。
- 模式 1 只挂载磁盘上的**第一个分区**。多分区磁盘需要手动处理。
- 不支持 LVM、LUKS、RAID 或 ZFS 卷。
- 脚本假设目标磁盘未被任何 LVM/RAID 子系统占用。
- 交互提示仅支持中英双语，更多语言在路线图中。

---

## 路线图

- [ ] 新增语言包（日语、韩语等）
- [ ] 模式 2 支持 `xfs` 和 `btrfs`
- [ ] 可选的 LVM 卷创建
- [ ] 演练模式（`--dry-run`）
- [ ] 非交互模式，便于在 Ansible、cloud-init 等工具中调用
- [x] `shellcheck` CI 工作流
- [x] 中英双语界面

---

## 参与贡献

欢迎提交 Issue 和 Pull Request！流程如下：

1. Fork 本仓库
2. 创建特性分支：`git checkout -b feature/my-feature`
3. 运行 `shellcheck OneKeyMount.sh` 并修复所有警告
4. 提交更改：`git commit -am 'Add my feature'`
5. 推送分支：`git push origin feature/my-feature`
6. 发起 Pull Request

详细说明请见 [CONTRIBUTING.md](CONTRIBUTING.md)。

### 代码风格

- 尽量使用与 POSIX 兼容的 `bash`
- 所有变量扩展都加引号：`"$var"`
- 优先使用 `[[ ]]` 而非 `[ ]`
- 使用 `set -euo pipefail`
- 函数保持短小、自解释
- 不保留行尾空格；使用 LF 换行

---

## 许可证

本项目基于 [MIT License](LICENSE) 许可发布。

---

## 免责声明

本脚本在选择模式 2 时会执行**破坏性的磁盘操作**。作者不对使用本脚本造成的任何数据丢失或系统损坏负责。**运行前请务必仔细阅读脚本并做好数据备份。**

---

## 致谢

使用标准 Linux 工具构建——除典型发行版自带的工具外无额外依赖。
