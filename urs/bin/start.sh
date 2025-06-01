#!/bin/bash

source /home/HUIAN/data/venv/bin/activate

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"
#主界面
#====================== 配置区 ======================
text_banner="欢迎使用绘安菜单"
text_greeting="请选择要执行的操作"
text_prompt="导航：↑/↓ 选择 | ← 退出 | → 确认 | ? 帮助"
menu_title="主菜单选项"

#====================== 函数区 ======================
source ../color.sh

# 配置菜单项
menu_items=(
    "${color_lv}:设置:option1_func"
    "${color_qing}:关于:option2_func"
    "${color_fen}:更新:option3_func"
    "${color_hong}:退出系统:exit_func"
)

# 动态添加ComfyUI菜单项
(cd ../../data && [ -d "ComfyUI" ]) && \
    menu_items=( "\033[38;5;214m:ComfyUI:comfy_func" "${menu_items[@]}") || \
    menu_items=( "\033[38;5;214m:ComfyUI(未安装):comfy_func" "${menu_items[@]}")

comfy_func() {
    clear
    if [ -d "../../data/ComfyUI" ]; then
        bash comfyui/start.sh
    else
        echo "安装ComfyUI..."
        cd ../../data
        mgit clone https://github.com/comfyanonymous/ComfyUI
    fi
}

option1_func() {
    clear
    bash sitt.sh
}

option2_func() {
    clear
    bash about.sh
}

option3_func() {
    clear
clear
    bash update.sh
    read -n 1 -s -r -p "按任意键返回主菜单..."
}

exit_func() {
    clear
    echo -e "${color_frame}正在安全退出系统..."
    echo "感谢您的使用！"
    sleep 0.3
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
