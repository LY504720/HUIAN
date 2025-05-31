#!/bin/bash

# HUIAN项目更新脚本
# 作者：LY504720
# 用法：直接运行 ./update.sh 或 sudo ./update.sh (如果需要权限)

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"

# 定义颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # 恢复默认颜色

# 检查是否在正确的目录结构下（检测../../../HUIAN是否存在）
HUIAN_PARENT_DIR="$(realpath "$(dirname "$0")/../../../")"
HUIAN_DIR="$HUIAN_PARENT_DIR/HUIAN"

if [[ ! -d "$HUIAN_DIR" ]]; then
    echo -e "${RED}错误：未在正确的目录结构下执行此脚本${NC}"
    echo -e "请确保在包含HUIAN项目的目录结构中运行"
    echo -e "期望的HUIAN项目路径: $HUIAN_DIR"
    exit 1
fi

# 项目仓库URL
REPO_URL="https://github.com/LY504720/HUIAN.git"
# 使用检测到的HUIAN目录
PROJECT_DIR="$HUIAN_DIR"

echo -e "${YELLOW}开始更新HUIAN项目...${NC}"

if [[ -d "$PROJECT_DIR" ]]; then
    cd "$PROJECT_DIR" || exit 1
    
    if [[ -d ".git" ]]; then
        # 现有仓库：拉取更新
        echo -e "${GREEN}找到现有仓库，开始拉取最新更改...${NC}"
        CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
        echo -e "当前分支: ${YELLOW}$CURRENT_BRANCH${NC}"
        git pull origin "$CURRENT_BRANCH"
        
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}项目更新成功！${NC}"
        else
            echo -e "${RED}错误：拉取更新失败${NC}"
            exit 1
        fi
    else
        # 处理非Git目录：备份并重新克隆
        echo -e "${YELLOW}警告：目录存在但不是Git仓库${NC}"
        echo -e "${YELLOW}正在备份并重新克隆...${NC}"
        
        # 创建备份目录名（带时间戳）
        BACKUP_DIR="${PROJECT_DIR}_backup_$(date +%Y%m%d%H%M%S)"
        
        # 移动旧目录
        mv -v "$PROJECT_DIR" "$BACKUP_DIR" || {
            echo -e "${RED}错误：备份目录失败，请检查权限${NC}"
            exit 1
        }
        
        echo -e "原目录已备份至: ${YELLOW}$BACKUP_DIR${NC}"
        
        # 重新克隆
        git clone "$REPO_URL" "$PROJECT_DIR"
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}项目克隆成功！${NC}"
        else
            echo -e "${RED}错误：克隆项目失败${NC}"
            exit 1
        fi
    fi
else
    # 目录不存在：全新克隆
    echo -e "${YELLOW}项目目录不存在，执行全新克隆...${NC}"
    git clone "$REPO_URL" "$PROJECT_DIR"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}项目克隆成功！${NC}"
    else
        echo -e "${RED}错误：克隆项目失败${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}操作完成！${NC}"
exit 0