#!/bin/bash

# HUIAN 项目启动脚本
# 作者：LY504720
# 功能：检查并创建数据目录，然后启动应用

# 定义颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # 恢复默认颜色

# 获取脚本所在目录
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"

# 检查数据目录是否存在
DATA_DIR="data"

echo -e "${YELLOW}检查数据目录...${NC}"

if [[ -d "$DATA_DIR" ]]; then
    echo -e "${GREEN}数据目录已存在: $DATA_DIR${NC}"
else
    echo -e "${YELLOW}数据目录不存在，正在创建...${NC}"
    
    # 创建数据目录
    mkdir -p "$DATA_DIR"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}数据目录创建成功: $DATA_DIR${NC}"
    else
        echo -e "${RED}错误：无法创建数据目录${NC}"
        echo -e "请检查目录权限或磁盘空间"
        exit 1
    fi
fi

# 检查启动脚本是否存在
START_SCRIPT="urs/bin/start.sh"

if [[ ! -f "$START_SCRIPT" ]]; then
    echo -e "${RED}错误：启动脚本不存在: $START_SCRIPT${NC}"
    echo -e "请确保项目已正确安装"
    exit 1
fi

# 执行启动脚本
bash "$START_SCRIPT"

# 检查启动结果
if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}--------------------------------------${NC}"
    echo -e "${GREEN}  HUIAN 应用已正常退出 ${NC}"
    echo -e "${GREEN}--------------------------------------${NC}"
else
    echo -e "${RED}--------------------------------------${NC}"
    echo -e "${RED}  HUIAN 应用异常退出 ${NC}"
    echo -e "${RED}--------------------------------------${NC}"
    exit 1
fi

exit 0