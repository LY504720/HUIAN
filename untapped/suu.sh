#!/bin/bash


#====================== 配置区 ======================
text_banner="欢迎使用绘安菜单"
text_greeting="请选择要执行的操作"
text_prompt="导航：↑/↓ 选择 | ← 退出 | → 确认 | ? 帮助"
menu_title="主菜单选项"

#====================== 函数区 ======================
option1_func() {
    clear
    echo -e "${color_title}=== 选项一已选择 ===${color_normal}"
    echo "正在执行示例操作..."
    echo "当前时间：$(date '+%T')"
    read -n 1 -s -r -p "按任意键返回主菜单..."
}

option2_func() {
    clear
    echo -e "${color_title}=== 选项二已选择 ===${color_normal}"
    echo "正在执行示例操作..."
    echo "系统负载：$(uptime)"
    read -n 1 -s -r -p "按任意键返回主菜单..."
}

option3_func() {
    clear
    echo -e "${color_title}=== 选项三已选择 ===${color_normal}"
    echo "正在执行示例操作..."
    echo "当前用户：$(whoami)"
    read -n 1 -s -r -p "按任意键返回主菜单..."
}

option4_func() {
    clear
    echo -e "${color_title}=== 选项四已选择 ===${color_normal}"
    echo "正在执行示例操作..."
    echo "主机名称：$(hostname)"
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
#====================== 核心逻辑 ======================
menu_items=(
    "选项一:option1_func"
    "选项二:option2_func"
    "选项三:option3_func"
    "选项四:option4_func"
    "退出系统:exit_func"
)

color_frame="\033[38;5;214m"  # 金色边框
color_title="\033[34m"        # 蓝色标题
color_highlight="\033[35m"    # 紫色高亮
color_normal="\033[0m"        # 默认颜色
color_prompt="\033[36m"       # 青色提示
color_help="\033[33m"         # 黄色帮助文本


current_selection=0
last_cols=0
last_lines=0
menu_start_line=8
last_selection=-1
force_redraw=false  # 新增：强制重绘标志

draw_line() {
    local line_char=$1
    local cols=$2
    printf "${color_frame}"
    printf "+%*s+" $((cols - 2)) | tr ' ' "$line_char"
    printf "${color_normal}\n"
}

center_text() {
    local text=$1
    local color=$2
    local cols=$3
    local offset=${4:-0}
    local width=$((cols - 4 - offset))
    printf "${color}%*s${color_normal}\n" $(( (${#text} + width) / 2 + offset )) "$text"
}

move_cursor() {
    printf "\033[%d;%dH" "$1" "$2"
}

draw_menu_item() {
    local i=$1
    local item="${menu_items[i]%%:*}"
    if [[ $i -eq $current_selection ]]; then
        printf "${color_highlight}>${color_normal} %d. ${color_highlight}%s${color_normal}\033[K" $((i+1)) "$item"
    else
        printf "   %d. %s\033[K" $((i+1)) "$item"
    fi
}

display() {
    local current_cols=$(tput cols)
    local current_lines=$(tput lines)
    local line_count=0

    # 强制重绘条件：终端尺寸变化、首次显示或设置了强制重绘标志
    if [[ $force_redraw == true || $current_cols -ne $last_cols || $current_lines -ne $last_lines || $last_selection -eq -2 ]]; then
        clear
        last_cols=$current_cols
        last_lines=$current_lines
        force_redraw=false  # 重置标志
        
        # 动态布局计算
        draw_line "=" "$current_cols"                   # 第1行
        ((line_count++))
        center_text "$text_banner" "$color_title" "$current_cols"
        ((line_count++))
        draw_line "-" "$current_cols"
        ((line_count++))
        center_text "$text_greeting" "$color_prompt" "$current_cols"
        ((line_count+=2))
        
        draw_line "-" "$current_cols"
        ((line_count++))
        center_text "$menu_title" "$color_title" "$current_cols" 2
        ((line_count++))
        draw_line "-" "$current_cols"
        ((line_count++))
        
        menu_start_line=$line_count

        # 全量绘制菜单项
        for i in "${!menu_items[@]}"; do
            move_cursor $((menu_start_line + i)) 1
            draw_menu_item "$i"
        done

        # 底部元素
        ((line_count += ${#menu_items[@]}))
        echo
        draw_line "=" "$current_cols"
        center_text "$text_prompt" "$color_prompt" "$current_cols"
        last_selection=$current_selection  # 同步状态
    else
        # 局部刷新逻辑
        if [[ $last_selection -ne $current_selection ]]; then
            # 清除旧选项高亮
            if [[ $last_selection -ge 0 ]]; then
                move_cursor $((menu_start_line + last_selection)) 1
                draw_menu_item "$last_selection"
            fi
            # 绘制新选项高亮
            move_cursor $((menu_start_line + current_selection)) 1
            draw_menu_item "$current_selection"
            last_selection=$current_selection
        fi
    fi
    move_cursor $((menu_start_line + ${#menu_items[@]} + 2)) 1
}

handle_input() {
    while true; do
        display
        IFS= read -rsn1 key
        case "$key" in
            $'\x1b')  # ESC序列
                read -rsn2 -t 0.1 key2
                case "$key2" in
                    '[A') ((current_selection > 0)) && ((current_selection--)) ;;
                    '[B') ((current_selection < ${#menu_items[@]}-1)) && ((current_selection++)) ;;
                    '[D') exit_func ;;
                    '[C') break ;;
                esac ;;
            "") break ;;  # 回车键
            $'?') help_func ; force_redraw=true ;;  # 英文问号
            $'\xef\xbc\x9f') help_func ; force_redraw=true ;;  # 中文问号（UTF-8编码）
            $'~') help_open ; force_redraw=true ;;  #~特殊函数
        esac
    done
}

# 主程序循环
while true; do
    handle_input
    selected_func="${menu_items[current_selection]#*:}"
    if declare -f "$selected_func" > /dev/null; then
        $selected_func
        # 函数执行完毕后，设置强制重绘标志
        force_redraw=true
    else
        echo -e "${color_highlight}错误：未定义的功能函数 [$selected_func]"
        sleep 2
        force_redraw=true  # 错误显示后也强制重绘
    fi
done