#!/bin/bash

# =========================================================
# System: Debian/Ubuntu/CentOS/AlmaLinux/Rocky Linux
# Description: Smart Swap Manager with Btrfs Support
# Version: 2.1 (Stable)
# Author: K23Flux
# =========================================================

set -o pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
SKY='\033[0;36m'
NC='\033[0m'

SWAP_FILE="/swapfile"
FSTAB_FILE="/etc/fstab"
FSTAB_ENTRY="/swapfile none swap sw 0 0"
MIN_FREE_BUFFER_MB=64

function info() {
    echo -e "${SKY}$1${NC}"
}

function warn() {
    echo -e "${YELLOW}$1${NC}"
}

function error() {
    echo -e "${RED}$1${NC}"
}

function ensure_root() {
    if [ "$EUID" -ne 0 ]; then
        error "错误：请使用 root 权限运行此脚本！例如 sudo -i 后再执行。"
        exit 1
    fi
}

function require_commands() {
    local missing=()
    local commands=(awk chmod cp date dd df free grep mkswap rm sed swapon swapoff truncate)

    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    if [ "${#missing[@]}" -gt 0 ]; then
        error "缺少必要命令：${missing[*]}"
        error "请先安装 util-linux、coreutils 等基础系统工具后再运行。"
        exit 1
    fi
}

function show_swap_status() {
    echo -e "----------------------------------------"
    echo -e "当前 Swap 状态："
    swapon --show 2>/dev/null || true
    echo -e "----------------------------------------"
    echo -e "当前内存状态："
    free -h
}

function show_result() {
    local status=$1
    local msg=$2

    echo ""
    echo -e "========================================"
    if [ "$status" == "success" ]; then
        echo -e "${GREEN}★ 操作成功！${NC}"
        echo -e "${GREEN}★ $msg${NC}"
        show_swap_status
    else
        echo -e "${RED}❌ 操作失败！${NC}"
        echo -e "${RED}原因分析: $msg${NC}"
        echo -e "${YELLOW}提示：OpenVZ、部分 LXC 容器或宿主机禁用 Swap 时，可能无法启用 Swap。${NC}"
    fi
    echo -e "========================================"
}

function backup_fstab() {
    local backup_file="${FSTAB_FILE}.bak.$(date +%Y%m%d%H%M%S)"

    if [ ! -f "$FSTAB_FILE" ]; then
        show_result "fail" "未找到 $FSTAB_FILE，无法写入开机自启配置。"
        return 1
    fi

    if ! cp "$FSTAB_FILE" "$backup_file"; then
        show_result "fail" "备份 $FSTAB_FILE 失败，请检查权限或文件系统状态。"
        return 1
    fi

    echo -e "已备份 $FSTAB_FILE 到 $backup_file"
}

function clean_fstab_entry() {
    backup_fstab || return 1
    sed -i '\|^[[:space:]]*/swapfile[[:space:]]|d' "$FSTAB_FILE"
}

function add_fstab_entry() {
    if grep -Eq '^[[:space:]]*/swapfile[[:space:]]+none[[:space:]]+swap[[:space:]]' "$FSTAB_FILE"; then
        echo -e "$FSTAB_FILE 已存在 /swapfile 配置，跳过追加。"
        return 0
    fi

    backup_fstab || return 1
    echo "$FSTAB_ENTRY" >> "$FSTAB_FILE"
}

function get_root_fs_type() {
    if command -v findmnt >/dev/null 2>&1; then
        findmnt -no FSTYPE /
    else
        df -T / | sed -n '2p' | awk '{print $2}'
    fi
}

function get_available_mb() {
    df -Pm / | sed -n '2p' | awk '{print $4}'
}

function validate_swap_size() {
    local swap_size=$1
    local available_mb
    local required_mb

    if ! [[ "$swap_size" =~ ^[0-9]+$ ]] || [ "$swap_size" -le 0 ]; then
        show_result "fail" "输入的数值非法，请输入大于 0 的纯数字。"
        return 1
    fi

    available_mb=$(get_available_mb)
    required_mb=$((swap_size + MIN_FREE_BUFFER_MB))

    if ! [[ "$available_mb" =~ ^[0-9]+$ ]]; then
        show_result "fail" "无法检测根分区可用空间。"
        return 1
    fi

    if [ "$available_mb" -lt "$required_mb" ]; then
        show_result "fail" "磁盘空间不足。需要至少 ${required_mb} MB，当前仅剩 ${available_mb} MB。"
        return 1
    fi
}

function dd_supports_progress() {
    dd --help 2>&1 | grep -q 'status='
}

function create_file_with_dd() {
    local swap_size=$1

    if dd_supports_progress; then
        dd if=/dev/zero of="$SWAP_FILE" bs=1M count="$swap_size" status=progress 2>&1
    else
        dd if=/dev/zero of="$SWAP_FILE" bs=1M count="$swap_size" 2>&1
    fi
}

function create_btrfs_swap_file() {
    local swap_size=$1
    local out

    if command -v btrfs >/dev/null 2>&1; then
        out=$(btrfs filesystem mkswapfile --size "${swap_size}m" "$SWAP_FILE" 2>&1)
        if [ $? -eq 0 ]; then
            chmod 600 "$SWAP_FILE"
            echo "BTRFS_MKSWAPFILE_OK"
            echo "$out"
            return 0
        fi

        warn "btrfs mkswapfile 不可用或执行失败，尝试 chattr +C 兼容方案。"
        echo "$out"
        rm -f "$SWAP_FILE"
    fi

    if ! command -v chattr >/dev/null 2>&1; then
        show_result "fail" "Btrfs 文件系统需要 btrfs 或 chattr 命令来安全创建 Swap。"
        return 1
    fi

    truncate -s 0 "$SWAP_FILE" || return 1
    chattr +C "$SWAP_FILE" || return 1
    create_file_with_dd "$swap_size"
}

function create_regular_swap_file() {
    local swap_size=$1
    create_file_with_dd "$swap_size"
}

function remove_swap() {
    warn "---> [清理] 正在检测并卸载旧 Swap..."

    if swapon --show=NAME --noheadings 2>/dev/null | grep -Fxq "$SWAP_FILE"; then
        if ! swapoff "$SWAP_FILE"; then
            show_result "fail" "无法卸载 $SWAP_FILE，请确认没有系统策略阻止 swapoff。"
            return 1
        fi
        echo -e "已卸载 $SWAP_FILE"
    fi

    if [ -f "$SWAP_FILE" ]; then
        rm -f "$SWAP_FILE"
        echo -e "已删除旧文件 $SWAP_FILE"
    else
        echo -e "未发现旧文件，跳过删除。"
    fi

    clean_fstab_entry || return 1
    echo -e "${GREEN}==> 环境清理完成。${NC}"
}

function create_swap() {
    local swap_size
    local fs_type
    local create_out
    local mk_out
    local swapon_out
    local need_mkswap=1

    warn "请输入 Swap 大小 (单位: MB)"
    read -r -p "推荐输入 1024 (即 1GB): " swap_size

    validate_swap_size "$swap_size" || return 1

    fs_type=$(get_root_fs_type)
    warn "---> [创建] 正在分配磁盘空间 (${swap_size} MB)..."

    if [ "$fs_type" == "btrfs" ]; then
        info "提示: 检测到 Btrfs 文件系统，启用专用 Swap 创建策略。"
        create_out=$(create_btrfs_swap_file "$swap_size" 2>&1)
        if [ $? -ne 0 ]; then
            rm -f "$SWAP_FILE"
            show_result "fail" "磁盘文件创建失败。\n系统报错: $create_out"
            return 1
        fi

        if grep -q '^BTRFS_MKSWAPFILE_OK$' <<< "$create_out"; then
            need_mkswap=0
        fi
    else
        info "提示: 常规文件系统 (${fs_type:-unknown})。"
        create_out=$(create_regular_swap_file "$swap_size" 2>&1)
        if [ $? -ne 0 ]; then
            rm -f "$SWAP_FILE"
            show_result "fail" "磁盘文件创建失败。\n系统报错: $create_out"
            return 1
        fi
    fi

    chmod 600 "$SWAP_FILE"

    if [ "$need_mkswap" -eq 1 ]; then
        warn "---> [格式化] 正在格式化 Swap..."
        mk_out=$(mkswap "$SWAP_FILE" 2>&1)
        if [ $? -ne 0 ]; then
            rm -f "$SWAP_FILE"
            show_result "fail" "格式化失败。\n系统报错: $mk_out"
            return 1
        fi
    fi

    warn "---> [挂载] 正在启用 Swap..."
    swapon_out=$(swapon "$SWAP_FILE" 2>&1)
    if [ $? -ne 0 ]; then
        rm -f "$SWAP_FILE"
        show_result "fail" "无法启用 Swap (swapon 失败)。\n系统报错: $swapon_out"
        return 1
    fi

    add_fstab_entry || return 1
    show_result "success" "Swap 已成功挂载并设置开机自启！"
}

function action_add() {
    remove_swap || return 1
    create_swap
}

function action_reset() {
    error "!!! 强制重置模式 !!!"
    echo -e "将无视当前状态，强制删除并重新创建 $SWAP_FILE。"
    remove_swap || return 1
    create_swap
}

function action_del() {
    remove_swap || return 1
    show_result "success" "所有 Swap 相关配置已清除。"
}

ensure_root
require_commands

if command -v clear >/dev/null 2>&1; then
    clear
fi
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
read -r -p "请输入数字 [0-3]: " choice

case $choice in
    1) action_add ;;
    2) action_del ;;
    3) action_reset ;;
    0) exit 0 ;;
    *) error "无效输入，退出..." ;;
esac
