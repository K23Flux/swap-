# Linux VPS 智能 Swap 管理脚本

![Shell](https://img.shields.io/badge/language-Shell-blue.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

一个面向 VPS 的交互式 Swap 管理脚本，支持添加、删除和强制重置 `/swapfile`。

脚本针对 Btrfs 做了兼容处理，优先使用 `btrfs filesystem mkswapfile`，不可用时自动回退到 `chattr +C` 方案，减少 `swapon: /swapfile: Invalid argument` 问题。

## 核心特性

- 自动检测根分区文件系统，支持 Ext4、XFS、Btrfs 等常见环境
- 创建前清理旧 `/swapfile`，避免重复挂载和 `/etc/fstab` 配置冲突
- 修改 `/etc/fstab` 前自动生成时间戳备份
- 输入 Swap 大小时检查格式和磁盘剩余空间
- 写入 `/etc/fstab` 前检查现有配置，避免重复追加
- 操作完成后显示 `swapon --show` 和 `free -h`
- 对 OpenVZ、部分 LXC 或宿主机禁用 Swap 的情况提供错误提示

## 支持系统

- Debian / Ubuntu
- CentOS / AlmaLinux / Rocky Linux
- 其他具备 `bash`、`util-linux`、`coreutils` 的主流 Linux 发行版

## 快速使用

在 VPS 终端使用 root 权限执行：

```bash
wget -O swap.sh https://raw.githubusercontent.com/K23Flux/swap-/main/swap.sh && chmod +x swap.sh && ./swap.sh
```

如果当前不是 root 用户，可以先执行：

```bash
sudo -i
```

## 菜单说明

```text
1. 添加 Swap (智能模式)
2. 删除 Swap (彻底卸载)
3. 强制重置 Swap (修复报错专用)
0. 退出
```

## 注意事项

- 脚本只管理 `/swapfile`，不会主动修改其他 swap 分区或 swap 文件。
- 脚本会修改 `/etc/fstab`，每次修改前会创建类似 `/etc/fstab.bak.20260101123000` 的备份。
- 创建 Swap 前请确保磁盘空间充足，脚本会预留 64 MB 安全余量。
- OpenVZ、部分 LXC 容器或被宿主机限制的 VPS 可能无法启用 Swap，这是虚拟化环境限制，不是脚本错误。

## 版本

当前版本：v2.1 Stable

## License

MIT
