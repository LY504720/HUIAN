#!/bin/bash

# 颜色定义
GOLD='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
GRAY='\033[1;30m'
RESET='\033[0m'

# 全局变量
declare -a items
declare -a item_types  # 0=文件 1=目录 2=返回上级 3=不可选提示
declare -A selected_items # 选中的项目(绝对路径)
INITIAL_DIR=$(realpath -s "$PWD")
CURRENT_DIR="$INITIAL_DIR"
FULL_PATH="$CURRENT_DIR"
mode="normal"  # normal/select
selection=0
operation=""   # copy/cut/compress
clipboard=()
bookmarks_file="$HOME/.filemanager_bookmarks"
clipboard_type=""
need_redraw=1  # 控制重绘标志

# 加载书签
load_bookmarks() {
    [[ ! -f "$bookmarks_file" ]] && touch "$bookmarks_file"
}

# 自然排序函数
natural_sort() {
    LC_COLLATE=C sort -f
}

# 优化目录更新函数（使用自然排序）
update_items() {
    items=()
    item_types=()
    FULL_PATH="$CURRENT_DIR"
    
    # 添加返回上级选项
    [[ "$CURRENT_DIR" != "/" ]] && { items+=(".."); item_types+=(2); }

    # 收集目录（自然排序）
    mapfile -t dirs < <(find "$CURRENT_DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" 2>/dev/null | natural_sort)
    for dir in "${dirs[@]}"; do
        items+=("$dir")
        item_types+=(1)
    done

    # 收集文件（自然排序）
    mapfile -t files < <(find "$CURRENT_DIR" -mindepth 1 -maxdepth 1 -type f -printf "%f\n" 2>/dev/null | natural_sort)
    for file in "${files[@]}"; do
        items+=("$file")
        item_types+=(0)
    done

    # 处理空目录
    [[ ${#items[@]} -eq 0 ]] && { items+=("(空目录)"); item_types+=(3); }
    
    # 重置选择位置
    ((selection >= ${#items[@]})) && selection=$((${#items[@]} - 1))
    need_redraw=1
}

# 显示导航栏
show_navbar() {
    local mode_display=${mode:0:1}
    echo -en "${GOLD}模式: ${CYAN}${mode_display^^}${RESET} "
    
    if [[ "$mode" == "normal" ]]; then
        if [[ -z "$operation" ]]; then
            echo -en "${CYAN}|↑↓${RESET}"
            echo -en "${MAGENTA}|←选择${RESET}"
            echo -en "${GREEN}|→进入${RESET}"
            echo -en "${YELLOW}|~更多${RESET}"
            [[ ${#selected_items[@]} -gt 0 ]] && echo -en " ${RED}(${#selected_items[@]}选中)${RESET}"
        else
            echo -en "${CYAN}|↑↓${RESET}"
            echo -en "${MAGENTA}|←取消选择${RESET}"
            echo -en "${RED}|r删除${RESET}"
            [[ "$operation" == "compress" ]] && echo -en "${YELLOW}|c压缩${RESET}" || {
                echo -en "${GREEN}|c复制${RESET}"
                echo -en "${MAGENTA}|x剪切${RESET}"
                echo -en "${BLUE}|v粘贴${RESET}"
                echo -en "${YELLOW}|o打开方式${RESET}"
            }
        fi
    else
        echo -en "${CYAN}|↑↓${RESET}"
        echo -en "${MAGENTA}|←选择${RESET}"
        echo -en "${GREEN}|→进入${RESET}"
        echo -en "${YELLOW}|ENTER确定${RESET}"
    fi
}
# 初始绘制界面
initial_draw() {
    clear
    echo -e "${CYAN}==============================="
    echo -e "当前路径: $FULL_PATH"
    echo -e "===============================${RESET}"
    draw_file_list
    draw_navbar
}

# 绘制文件列表
draw_file_list() {
    for i in "${!items[@]}"; do
        # 处理不可选条目
        if [[ ${item_types[i]} -eq 3 ]]; then
            echo -e "  ${GRAY}(空目录)${RESET}"
            continue
        fi

        # 文件绝对路径
        item_path="${CURRENT_DIR}/${items[i]}"
        
        # 根据类型设置颜色
        case ${item_types[i]} in
            0) color=$BLUE; prefix="[文件] " ;;
            1) color=$GOLD; prefix="[目录] " ;;
            2) color=$CYAN; prefix="<返回> " ;;
        esac

        # 高亮当前选项
        [[ $i -eq $selection ]] && echo -en "> " || echo -en "  "
        
        # 如果已选中则加标记
        [[ -n "${selected_items["$item_path"]}" ]] && echo -en "${RED}*${RESET} " || echo -en "  "
        
        echo -e "${color}${prefix}${items[i]}${RESET}"
    done
}

# 绘制导航栏
draw_navbar() {
    echo -e "${CYAN}===============================${RESET}"
    echo -en "${GOLD}"
    show_navbar
    echo -e "${RESET}"
    echo -e "${CYAN}===============================${RESET}"
}

# 精简刷新机制
redraw() {
    [[ $need_redraw -eq 1 ]] && {
        initial_draw
        need_redraw=0
    }
}
# 处理更多菜单
more_menu() {
    clear
    echo -e "${CYAN}==============================="
    echo -e "      更多选项菜单"
    echo -e "===============================${RESET}"
    
    PS3="请选择操作: "
    options=(
        "新建文件夹" 
        "新建文件"
        "添加书签"
        "管理书签"
        "新建压缩包"
        "返回主界面"
    )
    
    while true; do
        select choice in "${options[@]}"; do
            case $REPLY in
                1) # 新建文件夹
                    read -p "输入文件夹名称: " dir_name
                    if [[ -n "$dir_name" ]]; then
                        mkdir -p "${CURRENT_DIR}/${dir_name}"
                        update_items
                        return
                    fi
                    ;;
                2) # 新建文件
                    read -p "输入文件名: " file_name
                    if [[ -n "$file_name" ]]; then
                        touch "${CURRENT_DIR}/${file_name}"
                        update_items
                        return
                    fi
                    ;;
                3) # 添加书签
                    load_bookmarks
                    grep -qFx "$CURRENT_DIR" "$bookmarks_file" || {
                        echo "$CURRENT_DIR" >> "$bookmarks_file"
                        echo -e "${GREEN}书签添加成功${RESET}"
                        sleep 1
                    }
                    return
                    ;;
                4) # 管理书签
                    [[ ! -s "$bookmarks_file" ]] && {
                        echo -e "${RED}没有书签${RESET}"
                        sleep 1
                        return
                    }
                    
                    clear
                    echo -e "${CYAN}===== 书签管理 ====="
                    local i=1
                    local bm_choices=()
                    while IFS= read -r line; do
                        echo "$i. $line"
                        bm_choices+=("$line")
                        ((i++))
                    done < "$bookmarks_file"
                    
                    read -p "选择书签编号(0返回): " bm_choice
                    
                    if [[ "$bm_choice" -gt 0 ]] && [[ "$bm_choice" -le ${#bm_choices[@]} ]]; then
                        CURRENT_DIR="${bm_choices[$((bm_choice-1))]}"
                        update_items
                    fi
                    return
                    ;;
                5) # 新建压缩包
                    operation="compress"
                    return
                    ;;
                6) # 返回主界面
                    return
                    ;;
                *) echo -e "${RED}无效选择${RESET}" ;;
            esac
        done
    done
}

# 打开方式菜单
open_with_menu() {
    local file_path="${CURRENT_DIR}/${items[selection]}"
    [[ ! -f "$file_path" ]] && {
        echo -e "${RED}只有文件能选择打开方式${RESET}"
        sleep 1
        return
    }
    
    clear
    echo -e "${CYAN}==============================="
    echo -e "打开方式: $(basename "$file_path")"
    echo -e "===============================${RESET}"
    
    PS3="选择打开方式: "
    options=(
        "以文本编辑器打开"
        "添加执行权限并运行"
        "以压缩包打开（解压）"
        "返回主界面"
    )
    
    select choice in "${options[@]}"; do
        case $REPLY in
            1) # 以文本编辑器打开
                command -v nano &>/dev/null && nano "$file_path" || vi "$file_path"
                return
                ;;
            2) # 添加执行权限并运行
                chmod u+x "$file_path"
                clear
                echo -e "${GREEN}执行文件: $file_path${RESET}"
                bash "$file_path"
                echo -e "\n${GREEN}执行完成，按任意键继续...${RESET}"
                read -n1
                return
                ;;
                3) # 以压缩包打开（解压）
                if [[ "$file_path" == *.zip || "$file_path" == *.tar* ]]; then
                    TEMP_DIR=$(mktemp -d)
                    if tar -xf "$file_path" -C "$TEMP_DIR" 2>/dev/null || unzip -q "$file_path" -d "$TEMP_DIR" 2>/dev/null; then
                        CURRENT_DIR="$TEMP_DIR"
                        update_items
                    else
                        echo -e "${RED}解压失败${RESET}"
                        sleep 1
                    fi
                else
                    echo -e "${RED}非压缩格式文件${RESET}"
                    sleep 1
                fi
                return
                ;;
            4) return ;; # 返回主界面
            *) echo -e "${RED}无效选择${RESET}" ;;
        esac
    done
}

# 创建压缩包
create_compress() {
    [[ ${#selected_items[@]} -eq 0 ]] && {
        echo -e "${RED}未选择文件/目录${RESET}"
        sleep 1
        return
    }
    
    clear
    echo -e "${CYAN}==============================="
    echo -e "      新建压缩包"
    echo -e "===============================${RESET}"
    
    read -p "输入压缩包名称(不含扩展名): " zip_name
    [[ -z "$zip_name" ]] && {
        echo -e "${RED}操作取消${RESET}"
        sleep 1
        return
    }
    
    echo -e "\n${YELLOW}选择压缩格式:${RESET}"
    echo "1. zip"
    echo "2. tar.gz"
    echo "3. tar.bz2"
    read -p "选择 (1-3): " zip_type
    
    zip_file="$CURRENT_DIR/$zip_name"
    items_to_compress=()
    
    for path in "${!selected_items[@]}"; do
        items_to_compress+=("$path")
    done
    
    case $zip_type in
        1) 
            zip_file="$zip_file.zip"
            zip -r -q "$zip_file" "${items_to_compress[@]}"
            ;;
        2) 
            zip_file="$zip_file.tar.gz"
            tar -czf "$zip_file" "${items_to_compress[@]}"
            ;;
        3) 
            zip_file="$zip_file.tar.bz2"
            tar -cjf "$zip_file" "${items_to_compress[@]}"
            ;;
        *)
            echo -e "${RED}无效选择${RESET}"
            sleep 1
            return
            ;;
    esac
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}压缩包创建成功${RESET}"
        selected_items["$zip_file"]=1
        operation=""
        sleep 1
        update_items
    else
        echo -e "${RED}压缩包创建失败${RESET}"
        sleep 2
    fi
}

# 执行文件函数
run_file() {
    file_path="${CURRENT_DIR}/${items[selection]}"
    
    if [[ "$mode" == "select" ]]; then
        # 在选择模式下输出绝对路径
        [[ ${item_types[selection]} -lt 2 ]] && {
            echo "$(realpath -s "$file_path")"
            exit 0
        }
        return
    fi

    # 正常模式执行逻辑
    [[ ${item_types[selection]} -eq 0 ]] && {
        if [[ -x "$file_path" ]] || head -n1 "$file_path" | grep -q "bin/bash"; then
            clear
            echo -e "${GREEN}执行: $file_path${RESET}"
            bash "$file_path"
            echo -e "\n${GREEN}执行完成，按任意键继续...${RESET}"
            read -n1
            update_items
        else
            echo -e "\n${RED}无法执行非可执行文件${RESET}"
            sleep 1
        fi
    }
}
# 主循环
main() {
    stty -echo -icanon min 1 time 0
    load_bookmarks
    update_items
    
    while true; do
        redraw
        
        # 非阻塞按键读取
        IFS= read -rsn1 -t 0.05 key || true
        [[ -z "$key" ]] && continue
        
        # ESC键序列处理
        [[ "$key" == $'\x1b' ]] && {
            read -rsn2 -t 0.01 -s keys || true
            key="$key$keys"
        }

        case "$key" in
            # 上箭头
            $'\x1b[A')
                [[ $selection -gt 0 ]] && {
                    ((selection--))
                    need_redraw=1
                }
                ;;
                
            # 下箭头
            $'\x1b[B')
                [[ $selection -lt $((${#items[@]} - 1)) ]] && {
                    ((selection++))
                    need_redraw=1
                }
                ;;
                
            # 右箭头（进入）
            $'\x1b[C')
                case ${item_types[selection]} in
                    1) # 目录
                        NEW_DIR="$CURRENT_DIR/${items[selection]}"
                        CURRENT_DIR="$NEW_DIR"
                        selection=0
                        update_items
                        ;;
                    0) # 文件
                        run_file
                        ;;
                    2) # 返回上级
                        CURRENT_DIR=$(dirname "$CURRENT_DIR")
                        selection=0
                        update_items
                        ;;
                esac
                ;;
                
            # 左箭头（选择/取消选择）
            $'\x1b[D')
                [[ ${item_types[selection]} -lt 2 ]] && {
                    item_path="$CURRENT_DIR/${items[selection]}"
                    if [[ -n "${selected_items["$item_path"]}" ]]; then
                        unset selected_items["$item_path"]
                        # 取消操作如果没有选中项
                        [[ ${#selected_items[@]} -eq 0 ]] && operation=""
                    else
                        selected_items["$item_path"]=1
                        [[ -z "$operation" ]] && operation="selected"
                    fi
                    need_redraw=1
                }
                ;;
                
            "q"|"Q") # 退出
                clear
                stty sane
                exit 0
                ;;
                
            "~") # 更多菜单
                [[ "$mode" == "normal" ]] && {
                    more_menu
                    need_redraw=1
                }
                ;;
                "r"|"R") # 删除
                [[ "$mode" == "normal" && -n "$operation" && ${#selected_items[@]} -gt 0 ]] && {
                    for path in "${!selected_items[@]}"; do
                        rm -rf "$path"
                    done
                    operation=""
                    selected_items=()
                    update_items
                }
                ;;
                
            "c"|"C") # 复制或压缩
                [[ "$mode" == "normal" && -n "$operation" ]] && {
                    if [[ "$operation" == "compress" ]]; then
                        create_compress
                    else
                        clipboard=()
                        for path in "${!selected_items[@]}"; do
                            clipboard+=("$path")
                        done
                        clipboard_type="copy"
                        operation=""
                        need_redraw=1
                    fi
                }
                ;;
                
            "x"|"X") # 剪切
                [[ "$mode" == "normal" && -n "$operation" ]] && {
                    clipboard=()
                    for path in "${!selected_items[@]}"; do
                        clipboard+=("$path")
                    done
                    clipboard_type="cut"
                    operation=""
                    need_redraw=1
                }
                ;;
                
            "v"|"V") # 粘贴
                [[ "$mode" == "normal" && ${#clipboard[@]} -gt 0 ]] && {
                    for source_path in "${clipboard[@]}"; do
                        filename=$(basename "$source_path")
                        cp -r "$source_path" "$CURRENT_DIR/$filename" 2>/dev/null || 
                        mv "$source_path" "$CURRENT_DIR/$filename" 2>/dev/null
                    done
                    clipboard=()
                    clipboard_type=""
                    update_items
                }
                ;;
                
            "o"|"O") # 打开方式
                [[ "$mode" == "normal" && ${#selected_items[@]} -gt 0 ]] && {
                    open_with_menu
                    need_redraw=1
                }
                ;;
                
            "s"|"S") # 切换模式
                [[ "$mode" == "normal" ]] && mode="select" || mode="normal"
                selected_items=()
                operation=""
                need_redraw=1
                ;;
                
            " ") # 空格键（选中当前项）
                [[ ${item_types[selection]} -lt 2 ]] && {
                    item_path="$CURRENT_DIR/${items[selection]}"
                    if [[ -n "${selected_items["$item_path"]}" ]]; then
                        unset selected_items["$item_path"]
                    else
                        selected_items["$item_path"]=1
                        [[ -z "$operation" ]] && operation="selected"
                    fi
                    need_redraw=1
                }
                ;;
                
            $'\n') # 回车键
                # 选择模式处理
                [[ "$mode" == "select" && ${item_types[selection]} -lt 2 ]] && {
                    echo "$(realpath -s "$CURRENT_DIR/${items[selection]}")"
                    stty sane
                    exit 0
                }
                
                # 正常模式处理
                case ${item_types[selection]} in
                    1) # 目录
                        NEW_DIR="$CURRENT_DIR/${items[selection]}"
                        CURRENT_DIR="$NEW_DIR"
                        selection=0
                        update_items
                        ;;
                    0) # 文件
                        run_file
                        ;;
                    2) # 返回上级
                        CURRENT_DIR=$(dirname "$CURRENT_DIR")
                        selection=0
                        update_items
                        ;;
                esac
                ;;
        esac
    done
}

# 启动主函数
trap "stty sane" EXIT
main
