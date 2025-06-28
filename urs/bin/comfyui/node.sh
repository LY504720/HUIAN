#!/bin/bash
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"
#主界面
#====================== 配置区 ======================
text_banner="欢迎使用绘安菜单"
text_greeting="请选择要执行的操作"
text_prompt="导航：↑/↓ 选择 | ← 退出 | → 确认 | ? 帮助"
menu_title="启动选项"

#====================== 函数区 ======================
source ../../color.sh

# 配置菜单项
menu_items=(
    "${color_lv}:安装节点管理器:option1_func"
    "${color_qing}:更新节点管理器:option2_func"
    "${color_fen}:安全级别管理:option3_func"
    "${color_hong}:尝试从GitHub获取已编译的comftui:option4_func"
)


option1_func() {
    clear
    cd ../../../data/ComfyUI/custom_nodes/
    mgit clone https://github.com/ltdrdata/ComfyUI-Manager.git
    echo 安装完成
    read -n 1 -s -r
}

option2_func() {
    cd ../../../data/ComfyUI/custom_nodes/ComfyUI-Manager/
    mgit pull origin main
    echo 更新完成
    read -n 1 -s -r
}

option3_func() {
    clear
    bash node-qx.sh --security-menu
}

option4_func() {
    clear
    echo 正在施工...
    
    read -n 1 -s -r
}

exit_func() {
    clear
    echo -e "\e[0m"
    exit 0
}


help_func() {
    clear
    echo -e "${color_title}=== 帮助信息 ===${color_normal}"
    echo -e "${color_help}这是一个菜单导航系统，使用方向键进行操作："
    echo -e "  ↑     - 向上移动光标"
    echo -e "  ↓     - 向下移动光标"
    echo -e "  ←     - 退出系统"
    echo -e "  →/回车 - 确认当前选项"
    echo -e "  ?     - 显示此帮助信息（支持中文问号？）"
    echo
  
    echo -e "${color_prompt}按任意键返回主菜单...${color_normal}"
    read -n 1 -s -r
}

help_open() {
    echo -e "这里什么都没有"
    echo -e "${color_prompt}按任意键继续...${color_normal}"
    read -n 1 -s -r
}

source ../../xz.sh