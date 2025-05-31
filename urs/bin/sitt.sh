#!/bin/bash
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"
#主界面
#====================== 配置区 ======================
text_banner="欢迎使用绘安菜单"
text_greeting="请选择要执行的操作"
text_prompt="导航：↑/↓ 选择 | ← 退出 | → 确认 | ? 帮助"
menu_title="设置选项"

#====================== 函数区 ======================
source ../color.sh

# 配置菜单项
menu_items=(
    "${color_lv}:环境管理:option1_func"
    "${color_qing}:难疑解答:option2_func"
)


option1_func() {
    clear
    bash python.sh
}

option2_func() {
    clear
    echo 正在施工......
    read -n 1 -s -r
}

option3_func() {
    clear
    
}

option4_func() {
    clear
    
}

exit_func() {
    clear
    echo -e "\e[0m"
    exit 0
}

help_func() {
    clear
    echo -e "${color_title}=== 帮助信息 ===${color_normal}"
    echo -e "${color_help}这是一个菜单示例程序，使用方向键导航，回车键确认。"
    echo -e "支持的按键操作："
    echo -e "  ↑/↓  - 上下移动选择菜单项"
    echo -e "  ←    - 退出系统"
    echo -e "  →/回车 - 确认当前选择"
    echo -e "  ?    - 显示此帮助信息"
    echo -e "  ？   - 中文问号同样显示帮助${color_normal}"
    echo
    echo -e "${color_prompt}按任意键返回主菜单...${color_normal}"
    read -n 1 -s -r
}

help_open() {
    echo -e "这里什么都没有"
    echo -e "${color_prompt}按任意键继续...${color_normal}"
    read -n 1 -s -r
}

source ../xz.sh