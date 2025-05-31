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
    "${color_lv}:速度优先:option1_func"
    "${color_qing}:质量优先:option2_func"
    "${color_fen}:仅CPU:option3_func"
    "${color_hong}:自定义参数:option4_func"
)


option1_func() {
    clear
    cd ../../../data/ComfyUI && python3 main.py --cpu --disable-xformers --cpu-vae --disable-cuda-malloc --force-fp16 --fp8_e4m3fn-unet --disable-xformers --fp8_e4m3fn-text-enc --fast --disable-smart-memory --use-pytorch-cross-attention
    read -n 1 -s -r
}

option2_func() {
    cd ../../../data/ComfyUI && python3 main.py --cpu --disable-xformers --cpu-vae --disable-cuda-malloc --use-pytorch-cross-attention --force-fp16 --fp16-unet --disable-xformers --fp16-text-enc --fast --disable-smart-memory
    read -n 1 -s -r
}

option3_func() {
    clear
    cd ../../../data/ComfyUI && python3 main.py --cpu
    read -n 1 -s -r
}

option4_func() {
    clear
    bash open~.sh --customize
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
    echo -e "${color_help}启动选项说明："
    echo -e "  ${color_lv}速度优先${color_help}   - 启用CPU模式+优化参数（最快速度）"
    echo -e "  ${color_qing}质量优先${color_help}   - 启用CPU模式+高质量渲染参数"
    echo -e "  ${color_fen}仅CPU${color_help}      - 纯CPU模式（无GPU加速）"
    echo -e "  ${color_hong}自定义参数${color_help} - 打开高级参数配置界面"
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