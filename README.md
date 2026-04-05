# 🚀 Linux VPS 智能 Swap 管理脚本 (Btrfs 优化版)

![Shell](https://img.shields.io/badge/language-Shell-blue.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

一个轻量级、高兼容性的 Linux Swap 管理工具，专为 VPS 环境设计。

**特别优化了 Btrfs 文件系统**，彻底解决在 Btrfs 下创建 Swap 时常见的 `swapon: /swapfile: Invalid argument` 错误。

支持 **Debian / Ubuntu / CentOS / AlmaLinux / Rocky Linux** 等主流发行版。

---

## ✨ 核心特性

- 智能检测文件系统（Ext4 / Btrfs / 其他）
- Btrfs 自动处理：执行 `chattr +C` 禁用 Copy-on-Write（CoW），确保 Swap 正常工作
- 创建前自动安全清理旧 Swap，防止配置冲突
- 支持**一键添加**、**彻底删除**、**强制重置**三种模式
- 详细错误捕获与友好提示（包含 OpenVZ/LXC 不支持 Swap 的说明）
- 操作完成后自动显示 `free -h` 内存状态
- 纯 Bash 编写，无需任何额外依赖
- 版本：**v2.0 Stable**

---

## 📥 快速使用

### 一键启动（推荐）

在你的 VPS 终端直接执行以下命令：

```bash
wget -O swap.sh https://raw.githubusercontent.com/K23Flux/swap-/main/swap.sh && chmod +x swap.sh && ./swap.sh
