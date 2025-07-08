#!/bin/bash

# 启动AWS资源脚本
# 用于启动ITWords项目的所有AWS资源并部署应用

echo "🚀 启动ITWords项目AWS资源..."

# 配置变量
INSTANCE_ID="i-0afe53952ee8a6190"
REGION="us-east-1"
RDS_INSTANCE="itwords-db"
KEY_PATH="./aws-deployment/itwords-key.pem"
DUCKDNS_SUBDOMAIN="itwords"
DUCKDNS_TOKEN="bb3a6ba6-5885-4e66-966d-0c0acce87e6e"

# 检查AWS CLI配置
echo "📋 检查AWS配置..."
if ! aws configure list | grep -q access_key; then
    echo "❌ AWS CLI未配置，请先运行 aws configure"
    exit 1
fi

# 检查密钥文件
if [ ! -f "$KEY_PATH" ]; then
    echo "❌ 找不到密钥文件: $KEY_PATH"
    exit 1
fi

# 设置密钥文件权限
chmod 600 "$KEY_PATH"

# 检查当前实例状态
echo "📋 检查EC2实例状态..."
INSTANCE_STATE=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --region $REGION \
    --query 'Reservations[0].Instances[0].State.Name' \
    --output text 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "❌ 无法获取实例状态，请检查实例ID和权限"
    exit 1
fi

echo "📋 实例当前状态: $INSTANCE_STATE"

# 启动EC2实例
if [ "$INSTANCE_STATE" = "stopped" ]; then
    echo "🚀 启动EC2实例 $INSTANCE_ID..."
    aws ec2 start-instances \
        --instance-ids $INSTANCE_ID \
        --region $REGION
    
    if [ $? -eq 0 ]; then
        echo "✅ 启动命令已发送"
        
        # 等待实例完全启动
        echo "⏳ 等待实例启动（可能需要1-2分钟）..."
        aws ec2 wait instance-running \
            --instance-ids $INSTANCE_ID \
            --region $REGION
        
        echo "✅ EC2实例已启动"
    else
        echo "❌ 启动实例失败"
        exit 1
    fi
elif [ "$INSTANCE_STATE" = "running" ]; then
    echo "ℹ️  实例已经在运行中"
else
    echo "⚠️  实例状态: $INSTANCE_STATE，请手动检查"
    exit 1
fi

# 等待实例状态检查通过
echo "⏳ 等待实例状态检查通过..."
aws ec2 wait instance-status-ok \
    --instance-ids $INSTANCE_ID \
    --region $REGION
echo "✅ 实例状态检查通过"

# 获取实例公网IP
echo "📋 获取实例公网IP..."
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --region $REGION \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

if [ "$PUBLIC_IP" = "None" ] || [ -z "$PUBLIC_IP" ]; then
    echo "❌ 无法获取公网IP"
    exit 1
fi

echo "📋 实例公网IP: $PUBLIC_IP"

# 更新DuckDNS域名
echo "🌐 更新DuckDNS域名..."
DUCKDNS_RESPONSE=$(curl -s "https://www.duckdns.org/update?domains=${DUCKDNS_SUBDOMAIN}&token=${DUCKDNS_TOKEN}&ip=${PUBLIC_IP}")

if [ "$DUCKDNS_RESPONSE" = "OK" ]; then
    echo "✅ DuckDNS域名更新成功"
    echo "🌐 网站地址: http://${DUCKDNS_SUBDOMAIN}.duckdns.org"
else
    echo "⚠️  DuckDNS更新失败: $DUCKDNS_RESPONSE"
    echo "🌐 备用地址: http://$PUBLIC_IP"
fi

# 等待SSH服务启动
echo "⏳ 等待SSH服务启动..."
sleep 30

# 连接到实例并启动服务
echo "🔧 连接到实例并启动服务..."

# 创建启动脚本
cat > /tmp/start_services.sh << 'EOF'
#!/bin/bash
echo "🚀 启动ITWords应用服务..."

# 启动Spring Boot后端
echo "📋 启动Spring Boot后端..."
cd /home/ec2-user/itwordslearning_api
if [ -f "target/itwordslearning-0.0.1-SNAPSHOT.jar" ]; then
    # 停止现有进程
    pkill -f "itwordslearning-0.0.1-SNAPSHOT.jar" || true
    
    # 启动新进程
    nohup java -jar target/itwordslearning-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
    echo "✅ Spring Boot后端启动中..."
else
    echo "❌ 找不到Spring Boot JAR文件"
    exit 1
fi

# 等待后端启动
echo "⏳ 等待后端启动..."
sleep 15

# 启动前端开发服务器
echo "📋 启动前端开发服务器..."
cd /home/ec2-user/IT-wordslearing_display3.0*
if [ -d "node_modules" ]; then
    # 停止现有进程
    pkill -f "vite" || true
    
    # 启动新进程
    nohup npm run dev > frontend.log 2>&1 &
    echo "✅ 前端开发服务器启动中..."
else
    echo "⚠️  前端依赖未安装，正在安装..."
    npm install
    nohup npm run dev > frontend.log 2>&1 &
    echo "✅ 前端开发服务器启动中..."
fi

# 配置nginx
echo "📋 配置nginx..."
sudo tee /etc/nginx/conf.d/itwords.conf > /dev/null << 'NGINX_EOF'
server {
    listen 80;
    server_name localhost;
    
    # 后端API代理
    location /api/ {
        proxy_pass http://localhost:8080/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # 前端开发服务器代理
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
NGINX_EOF

# 重启nginx
sudo systemctl reload nginx

echo "✅ 服务启动完成！"
echo "🌐 请访问: http://PUBLIC_IP_PLACEHOLDER 或 http://itwords.duckdns.org"
EOF

# 替换占位符
sed -i.bak "s/PUBLIC_IP_PLACEHOLDER/$PUBLIC_IP/g" /tmp/start_services.sh

# 上传并执行启动脚本
echo "📤 上传启动脚本到服务器..."
scp -i "$KEY_PATH" -o StrictHostKeyChecking=no /tmp/start_services.sh ec2-user@$PUBLIC_IP:/tmp/
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no ec2-user@$PUBLIC_IP "chmod +x /tmp/start_services.sh && /tmp/start_services.sh"

# 清理临时文件
rm /tmp/start_services.sh /tmp/start_services.sh.bak

# 检查服务状态
echo "📋 检查服务状态..."
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no ec2-user@$PUBLIC_IP "
echo '后端服务状态:'
ps aux | grep java | grep -v grep || echo '后端服务未运行'
echo '前端服务状态:'
ps aux | grep node | grep -v grep || echo '前端服务未运行'
echo 'Nginx状态:'
sudo systemctl status nginx | head -3
"

echo ""
echo "🎉 ITWords项目启动完成！"
echo "🌐 网站地址: http://${DUCKDNS_SUBDOMAIN}.duckdns.org"
echo "🌐 备用地址: http://$PUBLIC_IP"
echo "📋 管理命令:"
echo "   停止服务: ./aws-deployment/stop-completely-free.sh"
echo "   查看日志: ssh -i $KEY_PATH ec2-user@$PUBLIC_IP"
echo ""
echo "✅ 启动完成！" 