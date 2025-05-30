#!/bin/bash

#====================== 配置区 ======================
yes_label="确认升级"  # 右侧确认选项文字
no_label="放弃操作"   # 左侧取消选项文字
default_selection=1   # 默认选中项 (0:No 1:Yes)

color_frame="\033[38;5;214m"  # 金色边框
color_title="\033[34m"        # 蓝色标题
color_highlight="\033[1;35m"  # 加粗紫色高亮
color_normal="\033[0m"        # 默认颜色

dialog_title="危险操作确认"
#dialog_prompt="您确定要执行此操作吗？"
hint_text="导航：←/→ 切换 | Enter确认"


confirm_action() {
    clear
    echo -e "${color_title}=== 操作已确认 ===${color_normal}"
    echo "正在执行敏感操作..."
    echo -e "\n操作成功完成！"
    read -n 1 -s -r -p "按任意键退出..."
    exit 0
}

cancel_action() {
    clear
    echo -e "${color_title}=== 操作已取消 ===${color_normal}"
    echo "正在安全退出系统..."
    exit 1
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

# 新增：按钮绘制优化函数
draw_buttons() {
    local cols=$1
    local btn_width=$((cols / 3))
    
    # 移动到按钮绘制起始行
    printf "\033[6;1H"  # 固定在第6行开始绘制
    
    # 清除旧按钮内容
    printf "\033[K"
    
    # 绘制取消按钮
    if [[ $current_selection -eq 0 ]]; then
        printf "${color_highlight}◄ %-*s${color_normal}" $((btn_width-3)) "$no_label"
    else
        printf "   %-*s" $((btn_width-3)) "$no_label"
    fi

    # 中间分隔区
    printf "%*s" $((cols - 2*btn_width )) " "

    # 绘制确认按钮
    if [[ $current_selection -eq 1 ]]; then
        printf "${color_highlight}%-*s ►${color_normal}" $((btn_width-3)) "$yes_label"
    else
        printf "%-*s   " $((btn_width-3)) "$yes_label"
    fi
    
    # 移动光标到底部提示区下方
    printf "\033[10;1H"
}

display() {
    local current_cols=$(tput cols)
    local current_lines=$(tput lines)

    if [[ $current_cols -ne $last_cols || $current_lines -ne $last_lines ]]; then
        clear
        last_cols=$current_cols
        last_lines=$current_lines
        
        # 框架绘制
        draw_line $current_cols
        center_text "$dialog_title" "$color_title" $current_cols
        draw_line $current_cols
        
        # 提示信息
        printf "\n\n"
        #center_text "$dialog_prompt" "$color_normal" $current_cols
        echo -e "\n"

        # 初始化按钮区域
        draw_buttons $current_cols
        
        # 底部提示
        printf "\n\n"
        draw_line $current_cols
        center_text "$hint_text" "$color_normal" $current_cols
    else
        # 仅刷新按钮区域
        draw_buttons $current_cols
    fi
}


#====================== 核心逻辑 ======================
current_selection=$default_selection
last_cols=0
last_lines=0

handle_input() {
    while true; do
        display
        IFS= read -rsn1 key
        case "$key" in
            $'\x1b')  # ESC序列
                read -rsn2 -t 0.1 key2
                case "$key2" in
                    '[D') ((current_selection=0)) ;;
                    '[C') ((current_selection=1)) ;;
                esac
                ;;
            "")  # Enter键
                if [[ $current_selection -eq 1 ]]; then
                    confirm_action
                else
                    cancel_action
                fi
                ;;
            q) cancel_action ;;
        esac
    done
}

# 启动主程序
handle_input