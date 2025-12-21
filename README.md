# 🚀 Linux VPS 智能 Swap 管理脚本 (Btrfs 修复版)

这是一个轻量级的 Linux VPS 虚拟内存（Swap）管理工具。

专为 **Debian/Ubuntu/CentOS** 设计，特别解决了在 **Btrfs** 文件系统下创建 Swap 报错（`Invalid argument`）的问题。支持一键添加、删除、强制重置 Swap。

## ✨ 主要功能

* **🛠 智能文件系统识别**：自动检测系统是 `Ext4` 还是 `Btrfs`。
* **💾 Btrfs 完美兼容**：针对 Btrfs 系统自动执行 `chattr +C` 禁用写时复制（CoW），彻底修复挂载失败的问题。
* **🛡 安全防错**：在创建新 Swap 前自动清理旧环境，防止冲突；支持捕获系统报错信息。
* **⚡ 强制重置模式**：无论当前 Swap 是否损坏，一键暴力重置，修复各种配置错误。
* **📊 状态直观**：操作结束后自动显示 `free -h` 内存状态。

## 🖥 快速使用

无需下载文件，直接在 VPS 终端执行以下命令即可启动菜单：

```bash
wget -O swap.sh [https://raw.githubusercontent.com/K23Flux/swap-/main/swap.sh](https://raw.githubusercontent.com/K23Flux/swap-/main/swap.sh) && chmod +x swap.sh && ./swap.sh
