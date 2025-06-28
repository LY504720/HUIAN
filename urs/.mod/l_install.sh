#!/bin/bash

# ====================== LSH 加速工具安装脚本 ======================
# 功能：将 l.sh 安装到系统目录 /usr/local/bin/lsh
# 用法：sudo ./install-lsh.sh [l.sh路径]
# 特点：自动搜索上一级目录的 l.sh
# ======================================================================

# 检查是否为 root 用户
if [ "$(id -u)" -ne 0 ]; then
    echo "请使用 sudo 运行此脚本:"
    echo "  sudo $0"
    exit 1
fi

# 安装路径
INSTALL_PATH="/usr/local/bin/lsh"

# 检查是否已安装
if [ -f "$INSTALL_PATH" ]; then
    echo "检测到已安装的 lsh: $INSTALL_PATH"
    echo "安装已取消（已存在安装）"
    exit 0
fi

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 确定 l.sh 文件位置
if [ -n "$1" ]; then
    SOURCE_FILE="$1"
else
    POSSIBLE_PATHS=(
        "$SCRIPT_DIR/l.sh"             # 当前目录
        "$SCRIPT_DIR/../l.sh"          # 上一级目录
        "$SCRIPT_DIR/../../l.sh"       # 上两级目录
        "./l.sh"                       # 当前工作目录
    )
    
    SOURCE_FILE=""
    for path in "${POSSIBLE_PATHS[@]}"; do
        if [ -f "$path" ]; then
            SOURCE_FILE="$path"
            break
        fi
    done
    
    if [ -z "$SOURCE_FILE" ]; then
        echo "未找到 l.sh 文件，请指定路径:"
        echo "  sudo $0 /path/to/l.sh"
        exit 1
    fi
fi

# 验证源文件是否存在
if [ ! -f "$SOURCE_FILE" ]; then
    echo "错误：文件不存在 - $SOURCE_FILE"
    exit 1
fi

echo "正在安装 LSH 加速工具..."
echo "源文件: $SOURCE_FILE"
echo "安装到: $INSTALL_PATH"

# 复制文件
cp -v "$SOURCE_FILE" "$INSTALL_PATH" || {
    echo "复制文件失败！"
    exit 1
}

# 修改解释器为 bash
sed -i '1s|^.*$|#!/usr/bin/env bash|' "$INSTALL_PATH" || {
    echo "修改解释器失败！"
    exit 1
}

# 添加执行权限
chmod -v +x "$INSTALL_PATH" || {
    echo "添加执行权限失败！"
    exit 1
}

# 添加版本信息
echo "添加版本标识..."
if grep -q "VERSION=" "$INSTALL_PATH"; then
    sed -i "s/^VERSION=.*/VERSION=\"$(date +%Y.%m.%d)\"/" "$INSTALL_PATH"
else
    sed -i "2i# VERSION=\"$(date +%Y.%m.%d)\"" "$INSTALL_PATH"
fi

# 检查依赖（示例，根据实际需求修改）
echo ""
echo "检查依赖..."
MISSING_DEPS=()
# command -v some_dependency >/dev/null 2>&1 || MISSING_DEPS+=("some_dependency")

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo "警告：缺少以下依赖: ${MISSING_DEPS[*]}"
    echo "请根据系统安装相应工具"
else
    echo "所有依赖已满足"
fi



echo ""
echo "使用示例:"
echo "  lsh 命令选项"
echo ""
echo "要卸载请使用: sudo rm $INSTALL_PATH"
