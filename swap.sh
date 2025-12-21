#!/bin/bash

# =========================================================
# System: Debian/Ubuntu/CentOS
# Description: Smart Swap Manager with Btrfs Support
# Version: 2.0 (Stable)
# Author: [Your Name/GitHub ID]
# =========================================================

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
SKY='\033[0;36m'
NC='\033[0m' # No Color

# 检查 Root 权限
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}错误：请使用 root 权限运行此脚本！(sudo -i)${NC}"
  exit 1
fi

# ==========================================
# 辅助函数：显示最终结果
# ==========================================
function show_result() {
    local status=$1
    local msg=$2
    echo ""
    echo -e "========================================"
    if [ "$status" == "success" ]; then
        echo -e "${GREEN}★  写入成功！${NC}"
        echo -e "${GREEN}★  $msg ${NC}"
        echo -e "----------------------------------------"
        echo -e "当前内存状态："
        free -h
    else
        echo -e "${RED}❌ 写入失败！${NC}"
        echo -e "${RED}原因分析: $msg ${NC}"
        echo -e "${YELLOW}提示：如果报错 'Operation not permitted'，说明这是 OpenVZ 架构，不支持 Swap。${NC}"
    fi
    echo -e "========================================"
}

# ==========================================
# 核心函数：删除 Swap
# ==========================================
function remove_swap() {
    echo -e "${YELLOW}---> [清理] 正在检测并卸载旧 Swap...${NC}"
    
    # 尝试关闭，捕获错误但不中断
    swapoff /swapfile >/dev/null 2>&1
    
    # 删除文件
    if [ -f "/swapfile" ]; then
        rm -f /swapfile
        echo -e "已删除旧文件 /swapfile"
    else
        echo -e "未发现旧文件，跳过删除。"
    fi
    
    # 清理 fstab
    sed -i '/\/swapfile/d' /etc/fstab
    
    echo -e "${GREEN}==> 环境清理完成。${NC}"
}

# ==========================================
# 核心函数：创建 Swap (带错误捕获)
# ==========================================
function create_swap() {
    # 1. 输入验证
    echo -e "${YELLOW}请输入 Swap 大小 (单位: MB)${NC}"
    read -p "推荐输入 1024 (即1GB): " SWAP_SIZE

    if ! [[ "$SWAP_SIZE" =~ ^[0-9]+$ ]]; then
        show_result "fail" "输入的数值非法，请输入纯数字。"
        return
    fi

    echo -e "${YELLOW}---> [创建] 正在分配磁盘空间 (${SWAP_SIZE} MB)...${NC}"

    # 2. 检测文件系统 & 创建文件
    FS_TYPE=$(df -T / | tail -n 1 | awk '{print $2}')
    
    if [[ "$FS_TYPE" == "btrfs" ]]; then
        echo -e "${SKY}提示: 检测到 Btrfs 文件系统，启用 CoW 禁用策略...${NC}"
        truncate -s 0 /swapfile
        chattr +C /swapfile
        DD_OUT=$(dd if=/dev/zero of=/swapfile bs=1M count=$SWAP_SIZE status=progress 2>&1)
    else
        echo -e "${SKY}提示: 常规文件系统 (${FS_TYPE})...${NC}"
        DD_OUT=$(dd if=/dev/zero of=/swapfile bs=1M count=$SWAP_SIZE status=progress 2>&1)
    fi

    # 检查 dd 是否成功
    if [ $? -ne 0 ]; then
        show_result "fail" "磁盘文件创建失败。\n系统报错: $DD_OUT"
        return
    fi

    # 3. 授权
    chmod 600 /swapfile

    # 4. 格式化 (mkswap)
    echo -e "${YELLOW}---> [格式化] 正在格式化 Swap...${NC}"
    MK_OUT=$(mkswap /swapfile 2>&1)
    if [ $? -ne 0 ]; then
        show_result "fail" "格式化失败。\n系统报错: $MK_OUT"
        return
    fi

    # 5. 挂载 (swapon)
    echo -e "${YELLOW}---> [挂载] 正在启用 Swap...${NC}"
    SWAPON_OUT=$(swapon /swapfile 2>&1)
    if [ $? -ne 0 ]; then
        rm -f /swapfile
        show_result "fail" "无法启用 Swap (swapon 失败)。\n系统报错: $SWAPON_OUT"
        return
    fi

    # 6. 写入 fstab (持久化)
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    
    show_result "success" "Swap 已成功挂载并设置开机自启！"
}

# ==========================================
# 逻辑封装
# ==========================================
function action_add() {
    remove_swap
    create_swap
}

function action_reset() {
    echo -e "${RED}!!! 强制重置模式 !!!${NC}"
    echo -e "将无视当前状态，强制删除并重新创建 Swap。"
    remove_swap
    create_swap
}

function action_del() {
    remove_swap
    echo ""
    echo -e "========================================"
    echo -e "${GREEN}★  删除成功！${NC}"
    echo -e "所有 Swap 相关配置已清除。"
    echo -e "========================================"
    free -h
}

# ==========================================
# 主菜单
# ==========================================
clear
echo -e "${SKY}#############################################${NC}"
echo -e "${SKY}#    Linux VPS 智能 Swap 管理脚本           #${NC}"
echo -e "${SKY}#    支持 Debian/Ubuntu/CentOS + Btrfs      #${NC}"
echo -e "${SKY}#############################################${NC}"
echo ""
echo -e " 1. 添加 Swap (智能模式)"
echo -e " 2. 删除 Swap (彻底卸载)"
echo -e " 3. 强制重置 Swap (修复报错专用)"
echo -e " 0. 退出"
echo ""
read -p "请输入数字 [0-3]: " choice

case $choice in
    1) action_add ;;
    2) action_del ;;
    3) action_reset ;;
    0) exit 0 ;;
    *) echo -e "${RED}无效输入，退出...${NC}" ;;
esac
