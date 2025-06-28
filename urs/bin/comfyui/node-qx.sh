#!/bin/bash

# ---------------------------
# 兼容性配置
# ---------------------------
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"

# ---------------------------
# 功能配置
# ---------------------------
COMFYUI_DIR="${COMFYUI_DIR:-/home/HUIAN/data/ComfyUI}"
CONFIG_FILE="${COMFYUI_DIR}/user/default/ComfyUI-Manager/config.ini"

# ---------------------------
# 核心功能函数
# ---------------------------
validate_config() {
    [ -f "$CONFIG_FILE" ] || { echo "错误：配置文件不存在"; return 1; }
    grep -q "security_level" "$CONFIG_FILE" || { echo "错误：配置文件缺少安全级别定义"; return 2; }
}

get_level() {
    validate_config || return 1
    # 增强的兼容性解析（支持任意空白符和行尾换行符）
    awk '
        $1 == "security_level" {
            sub(/^[^=]*=[[:space:]]*/, "");  # 移除键和等号前的空白
            gsub(/[[:space:]]*$/, "");      # 移除值后的空白
            print
            exit
        }
    ' "$CONFIG_FILE"
}

set_level() {
    local level=$1
    validate_config || return 1
    
    # 备份配置
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
    
    # 尝试更新现有配置
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! sed -i '' "/^security_level = / s/= .*/= $level/" "$CONFIG_FILE"; then
            # 如果未找到匹配行，则追加到文件末尾
            echo "security_level = $level" >> "$CONFIG_FILE"
        fi
    else
        if ! sed -i "/^security_level = / s/= .*/= $level/" "$CONFIG_FILE"; then
            # 如果未找到匹配行，则追加到文件末尾
            echo "security_level = $level" >> "$CONFIG_FILE"
        fi
    fi
    
    # 验证结果
    [ "$(get_level)" = "$level" ]
}
show_info() {
    cat << EOF
安全级别说明：
───────────────────────
 Strict (最严格): 禁止所有外部插件安装
 Normal (默认):   允许官方仓库插件
 Weak (最低):     允许任意来源插件
───────────────────────
EOF
}

security_menu() {
    local choice
    while true; do
        clear
        echo "───────────────────────"
        echo " 安全级别设置 ($CONFIG_FILE)"
        echo "───────────────────────"
        echo "当前级别: $(get_level)"
        echo "───────────────────────"
        echo "1) 最严格 (Strict)"
        echo "2) 默认 (Normal)"
        echo "3) 最低 (Weak)"
        echo "0) 返回上级菜单"
        echo "───────────────────────"
        
        read -p "选择操作 [0-3]: " choice
        case $choice in
            1) level="strict";;
            2) level="normal";;
            3) level="weak";;
            0) return;;
            *) echo "无效选择，请重新输入"; sleep 1;;
        esac
        
        if set_level "$level"; then
            echo "安全级别已更新为: $level"
            sleep 2
        else
            echo "设置失败，请检查配置文件权限"
            sleep 2
        fi
    done
}

# ---------------------------
# 独立运行模式
# ---------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case $1 in
        --install-manager)
            echo "安装功能尚未集成到独立脚本"
            ;;
        --update-manager)
            echo "更新功能尚未集成到独立脚本"
            ;;
        --set-level)
            shift
            set_level "$1"
            ;;
        --show-info)
            show_info
            ;;
        --security-menu)
            security_menu
            ;;
        *)
            echo "用法: $0 [选项]"
            echo "可用选项:"
            echo "  --set-level <级别>"
            echo "  --show-info"
            echo "  --security-menu"
            exit 1
            ;;
    esac
fi

# ---------------------------
# 模块导出（当被source时）
# ---------------------------
export -f validate_config get_level set_level show_info security_menu