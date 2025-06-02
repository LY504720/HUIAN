#!/bin/bash

# ComfyUI 插件管理器安装脚本
# 安装 ComfyUI-Manager 并添加权限管理功能
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"
# 颜色定义
color_green="\033[0;32m"
color_yellow="\033[0;33m"
color_red="\033[0;31m"
color_blue="\033[0;34m"
color_reset="\033[0m"

# ComfyUI 根目录
COMFYUI_DIR="../../../data/ComfyUI"
CUSTOM_NODES_DIR="$COMFYUI_DIR/custom_nodes"

# ComfyUI-Manager 仓库
MANAGER_REPO="https://github.com/ltdrdata/ComfyUI-Manager.git"
MANAGER_DIR="$CUSTOM_NODES_DIR/ComfyUI-Manager"

# 权限管理脚本
PERMISSION_SCRIPT="$MANAGER_DIR/permission_manager.py"

# 检查 ComfyUI 目录是否存在
check_comfyui_dir() {
    if [ ! -d "$COMFYUI_DIR" ]; then
        echo -e "${color_red}错误: ComfyUI 目录不存在 - $COMFYUI_DIR${color_reset}"
        exit 1
    fi
    
    # 创建 custom_nodes 目录如果不存在
    if [ ! -d "$CUSTOM_NODES_DIR" ]; then
        echo -e "${color_yellow}创建 custom_nodes 目录...${color_reset}"
        mkdir -p "$CUSTOM_NODES_DIR"
    fi
}

# 安装 ComfyUI-Manager
install_manager() {
    echo -e "${color_green}正在安装 ComfyUI-Manager...${color_reset}"
    
    # 检查是否已安装
    if [ -d "$MANAGER_DIR" ]; then
        echo -e "${color_yellow}ComfyUI-Manager 已存在，尝试更新...${color_reset}"
        cd "$MANAGER_DIR"
        git pull
        cd - > /dev/null
    else
        # 克隆仓库
        mgit clone "$MANAGER_REPO" "$MANAGER_DIR"
    fi
    
    # 检查安装结果
    if [ $? -ne 0 ]; then
        echo -e "${color_red}安装失败!${color_reset}"
        exit 1
    fi
    
    echo -e "${color_green}ComfyUI-Manager 安装成功!${color_reset}"
}

# 添加权限管理功能
# 添加权限管理功能
add_permission_management() {
    echo -e "${color_green}添加权限管理功能...${color_reset}"
    
    # 创建权限管理脚本
    cat > "$PERMISSION_SCRIPT" << 'EOL'
#!/usr/bin/env python3
"""
ComfyUI-Manager 权限管理模块
提供插件安装、更新和删除的权限控制
"""

import os
import json
import hashlib
from enum import Enum

class PermissionLevel(Enum):
    ADMIN = 0
    USER = 1
    GUEST = 2

class PermissionManager:
    def __init__(self, config_path="permissions.json"):
        self.config_path = config_path
        self.permissions = self.load_permissions()
        
        # 默认权限设置
        self.default_permissions = {
            "install_plugin": PermissionLevel.ADMIN.value,
            "update_plugin": PermissionLevel.ADMIN.value,
            "remove_plugin": PermissionLevel.ADMIN.value,
            "install_model": PermissionLevel.USER.value,
            "remove_model": PermissionLevel.ADMIN.value
        }
    
    def load_permissions(self):
        """加载权限配置"""
        if os.path.exists(self.config_path):
            try:
                with open(self.config_path, "r") as f:
                    return json.load(f)
            except:
                return {}
        return {}
    
    def save_permissions(self):
        """保存权限配置"""
        with open(self.config_path, "w") as f:
            json.dump(self.permissions, f, indent=2)
    
    def get_permission(self, action, user_level):
        """检查用户是否有权限执行操作"""
        # 获取操作所需的最低权限级别
        required_level = self.permissions.get(action, self.default_permissions.get(action, PermissionLevel.ADMIN.value))
        
        # 检查用户权限级别
        return user_level.value <= required_level
    
    def set_permission(self, action, level):
        """设置操作的权限级别"""
        if not isinstance(level, int) or level < 0 or level > 2:
            raise ValueError("无效的权限级别")
        
        self.permissions[action] = level
        self.save_permissions()
    
    def hash_password(self, password):
        """哈希密码"""
        return hashlib.sha256(password.encode()).hexdigest()
    
    def authenticate(self, username, password):
        """用户认证"""
        # 这里简化处理，实际应用中应从安全存储中获取
        users = {
            "admin": {
                "password_hash": "8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918",  # admin
                "level": PermissionLevel.ADMIN
            },
            "user": {
                "password_hash": "04f8996da763b7a969b1028ee3007569eaf3a635486ddab211d512c85b9df8fb",  # user
                "level": PermissionLevel.USER
            }
        }
        
        if username in users:
            user_data = users[username]
            if self.hash_password(password) == user_data["password_hash"]:
                return user_data["level"]
        
        return PermissionLevel.GUEST

# 集成到 ComfyUI-Manager
def setup():
    # 创建权限管理器实例
    manager = PermissionManager()
    
    # 在这里添加与 ComfyUI-Manager 集成的代码
    # 例如，在关键操作前添加权限检查
    
    print("权限管理模块已激活")

if __name__ == "__main__":
    # 测试权限管理
    pm = PermissionManager()
    
    # 测试认证
    user_level = pm.authenticate("admin", "admin")
    print(f"管理员权限级别: {user_level}")
    
    # 测试权限检查
    can_install = pm.get_permission("install_plugin", user_level)
    print(f"管理员可以安装插件: {can_install}")
    
    # 更改权限设置
    pm.set_permission("install_plugin", PermissionLevel.USER.value)
    
    # 再次测试
    user_level = pm.authenticate("user", "user")
    can_install = pm.get_permission("install_plugin", user_level)
    print(f"普通用户可以安装插件: {can_install}")

EOL

    # 添加执行权限
    chmod +x "$PERMISSION_SCRIPT"
    
    # 修改 ComfyUI-Manager 的 __init__.py 来集成权限管理
    INIT_FILE="$MANAGER_DIR/__init__.py"
    if [ -f "$INIT_FILE" ]; then
        # 检查是否已经添加过集成代码
        if ! grep -q "permission_manager" "$INIT_FILE"; then
            echo -e "${color_green}集成权限管理到 ComfyUI-Manager...${color_reset}"
            
            # 修复：添加 os 模块导入
            sed -i "1iimport os\nimport sys\nsys.path.append(os.path.dirname(os.path.realpath(__file__)))\nfrom permission_manager import setup as setup_permissions" "$INIT_FILE"
        else
            # 检查并修复缺失的 os 导入
            if ! grep -q "import os" "$INIT_FILE"; then
                echo -e "${color_yellow}修复: 添加缺失的 os 导入${color_reset}"
                sed -i "1iimport os" "$INIT_FILE"
            else
                echo -e "${color_yellow}权限管理已经集成，跳过...${color_reset}"
            fi
        fi
    else
        echo -e "${color_red}错误: 找不到 ComfyUI-Manager 的 __init__.py 文件${color_reset}"
    fi
    
    echo -e "${color_green}权限管理功能添加完成!${color_reset}"
}
# 创建默认配置文件
create_default_config() {
    CONFIG_FILE="$MANAGER_DIR/permissions.json"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${color_green}创建默认权限配置文件...${color_reset}"
        
        cat > "$CONFIG_FILE" << 'EOL'
{
  "install_plugin": 0,
  "update_plugin": 0,
  "remove_plugin": 0,
  "install_model": 1,
  "remove_model": 0
}
EOL
    fi
}

# 显示安装完成信息
show_completion() {
    # 获取绝对路径
    local abs_manager_dir=$(realpath "$MANAGER_DIR")
    local abs_permission_script=$(realpath "$PERMISSION_SCRIPT")
    local abs_config_file=$(realpath "$MANAGER_DIR/permissions.json")
    
    echo -e "\n${color_green}=============================================="
    echo -e "ComfyUI-Manager 安装完成!"
    echo -e "==============================================${color_reset}"
    echo -e "${color_blue}安装目录: $abs_manager_dir${color_reset}"
    echo -e "${color_blue}权限管理脚本: $abs_permission_script${color_reset}"
    echo -e "\n${color_yellow}使用说明:"
    echo -e "1. 启动 ComfyUI 后，在Web界面中会出现插件管理菜单"
    echo -e "2. 默认管理员账号: admin, 密码: admin"
    echo -e "3. 默认普通用户账号: user, 密码: user"
    echo -e "4. 权限配置文件: $abs_config_file"
    echo -e "   - 0: 管理员权限"
    echo -e "   - 1: 普通用户权限"
    echo -e "   - 2: 访客权限${color_reset}"
    echo -e "\n${color_green}安装完成!${color_reset}\n"
}
# 主安装流程
main() {
    echo -e "\n${color_green}开始安装 ComfyUI-Manager 插件管理器${color_reset}"
    
    # 检查目录
    check_comfyui_dir
    
    # 安装管理器
    install_manager
    
    # 添加权限管理
    add_permission_management
    
    # 创建默认配置
    create_default_config
    
    # 显示完成信息
    show_completion
}

# 执行主函数
main
