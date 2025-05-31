#!/bin/bash

# 颜色配置
color_frame="\033[38;5;39m"   # 科技蓝边框
color_title="\033[1;36m"      # 青色标题
color_highlight="\033[1;33m"  # 黄色高亮
color_normal="\033[0m"        # 默认颜色
color_content="\033[37m"      # 灰色内容文本
color_page="\033[38;5;202m"   # 页码颜色

confirm_label="我已阅读知晓"   # 确认选项文字
default_selection=1           # 固定选中确认项
# 通知内容配置
notice_title="重要系统通知"
notice_content=(
    "这是一个由高中业余程序员写的项目"
    "本项目旨在让ai绘画对零基础用户更友好"
    "并尝试在termux上复刻\"绘世\"启动器"
    "但更多的是作者学习的一个过程"
    "项目中untapped文件夹堆积了所有未被采纳，或部分采纳的代码，如果你也对shll感兴趣的话可以看看（屎山）"
    "那么，祝你玩的愉快"
    "还有很多不足的地方欢迎进群交流qq:833128381"
    "因为邻近高考本项目不会太频繁的更新"
    "看看他的主页【杨柳鲤余的个人空间-哔哩哔哩】 https://b23.tv/hJYHoml"
    "(悄悄告诉你：也许在某些界面按~会有惊喜呢？)"
    "更多内容1: 项目未使用开源协议，你想怎么搞就怎么搞"
    "更多内容2: 支持Linux/Android/WSL平台"
    "更多内容3: 使用Python作为核心处理语言"
    "更多内容4: 包含多种预训练模型"
    "更多内容5: 提供一键安装脚本"
    "更多内容6: 新手友好型界面设计"
    "更多内容7: 包含详细的使用文档"
    "更多内容8: 定期更新模型资源"
    "更多内容9: 提供问题反馈渠道"
)
hint_text="提示：←→翻页查看，最后一页按Enter确认"
footer_text="[重要通知] 请务必阅读所有内容后再确认"

confirm_action() {
    clear
    echo -e "${color_title}=== 通知已确认 ===${color_normal}"
    echo "感谢您的确认，感谢您的支持"
    read -n 1 -s -r -p "按任意键退出..."
    exit 0
}


# 全局变量
current_page=0
items_per_page=8
total_pages=$(( (${#notice_content[@]} + items_per_page - 1) / items_per_page ))


source ../tz.sh