#!/bin/bash


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
    local item_info="${menu_items[i]}"
    
    # 使用更灵活的分隔方式处理可能的转义字符
    local item_color="${item_info%%:*}"
    local rest="${item_info#*:}"
    local item_text="${rest%%:*}"
    local item_func="${rest#*:}"

    if [[ $i -eq $current_selection ]]; then
        # 只给 > 符号添加高亮，选项保持原色
        printf "${color_highlight}>${color_normal} %d. ${item_color}%s${color_normal}\033[K" $((i+1)) "$item_text"
    else
        printf "   %d. ${item_color}%s${color_normal}\033[K" $((i+1)) "$item_text"
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
    selected_info="${menu_items[current_selection]}"
    
    # 提取函数名
    rest="${selected_info#*:*:}"  # 跳过前两部分（颜色和文本）
    selected_func="${rest%%:*}"         # 提取函数名部分
    
    if declare -f "$selected_func" > /dev/null; then
        $selected_func
        force_redraw=true
    else
        echo -e "${color_highlight}错误：未定义的功能函数 [$selected_func]"
        sleep 2
        force_redraw=true
    fi
done