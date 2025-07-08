#!/bin/bash
cd /home/ec2-user/itwords-app

# 创建简化版docker-compose
cat > docker-compose-simple.yml << 'COMPOSE'
version: '3.8'
services:
  web:
    image: nginx:alpine
    container_name: itwords-web
    ports:
      - "80:80"
    volumes:
      - ./html:/usr/share/nginx/html
    restart: always
COMPOSE

# 创建测试网页
mkdir -p html
cat > html/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>IT Words Learning - AWS部署成功!</title>
    <style>
        body { font-family: Arial; text-align: center; padding: 50px; background: #f0f0f0; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 40px; border-radius: 10px; box-shadow: 0 4px 8px rgba(0,0,0,0.1); }
        h1 { color: #2196F3; }
        .success { color: #4CAF50; font-size: 18px; font-weight: bold; }
        .info { background: #e3f2fd; padding: 15px; margin: 20px 0; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 IT Words Learning</h1>
        <div class="success">✅ AWS EC2部署成功!</div>
        
        <div class="info">
            <h3>📋 部署信息</h3>
            <p><strong>服务器:</strong> AWS EC2 t3.micro (免费层)</p>
            <p><strong>IP地址:</strong> 3.226.248.245</p>
            <p><strong>状态:</strong> 运行中</p>
            <p><strong>费用:</strong> 完全免费!</p>
        </div>

        <div class="info">
            <h3>🌐 接下来配置免费域名</h3>
            <p>🔗 DuckDNS: itwords.duckdns.org</p>
            <p>🔗 ngrok: https://xxx.ngrok.io</p>
        </div>
    </div>
</body>
</html>
HTML

# 停止之前的容器
sudo docker stop itwords-web 2>/dev/null || true
sudo docker rm itwords-web 2>/dev/null || true

# 启动新服务
sudo docker-compose -f docker-compose-simple.yml up -d

# 检查状态
sudo docker ps
echo "网站应该在 http://3.226.248.245 可以访问了!"
