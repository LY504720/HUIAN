#!/bin/bash

# HUIAN项目更新脚本 (urs/bin/版本)
# 作者：LY504720
# 版本：2.1（专为urs/bin目录设计）
# 用法：在项目根目录运行 ./urs/bin/update.sh

# 定义颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # 恢复默认颜色

# 获取项目根目录（从urs/bin向上三级）
PROJECT_ROOT="$(realpath "$(dirname "${BASH_SOURCE[0]}")/../..")"

# 验证项目根目录
if [[ ! -d "$PROJECT_ROOT" ]]; then
    echo -e "${RED}错误：无法确定项目根目录${NC}"
    echo -e "当前路径: $(pwd)"
    echo -e "计算的项目根目录: $PROJECT_ROOT"
    exit 1
fi

# 进入项目根目录
cd "$PROJECT_ROOT" || {
    echo -e "${RED}错误：无法进入项目根目录${NC}"
    exit 1
}

echo -e "${YELLOW}项目根目录: $PROJECT_ROOT${NC}"
echo -e "${YELLOW}开始更新HUIAN项目...${NC}"

# 项目仓库URL
REPO_URL="https://github.com/LY504720/HUIAN.git"

if [[ -d ".git" ]]; then
    echo -e "${GREEN}找到现有仓库，开始拉取最新更改...${NC}"
    
    # 获取当前分支
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    echo -e "当前分支: ${YELLOW}$CURRENT_BRANCH${NC}"
    
    # 重置所有本地修改
    echo -e "${YELLOW}重置本地修改...${NC}"
    git reset --hard HEAD
    
    # 备份并移除可能冲突的文件
    echo -e "${YELLOW}处理潜在冲突文件...${NC}"
    
    # 定义需要处理的冲突文件列表
    CONFLICT_FILES=("start.sh" "update.sh" "run.sh" "urs/bin/start.sh" "urs/bin/update.sh")
    
    for file in "${CONFLICT_FILES[@]}"; do
        if [[ -f "$file" && -z $(git ls-files "$file" 2>/dev/null) ]]; then
            # 文件存在且未被跟踪
            backup_file="${file}.backup_$(date +%Y%m%d%H%M%S)"
            echo -e "${YELLOW}备份未跟踪文件: $file → $backup_file${NC}"
            mkdir -p "$(dirname "$backup_file")"
            mv -v "$file" "$backup_file"
        fi
    done
    
    # 安全清理未跟踪文件（排除数据目录）
    echo -e "${YELLOW}清理未跟踪文件...${NC}"
    git clean -f -d --exclude=data/
    
    # 拉取更新
    mgit pull origin "$CURRENT_BRANCH"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}项目更新成功！${NC}"
        
        # 检查是否需要恢复自定义设置
        for file in "${CONFLICT_FILES[@]}"; do
            backup_file=$(ls -t ${file}.backup_* 2>/dev/null | head -1)
            if [[ -f "$backup_file" ]]; then
                echo -e "${YELLOW}检测到备份文件: $backup_file${NC}"
                echo -e "${YELLOW}请手动检查是否需要合并自定义修改到新版本文件: $file${NC}"
                echo -e "使用命令比较差异: diff -u $backup_file $file"
            fi
        done
        
        # 确保启动脚本有执行权限
        if [[ -f "urs/bin/start.sh" ]]; then
            chmod +x "urs/bin/start.sh"
        fi
        if [[ -f "urs/bin/update.sh" ]]; then
            chmod +x "urs/bin/update.sh"
        fi
    else
        echo -e "${RED}错误：拉取更新失败${NC}"
        exit 1
    fi
else
    # 处理非Git目录：备份并重新克隆
    echo -e "${YELLOW}警告：目录存在但不是Git仓库${NC}"
    echo -e "${YELLOW}正在备份并重新克隆...${NC}"
    
    # 创建备份目录名（带时间戳）
    BACKUP_DIR="${PROJECT_ROOT}_backup_$(date +%Y%m%d%H%M%S)"
    
    # 移动旧目录
    mv -v "$PROJECT_ROOT" "$BACKUP_DIR" || {
        echo -e "${RED}错误：备份目录失败，请检查权限${NC}"
        exit 1
    }
    
    echo -e "原目录已备份至: ${YELLOW}$BACKUP_DIR${NC}"
    
    # 重新克隆
    mgit clone "$REPO_URL" "$PROJECT_ROOT"
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}项目克隆成功！${NC}"
        
        # 设置脚本权限
        chmod +x "$PROJECT_ROOT/urs/bin/"*.sh
    else
        echo -e "${RED}错误：克隆项目失败${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}操作完成！${NC}"
exit 0
