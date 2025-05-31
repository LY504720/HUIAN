#!/bin/bash

#====================== 函数区 ======================
draw_line() {
    printf "${color_frame}+"
    printf "%*s" $(($1 - 2)) | tr ' ' '-'
    printf "+${color_normal}\n"
}

center_text() {
    local text=$1
    local cols=$2
    local color=$3
    
    # 移除颜色代码计算实际文本长度
    local clean_text=$(echo -e "$text" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g")
    local text_length=${#clean_text}
    
    # 计算左边距
    local padding=$(( (cols - text_length) / 2 ))
    
    # 输出带颜色的居中文本
    printf "%*s${color}%s${color_normal}\n" $padding "" "$text"
}

draw_button() {
    local cols=$1
    local btn_width=$(( ${#confirm_label} + 6 ))
    
    # 绘制居中确认按钮
    printf "%*s" $(( (cols - btn_width) / 2 )) ""
    
    # 判断是否是最后一页
    if [ $current_page -eq $((total_pages - 1)) ]; then
        # 最后一页：高亮显示
        printf "${color_highlight}► ${confirm_label} ◄${color_normal}"
    else
        # 非最后一页：禁用状态
        printf "${color_content}☐ ${confirm_label} ${color_normal}"
    fi
}

display_page_content() {
    local cols=$1
    local start_index=$((current_page * items_per_page))
    local end_index=$((start_index + items_per_page - 1))
    
    # 显示当前页内容 - 左对齐
    for ((i = $start_index; i <= $end_index && i < ${#notice_content[@]}; i++)); do
        line="${notice_content[$i]}"
        # 左对齐显示，添加缩进
        printf "  ${color_content}%s${color_normal}\n" "$line"
    done
    
    # 如果当前页内容不足，填充空白行
    local current_lines=$((end_index - start_index + 1))
    if [ $current_lines -lt $items_per_page ]; then
        for ((i = $current_lines; i < $items_per_page; i++)); do
            printf "  ${color_content}%s${color_normal}\n" ""
        done
    fi
}

display_page_indicator() {
  local cols=$1
  local page_info="页面 $((current_page + 1))/$total_pages"

  # 计算页码文本长度（不含颜色代码）
  local page_info_length=${#page_info}

  # 计算左边距
  local padding=$(( (cols - page_info_length - 4) / 2 ))

  # 输出居中的页码指示器
  printf "%*s" $padding ""

  # 左箭头
  if [ $current_page -gt 0 ]; then
      printf "${color_highlight}← "
  else
      printf "${color_content}  "
  fi

  # 页码文本
  printf "${color_page}%s${color_normal}" "$page_info"

  # 右箭头
  if [ $current_page -lt $((total_pages - 1)) ]; then
      printf " ${color_highlight}→"
  else
      printf " ${color_content} "
  fi
}

display() {
    local current_cols=$(tput cols)
    local current_lines=$(tput lines)

    # 计算页脚区域行数
    local footer_area=5
    local content_height=$((current_lines - 6 - footer_area))
    
    # 动态调整每页显示数量
    items_per_page=$content_height
    if [ $items_per_page -lt 3 ]; then
        items_per_page=3
    fi
    total_pages=$(( (${#notice_content[@]} + items_per_page - 1) / items_per_page ))
    
    # 确保当前页在有效范围内
    if [ $current_page -ge $total_pages ]; then
        current_page=$((total_pages - 1))
    fi
    if [ $current_page -lt 0 ]; then
        current_page=0
    fi
    
    # 顶部框架
    draw_line $current_cols
    center_text "$notice_title" "$current_cols" "$color_title"
    draw_line $current_cols
    
    # 内容显示区域
    display_page_content $current_cols
    
    # 分隔线
    draw_line $current_cols
    
    # 页码指示器
    display_page_indicator $current_cols
    
    # 确认按钮区域
    draw_button $current_cols
    
    # 底部提示
    printf "\n"
    draw_line $current_cols
    
    # 修改后的提示文本显示 - 左对齐带缩进
    printf "  ${color_content}%s${color_normal}\n" "$hint_text"
    
    # 底部固定区域
    local footer_line=$((current_lines - 1))
    printf "\033[${footer_line};0H${color_frame}${footer_text}${color_normal}"
}

#====================== 核心逻辑 ======================
handle_input() {
    while true; do
        clear
        display
        
        # 等待用户输入
        read -rsn1 input
        case "$input" in
            $'\x1b') # 处理方向键
                read -rsn2 -t 0.1 rest
                case "$rest" in
                    '[C') # 右箭头
                        if [ $current_page -lt $((total_pages - 1)) ]; then
                            ((current_page++))
                        fi
                        ;;
                    '[D') # 左箭头
                        if [ $current_page -gt 0 ]; then
                            ((current_page--))
                        fi
                        ;;
                esac
                ;;
            "") # Enter键
                if [ $current_page -eq $((total_pages - 1)) ]; then
                    confirm_action
                fi
                ;;
            q) 
                exit 0 
                ;;
        esac
    done
}

# 启动主程序
handle_input