#!/bin/bash

# 创建自启动文件 (修正路径为完整文件路径)
STARTUP_SCRIPT="/data/data/com.termux/files/usr/etc/profile.d/666.sh"


# 纯文本确认界面
    read -p "系统安装程序已准备就绪，是否立即开始安装？[y/n] " yn
    case $yn in
        [Yy]* ) 
        rm ubuntu.tar.gz
pkg install proot -y
pkg install git
            echo "正在启动安装过程..."
            wget https://ghproxy.net/https://github.com/LY504720/android-comfyui-zerotermux/releases/download/install-beta0.2/ubuntu.tar.gz
            tar -xzvf ubuntu.tar.gz
            cd ubuntu-in-termux/ubuntu-fs/home/sd/cohui
            rm -rf android-comfyui-zerotermux
            git clone https://github.proxy.class3.fun/https://github.com/LY504720/android-comfyui-zerotermux.git
            cd
            cp ubuntu-in-termux/ubuntu-fs/home/sd/cohui/android-comfyui-zerotermux/安装系统.sh ubuntu-in-termux/ubuntu-fs/home/qd/安装系统.sh
                
                rm -rf ubuntu-in-termux/ubuntu-fs/home/sd/cohui/android-comfyui-zerotermux
                



            
            echo "安装完成请重启或输入 一键三连 启动"
rm ubuntu.tar.gz
            # 创建临时脚本文件
cat > 666.sh << 'EOF'
#!/bin/bash
alias 一键三连='bash ubuntu-in-termux/startubuntu.sh'
bash /data/data/com.termux/files/home/ubuntu-in-termux/startubuntu.sh
EOF

# 移动并设置权限 (修正移动目标路径)
mv 666.sh "$STARTUP_SCRIPT"
chmod +x "$STARTUP_SCRIPT"
           ;;
        [Nn]* )
            echo "安装已取消"
            # 清理修正后的文件路径
            rm -f "$STARTUP_SCRIPT"
            exit 1;;
        * ) 
            echo "请输入 y 或 n";;
    esac
