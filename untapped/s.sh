#!/bin/bash

#====================== 配置区 ======================
confirm_label="我已阅读知晓"   # 确认选项文字
default_selection=1           # 固定选中确认项

# 颜色配置
color_frame="\033[38;5;39m"   # 科技蓝边框
color_title="\033[1;36m"      # 青色标题
color_highlight="\033[1;33m"  # 黄色高亮
color_normal="\033[0m"        # 默认颜色
color_content="\033[37m"      # 灰色内容文本

# 通知内容配置
notice_title="重要系统通知"
notice_content=(
    "系统将于2023-08-30 03:00进行维护升级"
    "升级内容："
    "预计影响时长：2小时"
)
hint_text="提示：Enter键确认通知"

confirm_action() {
    clear
    echo -e "${color_title}=== 通知已确认 ===${color_normal}"
    echo "感谢您的确认，系统维护期间可能出现服务中断"
    read -n 1 -s -r -p "按任意键退出..."
    exit 0
}

#====================== 函数区 ======================
draw_line() {
    printf "${color_frame}"
    printf "+%*s+" $(($1 - 2)) | tr ' ' '-'
    printf "${color_normal}\n"
}

center_text() {
    local text=$1
    local color=$2
    local cols=$3
    printf "${color}%*s${color_normal}\n" $(( (${#text} + cols) / 2 )) "$text"
}

draw_button() {
    local cols=$1
    local btn_width=$((cols / 4))
    
    # 定位到按钮绘制行（通知内容下方）
    printf "\033[$((content_start_line + ${#notice_content[@]} + 2));1H"
    
    # 绘制居中确认按钮
    printf "%*s" $(( (cols - btn_width) / 2 )) ""
    printf "${color_highlight}► %s ◄${color_normal}" "$confirm_label"
    
    # 移动光标到底部提示区下方
    printf "\033[$((content_start_line + ${#notice_content[@]} + 5));1H"
}

display_content() {
    local cols=$1
    # 显示通知内容
    for line in "${notice_content[@]}"; do
        printf "${color_content}%*s${color_normal}\n" $(( (${#line} + cols) / 2 )) "$line"
    done
}

display() {
    local current_cols=$(tput cols)
    local current_lines=$(tput lines)

    if [[ $current_cols -ne $last_cols || $current_lines -ne $last_lines ]]; then
        clear
        last_cols=$current_cols
        last_lines=$current_lines
        
        # 顶部框架
        draw_line $current_cols
        center_text "$notice_title" "$color_title" $current_cols
        draw_line $current_cols
        
        # 内容显示区域
        content_start_line=4
        printf "\033[4;1H"  # 定位到第4行
        display_content $current_cols

        # 按钮区域
        draw_button $current_cols
        
        # 底部提示
        printf "\n"
        draw_line $current_cols
        center_text "$hint_text" "$color_normal" $current_cols
    fi
}


#====================== 核心逻辑 ======================
last_cols=0
last_lines=0

handle_input() {
    while true; do
        display
        # 只需响应Enter键
        IFS= read -rsn1 key
        case "$key" in
            "") confirm_action ;;  # Enter键
            q) exit 0 ;;           # 保留退出快捷键
        esac
    done
}

# 启动主程序
handle_input