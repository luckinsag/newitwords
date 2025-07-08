#!/bin/bash

# 重启ITWords应用服务脚本
# 用于在不停止EC2实例的情况下重启前端和后端服务

echo "🔄 重启ITWords应用服务..."

# 配置变量
INSTANCE_ID="i-0afe53952ee8a6190"
REGION="us-east-1"
KEY_PATH="./aws-deployment/itwords-key.pem"

# 检查密钥文件
if [ ! -f "$KEY_PATH" ]; then
    echo "❌ 找不到密钥文件: $KEY_PATH"
    exit 1
fi

# 设置密钥文件权限
chmod 600 "$KEY_PATH"

# 获取实例公网IP
echo "📋 获取实例公网IP..."
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --region $REGION \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text 2>/dev/null)

if [ "$PUBLIC_IP" = "None" ] || [ -z "$PUBLIC_IP" ]; then
    echo "❌ 无法获取公网IP，请确保实例正在运行"
    exit 1
fi

echo "📋 实例公网IP: $PUBLIC_IP"

# 创建重启脚本
cat > /tmp/restart_services.sh << 'EOF'
#!/bin/bash
echo "🔄 重启ITWords应用服务..."

# 停止现有服务
echo "🛑 停止现有服务..."
pkill -f "itwordslearning-0.0.1-SNAPSHOT.jar" || true
pkill -f "vite" || true
sleep 5

# 启动Spring Boot后端
echo "🚀 启动Spring Boot后端..."
cd /home/ec2-user/itwordslearning_api
if [ -f "target/itwordslearning-0.0.1-SNAPSHOT.jar" ]; then
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
echo "🚀 启动前端开发服务器..."
cd /home/ec2-user/IT-wordslearing_display3.0*
nohup npm run dev > frontend.log 2>&1 &
echo "✅ 前端开发服务器启动中..."

# 等待服务启动
echo "⏳ 等待服务启动完成..."
sleep 10

# 检查服务状态
echo "📋 检查服务状态..."
echo "后端服务状态:"
ps aux | grep java | grep itwordslearning | grep -v grep || echo "❌ 后端服务未运行"
echo "前端服务状态:"
ps aux | grep node | grep vite | grep -v grep || echo "❌ 前端服务未运行"

# 测试API
echo "🧪 测试API连接..."
sleep 5
curl -s http://localhost:8080/api/words/all -X POST -H 'Content-Type: application/json' | head -3 | grep -q "code" && echo "✅ 后端API正常" || echo "⚠️  后端API未响应"

echo "✅ 服务重启完成！"
EOF

# 上传并执行重启脚本
echo "📤 上传重启脚本到服务器..."
scp -i "$KEY_PATH" -o StrictHostKeyChecking=no /tmp/restart_services.sh ec2-user@$PUBLIC_IP:/tmp/
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no ec2-user@$PUBLIC_IP "chmod +x /tmp/restart_services.sh && /tmp/restart_services.sh"

# 清理临时文件
rm /tmp/restart_services.sh

echo ""
echo "🎉 ITWords服务重启完成！"
echo "🌐 网站地址: http://itwords.duckdns.org"
echo "🌐 备用地址: http://$PUBLIC_IP"
echo ""
echo "✅ 重启完成！" 