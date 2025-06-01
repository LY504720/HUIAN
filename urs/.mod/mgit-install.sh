#!/bin/bash

# ====================== GitHub 镜像加速工具安装脚本 ======================
# 功能：将 mgit.sh 安装到系统目录 /usr/local/bin/mgit
# 用法：sudo ./install-mgit.sh [mgit.sh路径]
# 特点：自动搜索上一级目录的 mgit.sh
# ======================================================================

# 检查是否为 root 用户
if [ "$(id -u)" -ne 0 ]; then
    echo "请使用 sudo 运行此脚本:"
    echo "  sudo $0"
    exit 1
fi

# 安装路径
INSTALL_PATH="/usr/local/bin/mgit"

# 检查是否已安装 - 如果存在直接退出
if [ -f "$INSTALL_PATH" ]; then
    echo "检测到已安装的 mgit: $INSTALL_PATH"
    echo "安装已取消（已存在安装）"
    exit 0
fi

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 确定 mgit.sh 文件位置
if [ -n "$1" ]; then
    SOURCE_FILE="$1"
else
    # 尝试在多个位置查找
    POSSIBLE_PATHS=(
        "$SCRIPT_DIR/mgit.sh"             # 当前目录
        "$SCRIPT_DIR/../mgit.sh"          # 上一级目录
        "$SCRIPT_DIR/../../mgit.sh"       # 上两级目录
        "./mgit.sh"                       # 当前工作目录
    )
    
    SOURCE_FILE=""
    for path in "${POSSIBLE_PATHS[@]}"; do
        if [ -f "$path" ]; then
            SOURCE_FILE="$path"
            break
        fi
    done
    
    if [ -z "$SOURCE_FILE" ]; then
        echo "未找到 mgit.sh 文件，请指定路径:"
        echo "  sudo $0 /path/to/mgit.sh"
        exit 1
    fi
fi

# 验证源文件是否存在
if [ ! -f "$SOURCE_FILE" ]; then
    echo "错误：文件不存在 - $SOURCE_FILE"
    exit 1
fi

echo "正在安装 GitHub 镜像加速工具..."
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
    # 如果已有版本信息则更新
    sed -i "s/^VERSION=.*/VERSION=\"$(date +%Y.%m.%d)\"/" "$INSTALL_PATH"
else
    # 添加版本信息
    sed -i "2i# VERSION=\"$(date +%Y.%m.%d)\"" "$INSTALL_PATH"
fi

# 检查依赖
echo ""
echo "检查依赖..."
MISSING_DEPS=()
command -v git >/dev/null 2>&1 || MISSING_DEPS+=("git")
command -v curl >/dev/null 2>&1 || MISSING_DEPS+=("curl")
command -v wget >/dev/null 2>&1 || MISSING_DEPS+=("wget")

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo "警告：缺少以下依赖: ${MISSING_DEPS[*]}"
    echo "mgit 需要这些工具才能正常工作"
    echo "请使用以下命令安装:"
    
    if command -v apt >/dev/null 2>&1; then
        echo "  sudo apt install ${MISSING_DEPS[*]}"
    elif command -v yum >/dev/null 2>&1; then
        echo "  sudo yum install ${MISSING_DEPS[*]}"
    elif command -v brew >/dev/null 2>&1; then
        echo "  brew install ${MISSING_DEPS[*]}"
    else
        echo "请根据您的系统手动安装: ${MISSING_DEPS[*]}"
    fi
else
    echo "所有依赖已满足"
fi

# 验证安装
echo ""
echo "安装成功！"
echo "验证安装:"
mgit || {
    echo "验证失败！请检查安装"
    exit 1
}

echo ""
echo "使用示例:"
echo "  克隆仓库: mgit clone https://github.com/user/repo.git"
echo "  下载文件: mgit -O file.zip https://github.com/user/repo/releases/file.zip"
echo "  测试镜像: mgit --test"
echo ""
echo "要卸载请使用: sudo rm $INSTALL_PATH"
