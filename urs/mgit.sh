#!/bin/bash

# ====================== 可修改配置区域 ======================
# GitHub 镜像源列表（添加官方源）
mirrors=(
    "github.com"           # 官方源
    "github.moeyy.xyz"
    "github.proxy.class3.fun"
    "ghproxy.net"
    "ghfile.geekertao.top"
    "jiashu.1win.eu.org"
    "ghf.xn--eqrr82bzpe.top"
    "github-proxy.lixxing.top"
    "gitproxy.click"
    "github.tbedu.top"
    "git.yylx.win"
    "gp-us.fyan.top"
    "gitproxy.127731.xyz"
    "j.1win.ggff.net"
    "github.kkproxy.dpdns.org"
    "tvv.tw"
    "github.cmsz.dpdns.org"
    "gitproxy1.127731.xyz"
    "gh-proxy.net"
    "github.acmsz.top"
    "github-proxy.kongkuang.icu"
)

# 超时设置（秒）
TIMEOUT=3

# 测试文件（用于速度测试）
TEST_FILE="https://github.com/ginuerzh/gost/archive/refs/tags/v2.11.5.tar.gz"
TEST_FILE_SIZE=2100000  #大小

# ====== 权重设置（可修改为以下任一模式） ======
# 模式1：完全以延迟为基准（延迟100%）
LATENCY_WEIGHT=1000
SPEED_WEIGHT=0

# 模式2：完全以速度为基准（速度100%）
# LATENCY_WEIGHT=0
# SPEED_WEIGHT=1000

# 模式3：混合模式（默认延迟90%+速度10%）
# LATENCY_WEIGHT=900
# SPEED_WEIGHT=100

# 并发线程数（根据CPU核心数自动设置）
CONCURRENCY=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
# ====================== 脚本功能区域 ======================
# 显示帮助信息
show_help() {
    echo "mgit - GitHub 镜像加速工具"
    echo "用法: mgit [选项] [git参数] <GitHub仓库URL>"
    echo
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -t, --test     仅测试镜像源速度，不执行操作"
    echo "  -l, --latency  完全以延迟为基准选择镜像"
    echo "  -s, --speed    完全以速度为基准选择镜像"
    echo
    echo "示例:"
    echo "  mgit clone https://github.com/user/repo.git"
    echo "  mgit https://github.com/user/repo/releases/download/v1/file.zip"
    echo "  mgit -O file.zip https://github.com/user/repo/releases/download/v1/file.zip"
    echo
    echo "配置说明:"
    echo "  1. 镜像源列表可在脚本开头 'mirrors' 数组中修改"
    echo "  2. 超时设置可在 'TIMEOUT' 变量中修改（当前为 ${TIMEOUT}秒）"
    echo "  3. 测试文件可在 'TEST_FILE' 变量中修改（当前测试文件大小: $((TEST_FILE_SIZE/1000))KB）"
    echo "  4. 延迟/速度权重可在 'LATENCY_WEIGHT' 和 'SPEED_WEIGHT' 中修改（当前 ${LATENCY_WEIGHT}‰延迟/${SPEED_WEIGHT}‰速度）"
    echo "  5. 并发线程数: ${CONCURRENCY} (自动检测)"
    echo
    echo "提示:"
    echo "  对于 git 操作（clone/pull/fetch）会自动使用 git 命令"
    echo "  其他操作会自动使用 wget 或 curl"
    echo "  使用 -l 或 -s 选项可临时切换权重模式"
}
# 检测响应时间（毫秒）
test_latency() {
    local mirror=$1
    
    # 使用 curl 测试实际响应时间
    local start_time=$(date +%s%3N)
    curl -sI "https://$mirror" -o /dev/null -m $TIMEOUT >/dev/null 2>&1
    local end_time=$(date +%s%3N)
    
    if [ $? -eq 0 ]; then
        echo $((end_time - start_time))
    else
        echo "timeout"
    fi
}

# 测试下载速度（KB/s）
test_speed() {
    local mirror=$1
    local test_url="https://${mirror}/${TEST_FILE#https://}"
    
    # 使用 curl 测试下载速度
    local start_time=$(date +%s)
    local downloaded_bytes=$(curl -s -w "%{size_download}" -o /dev/null -L "$test_url" -m $TIMEOUT 2>/dev/null)
    local end_time=$(date +%s)
    
    if [ $? -eq 0 ] && [ "$downloaded_bytes" -gt 0 ]; then
        local duration=$((end_time - start_time))
        if [ $duration -eq 0 ]; then
            duration=1  # 避免除以0
        fi
        local speed=$((downloaded_bytes / duration / 1024))
        echo $speed
    else
        echo "failed"
    fi
}

# 计算综合评分
calculate_score() {
    local latency=$1
    local speed=$2
    local mirror=$3
    
    # 如果是官方源且测试成功，特殊处理
    if [[ "$mirror" == "github.com" ]] && 
       [[ "$latency" != "timeout" ]] && 
       [[ "$speed" != "failed" ]]; then
        # 官方源默认给最高分
        echo 999999
        return
    fi
    
    # 处理测试失败的情况
    if [[ "$latency" == "timeout" ]] || [[ "$speed" == "failed" ]]; then
        echo -1
        return
    fi
    
    # 标准化处理（反转延迟：延迟越低越好）
    local normalized_latency=$((1000 - latency))
    if [ $normalized_latency -lt 0 ]; then
        normalized_latency=0
    fi
    
    # 加权计算
    local latency_score=$((normalized_latency * LATENCY_WEIGHT / 1000))
    local speed_score=$((speed * SPEED_WEIGHT))
    local total_score=$((latency_score + speed_score))
    
    echo $total_score
}
# 并行测试单个镜像源
test_mirror() {
    local mirror=$1
    local result_file=$2
    
    # 测试延迟
    local latency=$(test_latency "$mirror")
    
    # 测试下载速度
    local speed=$(test_speed "$mirror")
    
    # 保存结果到临时文件
    echo "$mirror $latency $speed" >> "$result_file"
}

# 查找最快的镜像源（多线程版）
find_fastest_mirror() {
    echo "正在测试 GitHub 镜像源 (延迟权重:${LATENCY_WEIGHT}‰ 速度权重:${SPEED_WEIGHT}‰)..." >&2
    echo "测试文件: ${TEST_FILE} ($((TEST_FILE_SIZE/1000))KB)" >&2
    echo "并发线程数: ${CONCURRENCY}" >&2

    # 创建临时文件存储结果
    local result_file=$(mktemp)
    
    # 创建管道用于并发控制
    local pipe=$(mktemp -u)
    mkfifo "$pipe"
    exec 3<>"$pipe"
    rm -f "$pipe"
    
    # 初始化管道
    for ((i=0; i<CONCURRENCY; i++)); do
        echo >&3
    done
    
    # 启动所有测试任务
    local pids=()
    for mirror in "${mirrors[@]}"; do
        # 等待可用槽位
        read -u 3 -t 10
        if [ $? -ne 0 ]; then
            echo "并发控制超时，跳过 $mirror" >&2
            continue
        fi
        
        # 启动后台任务
        (
            test_mirror "$mirror" "$result_file"
            # 释放槽位
            echo >&3
        ) &
        pids+=($!)
    done
    
    # 等待所有任务完成
    for pid in "${pids[@]}"; do
        wait $pid 2>/dev/null
    done
    
    # 关闭文件描述符
    exec 3>&-
    
    # 读取并处理结果
    declare -A mirror_scores
    local best_score=-1
    local best_mirror=""
    
    # 检查结果文件是否存在
    if [ ! -f "$result_file" ]; then
        echo -e "\n\e[31m错误：测试结果文件不存在，可能所有测试都失败了\e[0m" >&2
        rm -f "$result_file" 2>/dev/null
        return 1
    fi

    while read -r line; do
        local mirror=$(echo "$line" | awk '{print $1}')
        local latency=$(echo "$line" | awk '{print $2}')
        local speed=$(echo "$line" | awk '{print $3}')
        
        # 计算综合评分
        local score=$(calculate_score "$latency" "$speed" "$mirror")
        
        # 跳过无效分数
        if [ $score -eq -1 ]; then
            # 显示测试结果
            printf "  \e[31m%-30s\e[0m → " "$mirror" >&2
            if [[ "$latency" == "timeout" ]]; then
                printf "延迟: \e[31m超时\e[0m " >&2
            else
                printf "延迟: \e[31m失败\e[0m " >&2
            fi
            
            if [[ "$speed" == "failed" ]]; then
                printf "速度: \e[31m失败\e[0m " >&2
            else
                printf "速度: \e[31m失败\e[0m " >&2
            fi
            printf "评分: \e[31m无效\e[0m\n" >&2
            continue
        fi
        
        mirror_scores[$mirror]=$score
        
        # 显示测试结果
        printf "  \e[32m%-30s\e[0m → " "$mirror" >&2
        if [[ "$latency" == "timeout" ]]; then
            printf "延迟: \e[31m超时\e[0m " >&2
        else
            printf "延迟: \e[33m%4dms\e[0m " "$latency" >&2
        fi
        
        if [[ "$speed" == "failed" ]]; then
            printf "速度: \e[31m失败\e[0m " >&2
        else
            printf "速度: \e[36m%3dKB/s\e[0m " "$speed" >&2
        fi
        printf "评分: \e[35m%5d\e[0m\n" "$score" >&2
        
        # 更新最佳镜像
        if [ $score -gt $best_score ]; then
            best_score=$score
            best_mirror=$mirror
        fi
    done < "$result_file"
    
    # 清理临时文件
    rm -f "$result_file" 2>/dev/null

    if [ -z "$best_mirror" ] || [ $best_score -eq -1 ]; then
        echo -e "\n\e[31m错误：没有可用的镜像源，请检查网络连接\e[0m" >&2
        return 1
    else
        # 显示最佳镜像源详情
        local best_latency=$(test_latency "$best_mirror")
        local best_speed=$(test_speed "$best_mirror")
        
        echo -e "\n\e[32m最佳镜像源：$best_mirror\e[0m" >&2
        if [[ "$best_latency" == "timeout" ]]; then
            echo -e "  → 延迟: \e[31m超时\e[0m" >&2
        else
            echo -e "  → 延迟: \e[33m${best_latency}ms\e[0m" >&2
        fi
        
        if [[ "$best_speed" == "failed" ]]; then
            echo -e "  → 速度: \e[31m失败\e[0m" >&2
        else
            echo -e "  → 速度: \e[36m${best_speed}KB/s\e[0m" >&2
        fi
        echo -e "  → 综合评分: \e[35m${best_score}\e[0m" >&2
        echo "$best_mirror"
        return 0
    fi
}
# 构建代理URL
build_proxy_url() {
    local original_url=$1
    local best_mirror=$2
    
    # 特殊处理官方源
    if [ "$best_mirror" == "github.com" ]; then
        echo "$original_url"
        return
    fi

    # 处理中文路径等特殊字符
    original_url=$(echo "$original_url" | sed 's/ /%20/g')
    
    # 转换SSH协议到HTTPS
    if [[ "$original_url" == git@github.com:* ]]; then
        original_url="https://github.com/${original_url#git@github.com:}"
    fi
    
    # 修复关键问题：直接拼接原始URL，不去除https://
    if [[ "$original_url" =~ ^https?:// ]]; then
        echo "https://${best_mirror}/${original_url}"
    # 处理github.com开头的简写格式
    elif [[ "$original_url" =~ ^github\.com/ ]]; then
        echo "https://${best_mirror}/https://github.com/${original_url#github.com/}"
    else
        # 特殊处理ComfyUI-Manager
        if [[ "$original_url" == "/ComfyUI-Manager" || "$original_url" == "ComfyUI-Manager" ]]; then
            echo "https://${best_mirror}/https://github.com/ltdrdata/ComfyUI-Manager"
        else
            echo "$original_url"
        fi
    fi
}
# 主函数
main() {
    # 处理帮助选项
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        show_help
        return 0
    fi
    
    # 处理权重模式切换
    local weight_changed=0
    if [[ "$1" == "-l" || "$1" == "--latency" ]]; then
        LATENCY_WEIGHT=1000
        SPEED_WEIGHT=0
        shift
        weight_changed=1
    elif [[ "$1" == "-s" || "$1" == "--speed" ]]; then
        LATENCY_WEIGHT=0
        SPEED_WEIGHT=1000
        shift
        weight_changed=1
    fi
    
    # 处理测试选项
    if [[ "$1" == "-t" || "$1" == "--test" ]]; then
        find_fastest_mirror
        return $?
    fi
    
    if [ $# -lt 1 ]; then
        show_help
        return 1
    fi
    
    # 显示当前权重模式
    if [ $weight_changed -eq 1 ]; then
        echo -e "\n\e[34m已切换权重模式：延迟=${LATENCY_WEIGHT}‰ 速度=${SPEED_WEIGHT}‰\e[0m" >&2
    fi
    
    # 获取最快的镜像源
    local best_mirror=$(find_fastest_mirror)
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    local original_url=${!#}
    
    # 判断命令类型
    if [[ $1 == "clone" ]]; then
    # 提取目标路径（最后一个参数）
    local target_path="${!#}"
    
    # 构建镜像URL（原始URL是倒数第二个参数）
    local original_url="${@: -2:1}"  # 获取倒数第二个参数
    local proxy_url=$(build_proxy_url "$original_url" "$best_mirror")
    
    echo "使用镜像源: ${best_mirror}"
    echo "执行命令: git clone $proxy_url $target_path"
    
    # 执行：git clone <镜像URL> <目标路径>
    git clone "$proxy_url" "$target_path"
    elif [[ $1 == "fetch" || $1 == "pull" ]]; then
        # PULL/FETCH 命令处理
        # 检查是否在git仓库中
        if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            echo "错误：当前目录不是一个git仓库，无法执行 '$1' 命令。" >&2
            return 1
        fi

        # 获取远程名称（默认origin）
        local remote_name="origin"
        # 查找命令中指定的远程名称
        for arg in "$@"; do
            if [[ "$arg" != "fetch" && "$arg" != "pull" && ! "$arg" =~ ^- ]]; then
                remote_name="$arg"
                break
            fi
        done

        # 获取原始远程URL
        local remote_url=$(git remote get-url "$remote_name" 2>/dev/null)
        if [ $? -ne 0 ]; then
            echo "错误：远程 '$remote_name' 不存在。" >&2
            return 1
        fi

        # 构建镜像远程URL
        local proxy_remote_url=$(build_proxy_url "$remote_url" "$best_mirror")
        
        # 生成随机远程名称
        local temp_remote="mirror-$(date +%s%N)"
        
        # 添加临时远程
        git remote add "$temp_remote" "$proxy_remote_url" >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "错误：添加临时远程失败。" >&2
            return 1
        fi
        
        # 构建新命令（替换原远程名为临时远程名）
        local new_cmd=()
        for arg in "$@"; do
            if [[ "$arg" == "$remote_name" ]]; then
                new_cmd+=("$temp_remote")
            else
                new_cmd+=("$arg")
            fi
        done
        
        # 执行命令
        echo "使用镜像源: ${best_mirror}"
        echo "执行命令: git ${new_cmd[@]}"
        git "${new_cmd[@]}"
        local git_status=$?
        
        # 删除临时远程
        git remote remove "$temp_remote" >/dev/null 2>&1
        
        return $git_status
    else
        # 非git命令使用下载工具
        local proxy_url=$(build_proxy_url "$original_url" "$best_mirror")
        echo "使用镜像源: ${best_mirror}"
        echo "下载地址: $proxy_url"
        
        if command -v wget &> /dev/null; then
            wget "${@:1:$#-1}" "$proxy_url"
        elif command -v curl &> /dev/null; then
            curl -L -O "${@:1:$#-1}" "$proxy_url"
        else
            echo "错误：没有找到 wget 或 curl，无法下载。" >&2
            return 1
        fi
    fi
}

# 执行主函数
main "$@"