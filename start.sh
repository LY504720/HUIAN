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


#!/bin/bash

# 要检测的目标字符串
TARGET_ALIAS="alias mgit='bash /home/HUIAN/urs/mgit.sh'"

# 查找 ~/.bashrc 文件
BASHRC_PATH="$HOME/.bashrc"

# 检查文件是否存在
if [ ! -f "$BASHRC_PATH" ]; then
    echo "警告: 未找到 ~/.bashrc 文件"
    exit 1
fi

# 检测别名是否存在
if grep -qF "$TARGET_ALIAS" "$BASHRC_PATH"; then
    echo -e "\e[32m检测成功: \e[0m别名已设置"
    
else
    echo -e "\e[31m检测失败: \e[0m未找到匹配的别名设置"
    
    # 显示修改说明
    echo -e "\n请手动修改 \e[1m~/.bashrc\e[0m 文件:"
    echo -e "1. 使用以下命令打开文件:"
    echo -e "   \e[35mnano ~/.bashrc\e[0m 或 \e[35mvi ~/.bashrc\e[0m"
    echo -e "2. 在文件末尾添加以下内容:"
    echo -e "\e[33m$TARGET_ALIAS\e[0m"
    echo -e "3. 保存文件并退出编辑器"
    echo -e "4. 应用更改:"
    echo -e "   \e[35msource ~/.bashrc\e[0m"
    
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