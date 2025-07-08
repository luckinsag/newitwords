#!/bin/bash

# ngrok安装和配置脚本
# 提供立即可用的免费HTTPS域名

echo "🚀 安装ngrok..."

# 下载ngrok
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
sudo apt update && sudo apt install ngrok

# 或者直接下载binary（适用于Amazon Linux）
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
tar -xzf ngrok-v3-stable-linux-amd64.tgz
sudo mv ngrok /usr/local/bin/

echo "✅ ngrok安装完成！"
echo ""
echo "🔧 使用方法："
echo "1. 注册ngrok账户: https://dashboard.ngrok.com/signup"
echo "2. 获取authtoken"
echo "3. 运行: ngrok config add-authtoken YOUR_TOKEN"
echo "4. 启动隧道: ngrok http 80"
echo ""
echo "🌐 您将获得类似这样的免费域名："
echo "   https://abc123.ngrok.io"
echo ""
echo "💡 优势："
echo "- 立即可用的HTTPS域名"
echo "- 无需配置DNS"
echo "- 自动SSL证书"
echo "- 免费版本够用" 