#!/bin/bash

# IT Words Learning 一键部署脚本
# 使用前请确保已经配置好AWS CLI和相关服务

echo "=== IT Words Learning 一键部署脚本 ==="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查参数
if [ $# -lt 3 ]; then
    echo -e "${RED}使用方法: $0 <S3-bucket-name> <EC2-public-ip> <RDS-endpoint>${NC}"
    echo "例如: $0 itwords-frontend-bucket 1.2.3.4 itwords-db.abc123.us-east-1.rds.amazonaws.com"
    exit 1
fi

BUCKET_NAME=$1
EC2_IP=$2
RDS_ENDPOINT=$3
FRONTEND_DIR="IT-wordslearing_display3.0 2"
BACKEND_DIR="itwordslearning_api"

echo -e "${YELLOW}配置信息:${NC}"
echo "S3存储桶: $BUCKET_NAME"
echo "EC2 IP: $EC2_IP"
echo "RDS终端: $RDS_ENDPOINT"
echo ""

# 检查目录是否存在
if [ ! -d "$FRONTEND_DIR" ] || [ ! -d "$BACKEND_DIR" ]; then
    echo -e "${RED}错误: 项目目录不存在${NC}"
    exit 1
fi

# 第一步：部署后端到本地构建
echo -e "${GREEN}1. 准备后端配置...${NC}"
cd $BACKEND_DIR

# 备份原配置文件
if [ -f "src/main/resources/application.properties" ]; then
    cp src/main/resources/application.properties src/main/resources/application.properties.backup
fi

# 创建生产配置
cat > src/main/resources/application-prod.properties << EOF
spring.application.name=itwordslearning
server.port=8080

# RDS MySQL配置
spring.datasource.url=jdbc:mysql://${RDS_ENDPOINT}:3306/mysql_itwordslearning?allowPublicKeyRetrieval=true&useSSL=true&requireSSL=false&serverTimezone=UTC
spring.datasource.username=admin
spring.datasource.password=\${DB_PASSWORD:your-password}
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver

# 连接池配置
spring.datasource.hikari.maximum-pool-size=10
spring.datasource.hikari.minimum-idle=5

# MyBatis配置
mybatis.configuration.map-underscore-to-camel-case=true
mybatis.configuration.use-generated-keys=true
mybatis.mapper-locations=classpath:mapper/*.xml
mybatis.type-aliases-package=com.example.itwordslearning.entity

# 生产环境日志
logging.level.root=INFO
logging.level.com.example.itwordslearning=INFO
logging.file.name=/var/log/itwords/application.log

# Actuator健康检查
management.endpoints.web.exposure.include=health,info
management.endpoint.health.show-details=when-authorized
EOF

echo -e "${GREEN}2. 构建后端应用...${NC}"
mvn clean package -DskipTests -Pprod

if [ ! -f "target/itwordslearning-0.0.1-SNAPSHOT.jar" ]; then
    echo -e "${RED}后端构建失败${NC}"
    exit 1
fi

cd ..

# 第二步：部署前端
echo -e "${GREEN}3. 准备前端配置...${NC}"
cd "$FRONTEND_DIR"

# 备份原配置
if [ -f "src/api/userService.js" ]; then
    cp src/api/userService.js src/api/userService.js.backup
fi
if [ -f "src/api/wordService.js" ]; then
    cp src/api/wordService.js src/api/wordService.js.backup
fi

# 更新API地址
node -e "
const fs = require('fs');

// 更新 userService.js
let userService = fs.readFileSync('src/api/userService.js', 'utf8');
userService = userService.replace(/baseURL:\s*['\"]*http:\/\/localhost:8080['\"]*/, \"baseURL: 'http://${EC2_IP}:8080'\");
fs.writeFileSync('src/api/userService.js', userService);

// 更新 wordService.js
let wordService = fs.readFileSync('src/api/wordService.js', 'utf8');
wordService = wordService.replace(/baseURL:\s*['\"]*\/api['\"]*/, \"baseURL: 'http://${EC2_IP}:8080/api'\");
fs.writeFileSync('src/api/wordService.js', wordService);

console.log('API地址已更新');
"

echo -e "${GREEN}4. 构建前端应用...${NC}"
npm install
npm run build

if [ ! -d "dist" ]; then
    echo -e "${RED}前端构建失败${NC}"
    exit 1
fi

echo -e "${GREEN}5. 上传前端到S3...${NC}"
aws s3 sync dist/ s3://$BUCKET_NAME --delete

# 设置正确的Content-Type
aws s3 cp s3://$BUCKET_NAME s3://$BUCKET_NAME --recursive --metadata-directive REPLACE \
    --content-type "text/html" --exclude "*" --include "*.html"
aws s3 cp s3://$BUCKET_NAME s3://$BUCKET_NAME --recursive --metadata-directive REPLACE \
    --content-type "application/javascript" --exclude "*" --include "*.js"
aws s3 cp s3://$BUCKET_NAME s3://$BUCKET_NAME --recursive --metadata-directive REPLACE \
    --content-type "text/css" --exclude "*" --include "*.css"

cd ..

# 第三步：上传后端到EC2
echo -e "${GREEN}6. 上传后端到EC2...${NC}"
echo "请确保你有EC2的SSH密钥，然后手动执行以下命令："
echo ""
echo -e "${YELLOW}# 上传JAR文件到EC2:${NC}"
echo "scp -i \"your-key.pem\" $BACKEND_DIR/target/itwordslearning-0.0.1-SNAPSHOT.jar ec2-user@$EC2_IP:/home/ec2-user/"
echo ""
echo -e "${YELLOW}# 连接到EC2并部署:${NC}"
echo "ssh -i \"your-key.pem\" ec2-user@$EC2_IP"
echo ""
echo -e "${YELLOW}# 在EC2上执行:${NC}"
echo "sudo systemctl stop itwords"
echo "mv itwordslearning-0.0.1-SNAPSHOT.jar /home/ec2-user/itwords-app/"
echo "sudo systemctl start itwords"
echo "sudo systemctl status itwords"

# 恢复原始配置文件
echo -e "${GREEN}7. 恢复原始配置...${NC}"
if [ -f "$BACKEND_DIR/src/main/resources/application.properties.backup" ]; then
    mv $BACKEND_DIR/src/main/resources/application.properties.backup $BACKEND_DIR/src/main/resources/application.properties
fi

if [ -f "$FRONTEND_DIR/src/api/userService.js.backup" ]; then
    mv $FRONTEND_DIR/src/api/userService.js.backup $FRONTEND_DIR/src/api/userService.js
fi

if [ -f "$FRONTEND_DIR/src/api/wordService.js.backup" ]; then
    mv $FRONTEND_DIR/src/api/wordService.js.backup $FRONTEND_DIR/src/api/wordService.js
fi

echo -e "${GREEN}=== 部署完成 ===${NC}"
echo "前端地址: http://$BUCKET_NAME.s3-website-region.amazonaws.com"
echo "后端地址: http://$EC2_IP:8080"
echo ""
echo -e "${YELLOW}接下来请手动完成EC2部署步骤${NC}" 