#!/bin/bash

# IT Words Learning 后端部署脚本
# 在EC2服务器上运行此脚本

echo "=== IT Words Learning 后端部署脚本 ==="

# 变量配置
APP_DIR="/home/ec2-user/itwords-app"
JAR_NAME="itwordslearning-0.0.1-SNAPSHOT.jar"
SERVICE_NAME="itwords"

echo "1. 停止现有服务..."
sudo systemctl stop $SERVICE_NAME || echo "服务未运行"

echo "2. 进入应用目录..."
cd $APP_DIR/itwordslearning_api

echo "3. 更新代码（如果使用git）..."
if [ -d ".git" ]; then
    git pull origin main || git pull origin master
else
    echo "非git仓库，跳过代码更新"
fi

echo "4. 构建项目..."
mvn clean package -DskipTests

echo "5. 检查JAR文件..."
if [ -f "target/$JAR_NAME" ]; then
    echo "JAR文件构建成功"
else
    echo "错误: JAR文件构建失败"
    exit 1
fi

echo "6. 创建systemd服务文件..."
sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null <<EOF
[Unit]
Description=IT Words Learning Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=$APP_DIR/itwordslearning_api
ExecStart=/usr/bin/java -jar target/$JAR_NAME
Restart=always
RestartSec=10
Environment=JAVA_OPTS="-Xmx512m -Xms256m"

[Install]
WantedBy=multi-user.target
EOF

echo "7. 重新加载systemd并启动服务..."
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

echo "8. 检查服务状态..."
sleep 5
sudo systemctl status $SERVICE_NAME

echo "9. 检查应用健康状态..."
sleep 10
if curl -f http://localhost:8080/actuator/health 2>/dev/null; then
    echo "应用健康检查通过"
else
    echo "应用健康检查失败，请检查日志"
    echo "查看日志命令: sudo journalctl -u $SERVICE_NAME -f"
fi

echo "=== 部署完成 ==="
echo "后端服务已启动，端口: 8080"
echo "查看日志: sudo journalctl -u $SERVICE_NAME -f"
echo "重启服务: sudo systemctl restart $SERVICE_NAME" 