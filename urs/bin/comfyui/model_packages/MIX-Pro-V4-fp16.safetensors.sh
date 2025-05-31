#!/bin/bash

# 模型信息
MODEL_NAME="detail_enhancer.safetensors"
MODEL_URL="https://hf-mirror.com/AIARTCHAN/MIX-Pro-V4/resolve/main/MIX-Pro-V4-fp16.safetensors"
TARGET_DIR="$MODEL_DIR/loras"

# 下载模型 - 使用wget
echo "下载模型: $MODEL_NAME"
wget -c -O "$TARGET_DIR/$MODEL_NAME" "$MODEL_URL"

# 检查结果
if [ $? -eq 0 ]; then
    echo "安装成功! 模型位置: $TARGET_DIR/$MODEL_NAME"
    exit 0
else
    echo "安装失败!"
    exit 1
fi