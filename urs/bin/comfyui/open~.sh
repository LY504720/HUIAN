#!/bin/bash

# ComfyUI 智能启动脚本
# 版本: 4.1
# 最后更新: 2024-06-15
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# 颜色定义
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
CYAN='\033[1;36m'
NC='\033[0m' # 恢复默认颜色

# ComfyUI 安装目录
COMFYUI_DIR="../../../data/ComfyUI"

# 默认参数配置
CPU_MODE=false
FORCE_FP32=false
PREVIEW_METHOD="none"
GPU_ID=0
FP16=false
BF16=false
DISABLE_CPU_OFFLOAD=false
DISABLE_SMART_MEMORY=false
DETERMINISTIC=false
DISABLE_XFORMERS=false
OUTPUT_PATH="./output"
INPUT_PATH="./input"
TEMP_PATH="./temp"
LISTEN="127.0.0.1"
PORT=8188
ENABLE_CORS=false
CORS_ORIGINS="*"

# 显示帮助信息
show_help() {
    echo -e "${GREEN}ComfyUI 启动脚本使用指南${NC} ${CYAN}v4.1${NC}"
    echo -e "${YELLOW}──────────────────────────────────────────────${NC}"
    echo -e "三种运行模式:"
    echo -e "1. ${GREEN}快速启动${NC}: 直接运行脚本使用默认配置"
    echo -e "2. ${GREEN}自定义模式${NC}: 添加${CYAN}--customize${NC}参数进行详细配置"
    echo -e "3. ${GREEN}参数模式${NC}: 直接传递参数启动 (示例: --cpu --port 8080)"
    echo -e "${YELLOW}──────────────────────────────────────────────${NC}"
    echo -e "${BLUE}核心参数说明:${NC}"
    echo -e "  ${CYAN}--cpu${NC}             强制使用CPU模式 (禁用GPU加速)"
    echo -e "  ${CYAN}--gpu <id>${NC}       指定使用的GPU (默认: 0)"
    echo -e "  ${CYAN}--fp16${NC}           启用FP16加速 (需要GPU支持)"
    echo -e "  ${CYAN}--port <num>${NC}     设置服务端口 (默认: 8188)"
    echo -e "  ${CYAN}--listen <ip>${NC}    设置监听地址 (默认: 127.0.0.1)"
    echo -e "${YELLOW}──────────────────────────────────────────────${NC}"
    echo -e "${BLUE}高级参数说明:${NC}"
    echo -e "  ${CYAN}--preview <method>${NC}  预览方式: none, auto, latent2rgb, taesd"
    echo -e "  ${CYAN}--output-path <dir>${NC} 输出文件目录"
    echo -e "  ${CYAN}--input-path <dir>${NC}  输入文件目录"
    echo -e "  ${CYAN}--disable-xformers${NC}  禁用xformers优化"
    echo -e "  ${CYAN}--enable-cors${NC}       启用跨域支持"
    echo -e "${YELLOW}──────────────────────────────────────────────${NC}"
    echo -e "${BLUE}使用示例:${NC}"
    echo -e "${CYAN}1. 快速启动${NC}: ${YELLOW}./comfyui.sh${NC}"
    echo -e "${CYAN}2. 自定义配置${NC}: ${YELLOW}./comfyui.sh --customize${NC}"
    echo -e "${CYAN}3. 直接参数启动${NC}: ${YELLOW}./comfyui.sh --cpu --port 8080${NC}"
    echo -e "${CYAN}4. 生产环境${NC}: ${YELLOW}./comfyui.sh --gpu 1 --fp16 --output-path /mnt/output${NC}"
    echo -e "${YELLOW}──────────────────────────────────────────────${NC}"
    echo -e "${RED}提示: 使用--customize参数可进入交互式配置向导${NC}"
}

# 显示输入提示
show_prompt() {
    local prompt_text="$1"
    local default_hint="$2"
    local default_value="$3"
    
    # 显示提示信息
    echo -e "${GREEN}? ${BLUE}$prompt_text${NC}" >&2
    [ -n "$default_hint" ] && echo -e "  ${YELLOW}($default_hint)${NC}" >&2
    read -p "> " answer
    
    # 返回用户输入或默认值
    echo "${answer:-$default_value}"
}

# 参数帮助提示
param_help() {
    case $1 in
        cpu) echo "强制使用CPU模式 (禁用GPU加速)" ;;
        gpu) echo "指定使用的GPU设备ID (0-7)" ;;
        fp16) echo "启用FP16半精度加速 (需要GPU支持)" ;;
        bf16) echo "启用BF16脑浮点格式 (新型硬件)" ;;
        port) echo "设置服务端口号 (1024-65535)" ;;
        listen) echo "设置监听地址 (127.0.0.1=本地, 0.0.0.0=公开)" ;;
        preview) echo "预览生成方式: none, auto, latent2rgb, taesd" ;;
        output-path) echo "设置输出文件保存路径" ;;
        input-path) echo "设置输入文件读取路径" ;;
        disable-xformers) echo "禁用xformers优化 (如遇兼容性问题)" ;;
        enable-cors) echo "启用跨域资源共享(CORS)" ;;
        *) echo "自定义参数值" ;;
    esac
}

custom_config_mode() {
    echo -e "${GREEN}┌────────────────────────────────────────────┐"
    echo -e "│          ComfyUI 自定义配置向导            │"
    echo -e "└────────────────────────────────────────────┘${NC}"
    echo -e "${YELLOW}提示: 每个参数都有说明，直接回车使用默认值${NC}"
    echo ""
    
    # 添加完整的参数帮助显示
    echo -e "${CYAN}======================================================${NC}"
    echo -e "${CYAN}                    参数详细说明                     ${NC}"
    echo -e "${CYAN}======================================================${NC}"
    show_help
    echo -e "${CYAN}======================================================${NC}"
    echo ""
    
    # 等待用户确认
    read -p "按回车键开始配置..."
    echo ""
    
    # 1. 基础配置
    echo -e "\n${BLUE}=== 基础配置 ===${NC}"
    CPU_MODE=$(show_prompt "$(param_help cpu)" "y/n" "n")
    [[ "$CPU_MODE" == "y" ]] && CPU_MODE=true || CPU_MODE=false

    if [ "$CPU_MODE" = false ]; then
        GPU_ID=$(show_prompt "$(param_help gpu)" "默认: 0" "0")
        
        FP16_CHOICE=$(show_prompt "$(param_help fp16)" "y/n" "y")
        [[ "$FP16_CHOICE" == "y" ]] && FP16=true || FP16=false
        
        DISABLE_XFORMERS=$(show_prompt "$(param_help disable-xformers)" "y/n" "n")
        [[ "$DISABLE_XFORMERS" == "y" ]] && DISABLE_XFORMERS=true || DISABLE_XFORMERS=false
    fi

    # 2. 网络配置
    echo -e "\n${BLUE}=== 网络配置 ===${NC}"
    LISTEN=$(show_prompt "$(param_help listen)" "默认: 127.0.0.1" "127.0.0.1")
    PORT=$(show_prompt "$(param_help port)" "默认: 8188" "8188")
    
    if [ "$LISTEN" == "0.0.0.0" ]; then
        ENABLE_CORS=$(show_prompt "$(param_help enable-cors)" "y/n" "y")
        [[ "$ENABLE_CORS" == "y" ]] && ENABLE_CORS=true || ENABLE_CORS=false
        
        if [ "$ENABLE_CORS" = true ]; then
            CORS_ORIGINS=$(show_prompt "允许的CORS来源" "默认: *" "*")
        fi
    fi

    # 3. 路径配置
    echo -e "\n${BLUE}=== 路径配置 ===${NC}"
    OUTPUT_PATH=$(show_prompt "$(param_help output-path)" "默认: ./output" "./output")
    INPUT_PATH=$(show_prompt "$(param_help input-path)" "默认: ./input" "./input")

    # 4. 高级配置
    echo -e "\n${BLUE}=== 高级配置 ===${NC}"
    PREVIEW_METHOD=$(show_prompt "$(param_help preview)" "默认: none" "none")
    
    echo -e "\n${GREEN}配置完成! 生成启动命令...${NC}"
}

# 构建启动命令
build_launch_command() {
    # 切换到ComfyUI目录并启动
    local cmd="cd $SCRIPT_DIR && cd \"$COMFYUI_DIR\" && python3 main.py"
    
    # 添加基础参数
    [ "$CPU_MODE" = true ] && cmd="$cmd --cpu"
    [ "$FORCE_FP32" = true ] && cmd="$cmd --force-fp32"
    [ "$FP16" = true ] && cmd="$cmd --force-fp16"
    
    # 添加GPU相关参数
    if [ "$CPU_MODE" = false ]; then
        cmd="$cmd --cuda-device $GPU_ID"
        [ "$DISABLE_XFORMERS" = true ] && cmd="$cmd --disable-xformers"
    fi
    
    # 添加路径参数
    cmd="$cmd --output-directory \"$OUTPUT_PATH\""
    cmd="$cmd --input-directory \"$INPUT_PATH\""
    cmd="$cmd --temp-directory \"$TEMP_PATH\""
    
    # 添加网络参数
    cmd="$cmd --listen $LISTEN"
    cmd="$cmd --port $PORT"
    
    # 添加CORS参数（使用新格式）
    if [ "$ENABLE_CORS" = true ]; then
        if [ "$CORS_ORIGINS" = "*" ]; then
            cmd="$cmd --enable-cors-header"
        else
            cmd="$cmd --enable-cors-header \"$CORS_ORIGINS\""
        fi
    fi
    
    # 添加预览参数（使用新格式）
    if [ "$PREVIEW_METHOD" != "none" ]; then
        cmd="$cmd --preview-method $PREVIEW_METHOD"
    fi
    
    # 添加其他参数
    [ "$DISABLE_SMART_MEMORY" = true ] && cmd="$cmd --disable-smart-memory"
    [ "$DISABLE_CPU_OFFLOAD" = true ] && cmd="$cmd --disable-cpu-offload"
    [ "$DETERMINISTIC" = true ] && cmd="$cmd --deterministic"
    
    echo "$cmd"
}

# 参数解析
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --cpu) CPU_MODE=true; shift ;;
            --force-fp32) FORCE_FP32=true; shift ;;
            --preview) PREVIEW_METHOD="$2"; shift 2 ;;
            --gpu) GPU_ID="$2"; shift 2 ;;
            --fp16) FP16=true; shift ;;
            --bf16) BF16=true; shift ;;
            --disable-cpu-offload) DISABLE_CPU_OFFLOAD=true; shift ;;
            --disable-smart-memory) DISABLE_SMART_MEMORY=true; shift ;;
            --disable-xformers) DISABLE_XFORMERS=true; shift ;;
            --deterministic) DETERMINISTIC=true; shift ;;
            --output-path) OUTPUT_PATH="$2"; shift 2 ;;
            --input-path) INPUT_PATH="$2"; shift 2 ;;
            --temp-path) TEMP_PATH="$2"; shift 2 ;;
            --listen) LISTEN="$2"; shift 2 ;;
            --port) PORT="$2"; shift 2 ;;
            --enable-cors) ENABLE_CORS=true; shift ;;
            --cors-origins) CORS_ORIGINS="$2"; shift 2 ;;
            --customize) CUSTOM_MODE=true; shift ;;
            --help) show_help; exit 0 ;;
            *) echo -e "${RED}未知参数: $1${NC}"; show_help; exit 1 ;;
        esac
    done
}

# 主函数
main() {
    # 检查自定义模式
    if [[ "$1" == "--customize" ]]; then
        custom_config_mode
        LAUNCH_CMD=$(build_launch_command)
        
        echo -e "\n${GREEN}生成的启动命令:${NC}"
        echo -e "${YELLOW}$LAUNCH_CMD${NC}"
        
        read -p "是否立即执行? (y/n) " execute
        if [[ "$execute" == "y" ]]; then
            echo -e "\n${GREEN}启动ComfyUI...${NC}"
            eval $LAUNCH_CMD
        else
            echo -e "\n${YELLOW}已生成命令但未执行。可复制上方命令手动启动。${NC}"
        fi
        exit 0
    fi

    # 解析其他参数
    parse_arguments "$@"
    
    # 构建并执行命令
    LAUNCH_CMD=$(build_launch_command)
    
    # 显示启动信息
    echo -e "${GREEN}启动ComfyUI...${NC}"
    echo -e "${CYAN}运行命令: ${YELLOW}$LAUNCH_CMD${NC}"
    echo ""
    
    eval $LAUNCH_CMD
}

# 启动主函数
main "$@"