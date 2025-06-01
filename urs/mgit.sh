#!/bin/bash

# ====================== 可修改配置区域 ======================
# GitHub 镜像源列表 - 您可以在这里添加/删除/修改镜像源
mirrors=(
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
    "j.1lin.dpdns.org"
)

# 超时设置（秒）- 修改这个值可以调整测试超时时间
TIMEOUT=3

# ====================== 脚本功能区域 ======================
# 显示帮助信息
show_help() {
    echo "mgit - GitHub 镜像加速工具"
    echo "用法: mgit [选项] [git参数] <GitHub仓库URL>"
    echo
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -t, --test     仅测试镜像源速度，不执行操作"
    echo
    echo "示例:"
    echo "  mgit clone https://github.com/user/repo.git"
    echo "  mgit https://github.com/user/repo/releases/download/v1/file.zip"
    echo "  mgit -O file.zip https://github.com/user/repo/releases/download/v1/file.zip"
    echo
    echo "配置说明:"
    echo "  1. 镜像源列表可在脚本开头 'mirrors' 数组中修改"
    echo "  2. 超时设置可在 'TIMEOUT' 变量中修改（当前为 ${TIMEOUT}秒）"
    echo
    echo "提示:"
    echo "  对于 git 操作（clone/pull/fetch）会自动使用 git 命令"
    echo "  其他操作会自动使用 wget 或 curl"
}

# 检测响应时间（毫秒）
test_mirror() {
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

# 查找最快的镜像源
find_fastest_mirror() {
  # 所有测试过程输出到stderr
  echo "正在测试 GitHub 镜像源..." >&2

  declare -A mirror_speeds
  local best_time=99999
  local best_mirror=""
  
  # 新增：标记是否找到低延迟源
  local found_low_latency=0
  
  for mirror in "${mirrors[@]}"; do
      speed=$(test_mirror "$mirror")
      if [[ $speed =~ ^[0-9]+$ ]]; then
          printf "  \e[32m%-30s\e[0m → %4d ms\n" "$mirror" "$speed" >&2
          mirror_speeds[$mirror]=$speed
          
          # ===== 新增逻辑：检测到低延迟源直接使用 =====
          if [ $speed -lt 900 ]; then
              echo -e "  \e[33m发现低延迟镜像源 $mirror (${speed}ms < 900ms)，直接选用\e[0m" >&2
              best_mirror=$mirror
              best_time=$speed
              found_low_latency=1
              break  # 跳出测试循环
          fi
          # ===== 结束新增 =====
          
          # 更新最快记录
          if [ $speed -lt $best_time ]; then
              best_time=$speed
              best_mirror=$mirror
          fi
      else
          printf "  \e[31m%-30s\e[0m → %s\n" "$mirror" "$speed" >&2
      fi
  done

  if [ -z "$best_mirror" ]; then
      echo -e "\e[31m错误：没有可用的镜像源，请检查网络连接\e[0m" >&2
      return 1
  else
      # 根据是否找到低延迟源显示不同信息
      if [ $found_low_latency -eq 1 ]; then
          echo -e "\n\e[33m直接选用低延迟镜像源：$best_mirror (${best_time}ms)\e[0m" >&2
      else
          echo -e "\n\e[32m最快镜像源：$best_mirror (${best_time}ms)\e[0m" >&2
      fi
      echo "https://$best_mirror/"
      return 0
  fi
}

# 主函数
main() {
    # 处理帮助选项
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        show_help
        return 0
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
    
    local original_url=${!#}
    
    # 获取最快的镜像源
    local best_mirror=$(find_fastest_mirror)
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # 构建代理URL
    local proxy_url="${best_mirror}${original_url}"
    echo "代理地址：$proxy_url"
    
    # 执行命令
    echo "执行命令: ${*:1:$#-1} $proxy_url"
    
    # 判断命令类型
    if [[ $1 == "clone" ]] || [[ $1 == "pull" ]] || [[ $1 == "fetch" ]]; then
        git "${@:1:$#-1}" "$proxy_url"
    else
        if command -v wget &>/dev/null; then
            wget "${@:1:$#-1}" "$proxy_url"
        elif command -v curl &>/dev/null; then
            curl "${@:1:$#-1}" -L -O "$proxy_url"
        else
            echo -e "\e[31m错误：需要 wget 或 curl 但未找到\e[0m"
            return 1
        fi
    fi
}

# 执行主函数
main "$@"
