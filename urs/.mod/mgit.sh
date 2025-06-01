#!/bin/bash

# 要检测的目标字符串
TARGET_ALIAS="alias mgit='bash /home/HUIAN/urs/mgit.sh'"

# 查找 ~/.bashrc 文件
BASHRC_PATH="$HOME/.bashrc"

# 检查文件是否存在
if [ ! -f "$BASHRC_PATH" ]; then
    echo "警告: 未找到 ~/.bashrc 文件"
    exit 1
fi

# 检测别名是否存在
if grep -qF "$TARGET_ALIAS" "$BASHRC_PATH"; then
    echo -e "\e[32m检测成功: \e[0m别名已设置"
    
else
    echo -e "\e[31m检测失败: \e[0m未找到匹配的别名设置"
    
    # 询问用户是否自动添加
    read -p "是否要自动添加别名到 ~/.bashrc? [y/N] " choice
    case "$choice" in
        y|Y)
            # 确保文件以换行符结尾
            if [ -n "$(tail -c 1 "$BASHRC_PATH")" ]; then
                echo "" >> "$BASHRC_PATH"
            fi
            
            # 添加别名
            echo "$TARGET_ALIAS" >> "$BASHRC_PATH"
            
            # 检查是否添加成功
            if grep -qF "$TARGET_ALIAS" "$BASHRC_PATH"; then
                echo -e "\e[32m别名添加成功!\e[0m"
                
                # 询问是否立即生效
                read -p "是否要使别名立即生效? [Y/n] " apply_choice
                case "$apply_choice" in
                    n|N)
                        echo -e "请稍后手动执行: \e[35msource ~/.bashrc\e[0m"
                        ;;
                    *)
                        echo -e "执行: \e[35msource ~/.bashrc\e[0m"
                        source "$BASHRC_PATH"
                        echo -e "\e[32m别名已生效! 您现在可以使用 'mgit' 命令\e[0m"
                        ;;
                esac
            else
                echo -e "\e[31m错误: 添加别名失败，请手动添加\e[0m"
            fi
            ;;
        *)
            # 显示手动修改说明
            echo -e "\n请手动修改 \e[1m~/.bashrc\e[0m 文件:"
            echo -e "1. 使用以下命令打开文件:"
            echo -e "   \e[35mnano ~/.bashrc\e[0m 或 \e[35mvi ~/.bashrc\e[0m"
            echo -e "2. 在文件末尾添加以下内容:"
            echo -e "\e[33m$TARGET_ALIAS\e[0m"
            echo -e "3. 保存文件并退出编辑器"
            echo -e "4. 应用更改:"
            echo -e "   \e[35msource ~/.bashrc\e[0m"
            exit 1
            ;;
    esac
fi