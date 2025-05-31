#!/bin/bash
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"
#主界面
#====================== 配置区 ======================
text_banner="欢迎使用绘安菜单"
text_greeting="请选择要执行的操作"
text_prompt="导航：↑/↓ 选择 | ← 退出 | → 确认 | ? 帮助"
menu_title="环境管理选项"

#====================== 函数区 ======================
source ../color.sh

# 配置菜单项
menu_items=(
    "${color_lv}:环境自检:option1_func"
    "${color_qing}:重置Python环境:option2_func"
    "${color_fen}:torch安装:option3_func"
    "${color_hong}:comfyui环境修复:option4_func"
)


option1_func() {
    clear
    python3 python-zijian.py
    read -n 1 -s -r
}

option2_func() {
    bash python-chong.sh
    read -n 1 -s -r
}

option3_func() {
    clear
    echo "正在安装......"
    pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu --break-system-packages
    echo "安装结束"
    read -n 1 -s -r
}

option4_func() {
    clear
    cd ../../data/ComfyUI && pip install -r requirements.txt
    echo "安装结束"
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