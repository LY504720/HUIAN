#!/bin/bash

#====================== 配置区 ======================
yes_label="确认重置"  # 右侧确认选项文字
no_label="放弃操作"   # 左侧取消选项文字
default_selection=1   # 默认选中项 (0:No 1:Yes)

color_frame="\033[38;5;214m"  # 金色边框
color_title="\033[34m"        # 蓝色标题
color_highlight="\033[1;35m"  # 加粗紫色高亮
color_normal="\033[0m"        # 默认颜色

dialog_title="危险操作确认"
dialog_prompt="您确定要执行此操作吗？"
hint_text="导航：←/→ 切换 | Enter确认"


confirm_action() {
    clear
    echo -e "${color_title}=== 操作已确认 ===${color_normal}"
    echo "正在执行敏感操作..."
    echo "当前虚拟环境路径：$VIRTUAL_ENV"
    echo "正在删除旧环境"
    rm -rf /home/HUIAN/date/venv
    cd /home/HUIAN/data
    echo "正在创建新环境"
    python3 -m venv venv
    source /home/HUIAN/data/venv/bin/activate
    echo "并未安装依赖，请到 主页面→设置→环境管理→***环境修复 以安装对应环境依赖"
    echo -e "\n操作成功完成！"
    read -n 1 -s -r -p "按任意键退出..."
    exit 0
}

cancel_action() {
    clear
    echo -e "${color_title}=== 操作已取消 ===${color_normal}"
    echo "正在安全取消操作..."
    exit 1
}
source ../qd.sh