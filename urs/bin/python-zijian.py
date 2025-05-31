#!/usr/bin/env python3
# ComfyUI Termux-Ubuntu环境检查精简版

import os, sys, platform, subprocess, re, shutil, socket
from termcolor import colored

def is_termux():
    return 'com.termux' in os.environ.get('PREFIX', '')

def print_header():
    print(colored("\nComfyUI Termux环境检查精简版", 'cyan', attrs=['bold']))
    print(f"系统: {platform.system()} | Python: {sys.version.split()[0]}")
    print(f"环境: {'Termux' if is_termux() else '常规Linux'}\n")

def check_essentials():
    print(colored(">>> 基础检查", 'yellow'))
    checks = {
        "Python版本": (3, 8) <= sys.version_info[:2] <= (3, 11),
        "存储空间": (shutil.disk_usage('/data/data/com.termux/files/home' if is_termux() else '/').free / (1024**3)) > 8,
        "内存": get_available_mem() > 2,
        "CPU核心": os.cpu_count() >=4
    }
    for name, status in checks.items():
        print(f"{name}: {colored('通过','green') if status else colored('失败','red')}")
    return all(checks.values())

def get_available_mem():
    try:
        if is_termux():
            cmd = "termux-memory-info | grep 'Available RAM' | awk '{print $4}'"
            return int(subprocess.getoutput(cmd))/1024**2
        with open('/proc/meminfo') as f:
            mem = f.read()
            return (int(re.search(r'MemFree:\s+(\d+)', mem).group(1)) + 
                   int(re.search(r'Cached:\s+(\d+)', mem).group(1)))/1024**2
    except:
        return 0

def check_network():
    print(colored("\n>>> 网络检查", 'yellow'))
    try:
        if subprocess.run(['ping','-c','1','github.com'], capture_output=True).returncode == 0:
            print(colored("✓ 网络正常", 'green'))
            return True
        print(colored("❌ 网络异常", 'red'))
    except:
        print(colored("❌ 网络检查失败", 'red'))
    return False

def check_pip():
    print(colored("\n>>> PIP检查", 'yellow'))
    try:
        pip_ver = subprocess.getoutput(f"{sys.executable} -m pip --version")
        print(colored(f"✓ {pip_ver.split()[1]}", 'green'))
        return True
    except:
        print(colored("❌ PIP未安装", 'red'))
        return False

if __name__ == "__main__":
    print_header()
    if check_essentials() and check_network() and check_pip():
        print(colored("\n环境检查通过，可以尝试安装ComfyUI", 'green'))
    else:
        print(colored("\n环境存在问题，请根据提示修复", 'red'))