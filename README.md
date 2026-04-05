```markdown
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
```

### 或者通过 Git 克隆

```bash
git clone https://github.com/K23Flux/swap-.git
cd swap-
chmod +x swap.sh
./swap.sh
```

---

## 🎮 使用菜单

运行脚本后会显示交互菜单：

```
1. 添加 Swap（智能模式）          ← 推荐使用
2. 删除 Swap（彻底清理）
3. 强制重置 Swap（修复问题时使用）
0. 退出
```

**使用建议**：
- 内存 512MB~2GB 的 VPS，推荐添加 **1GB ~ 2GB** Swap
- 内存 4GB 以上，可根据需求添加 2GB~4GB
- 输入 Swap 大小时请直接输入数字（单位：MB），例如 `2048` 表示 2GB

---

## ⚠️ 注意事项

- **必须以 root 权限运行**（建议先执行 `sudo -i`）
- **OpenVZ / 部分 LXC 容器** 默认不支持用户态创建 Swap，会提示 `Operation not permitted`
- 创建的 Swap 大小不要超过磁盘剩余可用空间
- 脚本会修改 `/etc/fstab` 文件，重要服务器建议提前备份
- Btrfs 文件系统用户无需手动操作，脚本已自动优化

---

## 📁 仓库文件

- `swap.sh` —— 主脚本（v2.0）
- `README.md` —— 本文档

---

## 📖 更新日志

**v2.0（当前版本）**
- 重构代码结构，提升可读性和稳定性
- 优化 Btrfs 处理流程，增加错误捕获
- 改进用户交互和提示信息
- 增强对多种 Linux 发行版的兼容性

---

## 📄 开源协议

本项目采用 [MIT License](LICENSE) 开源协议，欢迎 Fork、Star 和提交 Pull Request。

---

## 💬 反馈与支持

- 如果在使用中遇到问题，欢迎在 [Issues](https://github.com/K23Flux/swap-/issues) 中提交
- 欢迎提交改进建议或代码优化

**作者**：K23Flux  
**GitHub**：https://github.com/K23Flux/swap-

---

**感谢使用本脚本！**  
如果觉得好用，欢迎点个 **Star** ⭐ 支持一下～
```

---
