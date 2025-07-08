#!/bin/bash

# IT Words Learning 前端部署脚本
# 使用方法: ./deploy-frontend.sh your-s3-bucket-name

if [ -z "$1" ]; then
    echo "使用方法: $0 <S3-bucket-name>"
    echo "例如: $0 itwords-frontend-bucket"
    exit 1
fi

BUCKET_NAME=$1
PROJECT_DIR="IT-wordslearing_display3.0 2"

echo "=== IT Words Learning 前端部署脚本 ==="
echo "目标S3存储桶: $BUCKET_NAME"
echo "项目目录: $PROJECT_DIR"

# 检查项目目录是否存在
if [ ! -d "$PROJECT_DIR" ]; then
    echo "错误: 项目目录 '$PROJECT_DIR' 不存在"
    exit 1
fi

# 进入项目目录
cd "$PROJECT_DIR"

echo "1. 安装依赖..."
npm install

echo "2. 构建生产版本..."
npm run build

echo "3. 上传到S3..."
aws s3 sync dist/ s3://$BUCKET_NAME --delete

echo "4. 设置正确的Content-Type..."
aws s3 cp s3://$BUCKET_NAME s3://$BUCKET_NAME --recursive --metadata-directive REPLACE \
    --content-type "text/html" --exclude "*" --include "*.html"

aws s3 cp s3://$BUCKET_NAME s3://$BUCKET_NAME --recursive --metadata-directive REPLACE \
    --content-type "application/javascript" --exclude "*" --include "*.js"

aws s3 cp s3://$BUCKET_NAME s3://$BUCKET_NAME --recursive --metadata-directive REPLACE \
    --content-type "text/css" --exclude "*" --include "*.css"

echo "5. 清理CloudFront缓存（如果配置了CDN）..."
echo "请手动在AWS控制台清理CloudFront缓存，或使用以下命令："
echo "aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths '/*'"

echo "=== 部署完成 ==="
echo "你的前端应用已部署到: http://$BUCKET_NAME.s3-website-region.amazonaws.com" 