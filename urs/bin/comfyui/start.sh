#!/bin/bash
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"

#====================== 配置区 ======================
text_banner="ComfyUI 管理菜单"
text_greeting="请选择要执行的操作"
text_prompt="导航：↑/↓ 选择 | ← 退出 | → 确认 | ? 帮助"
menu_title="主菜单"

#====================== 函数区 ======================
# 引入颜色定义
source ../../color.sh

# 配置菜单项
menu_items=(
    "${color_lv}:启动ComfyUI:launch_comfyui"
    "${color_qing}:模型管理:manage_models"
    "${color_fen}:安装插件管理器:manage_plugins"
)

#====================== ComfyUI 功能函数 ======================
launch_comfyui() {
    clear
    
    bash open.sh
}

manage_models() {
    clear
    
    bash model.sh
    
}

manage_plugins() {
    clear
    bash node.sh
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
    echo -e "${color_help}这是一个ComfyUI管理菜单，使用方向键导航，回车键确认。"
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

#====================== 引入菜单框架 ======================
# 设置菜单框架所需颜色变量
color_frame="${color_jin}"     # 金色边框
color_title="${color_lan}"     # 蓝色标题
color_highlight="${color_zi}"  # 紫色高亮
color_normal="${color_mo}"     # 默认颜色
color_prompt="${color_qing}"   # 青色提示
color_help="${color_huang}"    # 黄色帮助文本

# 引入菜单框架
source ../../xz.sh