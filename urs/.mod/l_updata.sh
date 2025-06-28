#!/bin/bash

# ====================== GitHub 镜像加速工具安装脚本 ======================
# 用法：sudo ./install-lsh.sh <lsh.sh路径>
# 注意：无任何检测，请确保路径正确
# ======================================================================
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"
SOURCE_FILE="../l.sh"
INSTALL_PATH="/usr/local/bin/lsh"

# 安装核心步骤
cp "../l.sh" "$INSTALL_PATH"
sed -i '1s|^.*$|#!/usr/bin/env bash|' "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"
sed -i "2i# Installed: $(date +%Y.%m.%d)" "$INSTALL_PATH"
rm l_updata.sh
echo "lsh初始化完成"