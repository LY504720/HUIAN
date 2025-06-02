#!/bin/bash
# ComfyUI 节点管理工具 - 集成安装、更新和安全设置
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"

# 固定路径配置
COMFYUI_DIR="/home/HUIAN/data/ComfyUI"
MANAGER_DIR="$COMFYUI_DIR/custom_nodes/ComfyUI-Manager"
MANAGER_CONFIG="$COMFYUI_DIR/user/default/ComfyUI-Manager/config.ini"

# 验证配置文件
validate_config() {
    [ -z "$MANAGER_CONFIG" ] && return 1
    [ ! -f "$MANAGER_CONFIG" ] && return 2
    grep -q "security_level" "$MANAGER_CONFIG" || return 3
    return 0
}

# 获取当前安全级别
get_level() {
    validate_config && grep '^security_level' "$MANAGER_CONFIG" | awk -F= '{print $2}' | tr -d ' ' || echo "未知"
}

# 设置安全级别
set_level() {
    local level=$1
    validate_config || return 1
    
    # 备份并更新配置
    cp "$MANAGER_CONFIG" "${MANAGER_CONFIG}.bak"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^security_level = .*/security_level = $level/" "$MANAGER_CONFIG"
    else
        sed -i "s/^security_level = .*/security_level = $level/" "$MANAGER_CONFIG"
    fi
    
    # 验证是否设置成功
    [ "$(get_level)" == "$level" ] && return 0
    return 1
}

# 显示安全级别说明
show_info() {
    clear
    echo "=============================================="
    echo " 安全级别说明"
    echo "=============================================="
    echo " Strict (最严格):"
    echo "   禁止所有外部插件安装，仅允许官方认证插件"
    echo "   最高安全级别，防止恶意插件"
    echo ""
    echo " Normal (默认):"
    echo "   允许从官方仓库安装插件"
    echo "   默认安全级别，平衡安全与功能"
    echo ""
    echo " Weak (最低):"
    echo "   允许任意来源安装插件"
    echo "   用于临时安装第三方插件"
    echo "=============================================="
    read -p "按 Enter 键返回主菜单..."
}

# 安装节点管理器
install_manager() {
    clear
    echo "=============================================="
    echo " 安装 ComfyUI 节点管理器"
    echo "=============================================="
    
    # 检查是否已安装
    if [ -d "$MANAGER_DIR" ]; then
        echo "节点管理器已安装，请使用更新功能。"
        read -p "按 Enter 键返回主菜单..."
        return
    fi
    
    echo "正在安装节点管理器..."
    
    # 创建必要的目录
    mkdir -p "$COMFYUI_DIR/custom_nodes"
    
    # 克隆仓库
    mgit clone https://github.com/ltdrdata/ComfyUI-Manager.git "$MANAGER_DIR"
    
    # 检查是否安装成功
    if [ -d "$MANAGER_DIR" ]; then
        echo ""
        echo "=============================================="
        echo " 节点管理器安装成功！"
        echo " 请重启 ComfyUI 服务使更改生效"
        echo "=============================================="
    else
        echo ""
        echo "=============================================="
        echo " 安装失败，请检查网络连接和目录权限"
        echo "=============================================="
    fi
    
    read -p "按 Enter 键返回主菜单..."
}

# 更新节点管理器
update_manager() {
    clear
    echo "=============================================="
    echo " 更新 ComfyUI 节点管理器"
    echo "=============================================="
    
    # 检查是否已安装
    if [ ! -d "$MANAGER_DIR" ]; then
        echo "节点管理器未安装，请先安装。"
        read -p "按 Enter 键返回主菜单..."
        return
    fi
    
    echo "正在更新节点管理器..."
    
    # 进入目录并更新
    cd "$MANAGER_DIR"
    git pull origin main
    
    # 检查更新结果
    if [ $? -eq 0 ]; then
        echo ""
        echo "=============================================="
        echo " 节点管理器更新成功！"
        echo " 请重启 ComfyUI 服务使更改生效"
        echo "=============================================="
    else
        echo ""
        echo "=============================================="
        echo " 更新失败，请检查网络连接或手动更新"
        echo "=============================================="
    fi
    
    cd "$SCRIPT_DIR"
    read -p "按 Enter 键返回主菜单..."
}

# 显示主菜单
show_menu() {
    clear
    echo "=============================================="
    echo " ComfyUI 节点管理工具"
    echo "=============================================="
    echo " 管理器路径: $MANAGER_DIR"
    echo " 配置文件: $MANAGER_CONFIG"
    echo " 当前安全级别: $(get_level)"
    echo "----------------------------------------------"
    echo " 1) 安装节点管理器"
    echo " 2) 更新节点管理器"
    echo " 3) 设置安全级别"
    echo " 4) 安全级别说明"
    echo " 0) 退出"
    echo "=============================================="
}

# 安全级别设置子菜单
security_menu() {
    while true; do
        clear
        echo "=============================================="
        echo " 安全级别设置"
        echo "=============================================="
        echo " 配置文件: $MANAGER_CONFIG"
        echo " 当前安全级别: $(get_level)"
        echo "----------------------------------------------"
        echo " 1) 设为最严格 (Strict)"
        echo " 2) 设为默认 (Normal)"
        echo " 3) 设为最低 (Weak)"
        echo " 4) 返回主菜单"
        echo "=============================================="
        
        read -p "请选择操作 [1-4]: " choice
        
        case $choice in
            1) level="strict";;
            2) level="normal";;
            3) level="weak";;
            4) return;;
            *) echo "无效选择，请重新输入"; sleep 1; continue;;
        esac
        
        if set_level "$level"; then
            echo ""
            echo "=============================================="
            echo " 安全级别已成功设置为: $level"
            echo " 请重启 ComfyUI 服务使更改生效"
            echo "=============================================="
            sleep 2
        else
            echo ""
            echo "=============================================="
            echo " 设置失败，请检查配置文件是否正确"
            echo " 路径: $MANAGER_CONFIG"
            echo "=============================================="
            sleep 2
        fi
    done
}

# 主程序
main() {
    while true; do
        show_menu
        read -p "请选择操作 [0-4]: " choice
        
        case $choice in
            1) install_manager;;
            2) update_manager;;
            3) security_menu;;
            4) show_info;;
            0) echo "退出程序"; exit 0;;
            *) echo "无效选择，请重新输入"; sleep 1;;
        esac
    done
}

# 启动程序
main
