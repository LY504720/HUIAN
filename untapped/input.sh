#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"

source conf.sh
beautify=1
case "beautify" in
1)
echo "启用美化"
update_rainbow_ps1() {
    local colors=("31" "32" "33" "34" "35" "36" "91" "92" "93" "94" "95" "96")
    local venv_prefix=""
    
    # 检查是否在虚拟环境中
    if [ -n "$VIRTUAL_ENV" ]; then
        venv_prefix="\[\e[1;37m\](venv) "  # 灰色标识虚拟环境
    fi

    PS1="${venv_prefix}\[\e[1;${colors[RANDOM % ${#colors[@]}]}m\]HUIAN-"
    PS1+="\[\e[1;${colors[RANDOM % ${#colors[@]}]}m\](＾ｖ＾)"
    PS1+="\[\e[0m\]:\[\e[1;${colors[RANDOM % ${#colors[@]}]}m\]\w\[\e[0m\]\\$ "
}

PROMPT_COMMAND=update_rainbow_ps1
;;

esac

cd
