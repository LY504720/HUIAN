#!/bin/bash
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"

#====================== 颜色定义 ======================
color_frame="\033[38;5;214m"  # 金色边框
color_title="\033[34m"        # 蓝色标题
color_highlight="\033[35m"    # 紫色高亮
color_normal="\033[0m"        # 默认颜色
color_prompt="\033[36m"       # 青色提示
color_help="\033[33m"         # 黄色帮助文本
color_lv="\033[0;32m"         # 绿色
color_qing="\033[0;36m"       # 青色
color_fen="\033[38;5;211m"    # 粉色
color_hong="\033[0;31m"       # 红色
color_huang="\033[38;5;220m"  # 金色

#====================== 配置区 ======================
text_banner="ComfyUI 模型管理器"
text_greeting="请选择要执行的操作"
text_prompt="导航：↑/↓ 选择 | ← 退出 | → 确认 | ? 帮助"
menu_title="模型管理"

# 模型目录配置
MODEL_DIR="../../../data/ComfyUI/models"
INSTALL_PACKAGE_DIR="./model_packages"  # 模型安装包目录

# 创建目录
mkdir -p "$INSTALL_PACKAGE_DIR"

#====================== 函数定义 ======================
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
    
    local item_color="${item_info%%:*}"
    local rest="${item_info#*:}"
    local item_text="${rest%%:*}"
    local item_func="${rest#*:}"

    if [[ $i -eq $current_selection ]]; then
        printf "${color_highlight}>${color_normal} %d. ${item_color}%s${color_normal}\033[K" $((i+1)) "$item_text"
    else
        printf "   %d. ${item_color}%s${color_normal}\033[K" $((i+1)) "$item_text"
    fi
}

display() {
    local current_cols=$(tput cols)
    local current_lines=$(tput lines)
    local line_count=0

    if [[ $force_redraw == true || $current_cols -ne $last_cols || $current_lines -ne $last_lines || $last_selection -eq -2 ]]; then
        clear
        last_cols=$current_cols
        last_lines=$current_lines
        force_redraw=false
        
        draw_line "=" "$current_cols"
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

        for i in "${!menu_items[@]}"; do
            move_cursor $((menu_start_line + i)) 1
            draw_menu_item "$i"
        done

        ((line_count += ${#menu_items[@]}))
        echo
        draw_line "=" "$current_cols"
        center_text "$text_prompt" "$color_prompt" "$current_cols"
        last_selection=$current_selection
    else
        if [[ $last_selection -ne $current_selection ]]; then
            if [[ $last_selection -ge 0 ]]; then
                move_cursor $((menu_start_line + last_selection)) 1
                draw_menu_item "$last_selection"
            fi
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
            $'\x1b')
                read -rsn2 -t 0.1 key2
                case "$key2" in
                    '[A') ((current_selection > 0)) && ((current_selection--)) ;;
                    '[B') ((current_selection < ${#menu_items[@]}-1)) && ((current_selection++)) ;;
                    '[D') exit_func ;;
                    '[C') break ;;
                esac ;;
            "") break ;;
            $'?') help_func ; force_redraw=true ;;
            $'\xef\xbc\x9f') help_func ; force_redraw=true ;;
            $'~') help_open ; force_redraw=true ;;
        esac
    done
}

#====================== 模型树查看功能 ======================
show_model_tree() {
    clear
    echo -e "${color_title}=== 模型目录结构 ===${color_normal}"
    echo -e "${color_highlight}模型根目录: $MODEL_DIR${color_normal}\n"
    
    # 使用tree命令显示目录结构（如果可用）
    if command -v tree &> /dev/null; then
        tree -L 3 "$MODEL_DIR" | sed -E "s/([^ ]+)\/$/${color_qing}\1${color_normal}/g" | \
        sed -E "s/(\.ckpt|\.safetensors|\.pt|\.pth)$/${color_lv}\1${color_normal}/g" | \
        sed -E "s/(\.yaml|\.yml)$/${color_huang}\1${color_normal}/g"
    else
        # 如果没有tree命令，使用find模拟并优化显示
        find "$MODEL_DIR" -maxdepth 3 -print | while IFS= read -r path; do
            # 计算相对路径
            rel_path="${path#$MODEL_DIR/}"
            
            # 计算缩进级别
            depth=$(grep -o '/' <<< "$rel_path" | wc -l)
            
            # 创建缩进字符串
            indent=""
            for ((i=1; i<depth; i++)); do
                indent+="│   "
            done
            
            # 如果是最后一级，添加分支符号
            if [[ $depth -gt 0 ]]; then
                indent+="├── "
            fi
            
            # 获取文件名或目录名
            name=$(basename "$path")
            
            # 根据类型设置颜色
            if [[ -d "$path" ]]; then
                # 计算目录中的项目数
                item_count=$(find "$path" -maxdepth 1 -mindepth 1 | wc -l)
                echo -e "${indent}${color_qing}$name${color_normal} (${color_huang}$item_count项${color_normal})"
            else
                # 根据文件扩展名设置颜色
                case "$name" in
                    *.ckpt|*.safetensors|*.pt|*.pth)
                        echo -e "${indent}${color_lv}$name${color_normal}" ;;
                    *.yaml|*.yml)
                        echo -e "${indent}${color_huang}$name${color_normal}" ;;
                    *)
                        echo -e "${indent}${color_normal}$name${color_normal}" ;;
                esac
            fi
        done
    fi
    
    echo -e "\n${color_prompt}按任意键返回...${color_normal}"
    read -n 1 -s -r
}
#====================== 模型安装功能 ======================
install_model_package() {
    clear
    echo -e "${color_title}=== 安装模型包 ===${color_normal}"
    
    # 检查安装包目录是否存在
    if [ ! -d "$INSTALL_PACKAGE_DIR" ]; then
        echo -e "${color_hong}错误: 安装包目录不存在 - $INSTALL_PACKAGE_DIR${color_normal}"
        echo -e "${color_prompt}按任意键返回...${color_normal}"
        read -n 1 -s -r
        return
    fi
    
    # 获取所有安装包
    local packages=($(find "$INSTALL_PACKAGE_DIR" -maxdepth 1 -type f -name "*.sh" | sort))
    
    if [ ${#packages[@]} -eq 0 ]; then
        echo -e "${color_hui}没有找到可用的模型安装包${color_normal}"
        echo -e "${color_prompt}按任意键返回...${color_normal}"
        read -n 1 -s -r
        return
    fi
    
    # 显示安装包列表
    echo -e "${color_highlight}可用的模型安装包:${color_normal}"
    for i in "${!packages[@]}"; do
        echo -e "  ${color_lv}$((i+1)). ${color_normal}$(basename "${packages[i]}")"
    done
    
    # 用户选择
    read -p "请选择要安装的模型包 (1-${#packages[@]}, 0取消): " choice
    
    # 处理取消
    if [[ $choice -eq 0 ]]; then
        return
    fi
    
    # 验证输入
    if [[ ! $choice =~ ^[1-9][0-9]*$ ]] || ((choice > ${#packages[@]})); then
        echo -e "${color_hong}无效选择${color_normal}"
        sleep 1
        return
    fi
    
    # 获取选择的安装包
    local package_path="${packages[$((choice-1))]}"
    local package_name=$(basename "$package_path")
    
    # 确认安装
    echo -e "\n${color_qing}确定要安装: $package_name 吗? (y/n)${color_normal}"
    read confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${color_huang}安装已取消${color_normal}"
        sleep 1
        return
    fi
    
    # 执行安装
    echo -e "${color_qing}正在安装: $package_name${color_normal}"
    MODEL_DIR="$MODEL_DIR" bash "$package_path"
    
    # 检查结果
    if [ $? -eq 0 ]; then
        echo -e "\n${color_lv}模型包安装成功!${color_normal}"
    else
        echo -e "\n${color_hong}模型包安装失败!${color_normal}"
    fi
    
    echo -e "\n${color_prompt}按任意键继续...${color_normal}"
    read -n 1 -s -r
}
#====================== 模型删除功能 ======================
delete_model() {
    clear
    echo -e "${color_title}=== 删除模型 ===${color_normal}"
    
    # 查找所有模型文件（符合ComfyUI标准结构）
    local models=()
    while IFS= read -r -d $'\0' file; do
        models+=("$file")
    done < <(find "$MODEL_DIR" -type f \( \
        -path "*/checkpoints/*" -o \
        -path "*/loras/*" -o \
        -path "*/vae/*" -o \
        -path "*/controlnet/*" -o \
        -path "*/upscale_models/*" -o \
        -path "*/embeddings/*" \
        \) \( \
        -name "*.ckpt" -o \
        -name "*.safetensors" -o \
        -name "*.pt" -o \
        -name "*.pth" -o \
        -name "*.bin" \
        \) -print0)
    
    if [ ${#models[@]} -eq 0 ]; then
        echo -e "${color_hui}没有找到任何模型文件${color_normal}"
        echo -e "${color_prompt}按任意键返回...${color_normal}"
        read -n 1 -s -r
        return
    fi
    
    # 显示模型列表
    echo -e "${color_highlight}可删除的模型:${color_normal}"
    for i in "${!models[@]}"; do
        # 提取相对路径（相对于MODEL_DIR）
        local rel_path="${models[i]#$MODEL_DIR/}"
        echo -e "  ${color_lv}$((i+1)). ${color_normal}$rel_path"
    done
    
    # 用户选择
    read -p "请选择要删除的模型 (1-${#models[@]}, 0取消): " choice
    
    # 处理取消
    if [[ $choice -eq 0 ]]; then
        return
    fi
    
    # 验证输入
    if [[ ! $choice =~ ^[1-9][0-9]*$ ]] || ((choice > ${#models[@]})); then
        echo -e "${color_hong}无效选择${color_normal}"
        sleep 1
        return
    fi
    
    # 获取选择的模型
    local model_path="${models[$((choice-1))]}"
    local model_name=$(basename "$model_path")
    
    # 确认删除
    echo -e "\n${color_qing}确定要删除: $model_name 吗? (y/n)${color_normal}"
    read confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${color_huang}删除已取消${color_normal}"
        sleep 1
        return
    fi
    
    # 执行删除
    rm -f "$model_path"
    
    # 检查结果
    if [ $? -eq 0 ]; then
        echo -e "\n${color_lv}模型删除成功!${color_normal}"
    else
        echo -e "\n${color_hong}模型删除失败!${color_normal}"
    fi
    
    echo -e "\n${color_prompt}按任意键继续...${color_normal}"
    read -n 1 -s -r
}

#====================== 其他功能 ======================
exit_func() {
    clear
    echo -e "${color_title}感谢使用 ComfyUI 模型管理器${color_normal}"
    echo -e "${color_highlight}再见!${color_normal}"
    echo -e "\e[0m"
    exit 0
}

help_func() {
    clear
    echo -e "${color_title}=== 帮助信息 ===${color_normal}"
    echo -e "${color_help}ComfyUI 模型管理器使用指南:"
    echo -e "  1. 使用方向键导航菜单"
    echo -e "  2. 按回车键确认选择"
    echo -e "  3. 按左方向键退出系统"
    echo -e "  4. 按?键显示帮助信息"
    echo -e "\n功能说明:"
    echo -e "  ${color_lv}查看模型树${color_normal} - 以树状结构显示所有模型"
    echo -e "  ${color_qing}安装模型包${color_normal} - 运行模型安装脚本"
    echo -e "  ${color_fen}删除模型${color_normal} - 从系统中移除模型"
    echo -e "\n${color_prompt}按任意键返回主菜单...${color_normal}"
    read -n 1 -s -r
}

help_open() {
    clear
    echo -e "${color_title}=== 高级帮助 ===${color_normal}"
    echo -e "${color_highlight}模型安装包说明:${color_normal}"
    echo -e "  1. 模型安装包应放置在: $INSTALL_PACKAGE_DIR"
    echo -e "  2. 安装包应为.sh脚本文件"
    echo -e "  3. 安装包应包含以下变量定义:"
    echo -e "     - MODEL_NAME: 模型名称"
    echo -e "     - MODEL_URL: 模型下载URL"
   
    echo -e "     - MODEL_PATH: 安装路径 (相对于 $MODEL_DIR)"
    echo -e "\n${color_highlight}示例安装包内容:${color_normal}"
    echo -e "  #!/bin/bash"
    echo -e "  MODEL_NAME=\"Stable Diffusion v1.5\""
    echo -e "  MODEL_URL=\"https://example.com/models/sd-v1.5.ckpt\""
    echo -e "  MODEL_PATH=\"stable-diffusion/v1.5\""
    echo -e "  # 下载并安装模型"
    echo -e "  mkdir -p \"$MODEL_DIR/\$MODEL_PATH\""
    echo -e "  wget -O \"$MODEL_DIR/\$MODEL_PATH/\$MODEL_NAME.ckpt\" \"\$MODEL_URL\""
    echo -e "\n${color_prompt}按任意键继续...${color_normal}"
    read -n 1 -s -r
}

#====================== 主菜单配置 ======================
menu_items=(
    "${color_lv}:查看模型树:show_model_tree"
    "${color_qing}:安装模型包:install_model_package"
    "${color_fen}:删除模型:delete_model"
    "${color_hong}:退出管理器:exit_func"
)

#====================== 初始化变量 ======================
current_selection=0
last_cols=0
last_lines=0
menu_start_line=8
last_selection=-1
force_redraw=false

#====================== 主程序循环 ======================
while true; do
    handle_input
    selected_info="${menu_items[current_selection]}"
    
    # 提取函数名
    rest="${selected_info#*:*:}"  # 跳过前两部分（颜色和文本）
    selected_func="${rest%%:*}"   # 提取函数名部分
    
    if declare -f "$selected_func" > /dev/null; then
        $selected_func
        force_redraw=true
    else
        echo -e "${color_highlight}错误：未定义的功能函数 [$selected_func]"
        sleep 2
        force_redraw=true
    fi
done