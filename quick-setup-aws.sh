#!/bin/bash

# IT Words Learning - AWS 快速配置脚本
# 此脚本将帮助你设置 GitHub Actions 部署所需的 AWS 资源

set -e

echo "🚀 IT Words Learning - AWS 快速配置脚本"
echo "========================================="

# 检查 AWS CLI 是否安装
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI 未安装，请先安装 AWS CLI"
    echo "💡 安装方法: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

# 检查 AWS 凭证
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS 凭证未配置，请先配置 AWS CLI"
    echo "💡 运行: aws configure"
    exit 1
fi

echo "✅ AWS CLI 已配置"

# 获取当前 AWS 账户信息
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region || echo "us-east-1")

echo "📋 当前 AWS 配置："
echo "   账户 ID: $ACCOUNT_ID"
echo "   区域: $REGION"
echo ""

# 1. 创建 S3 存储桶
BUCKET_NAME="itwords-deployment-$(date +%Y%m%d)-$(openssl rand -hex 4)"
echo "🪣 创建 S3 存储桶: $BUCKET_NAME"

if aws s3 mb s3://$BUCKET_NAME --region $REGION; then
    echo "✅ S3 存储桶创建成功"
else
    echo "❌ S3 存储桶创建失败"
    exit 1
fi

# 2. 创建 IAM 策略文件
echo "🔐 创建 IAM 策略..."

cat > github-actions-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::$BUCKET_NAME",
                "arn:aws:s3:::$BUCKET_NAME/*"
            ]
        }
    ]
}
EOF

# 3. 创建 EC2 S3 访问策略
cat > ec2-s3-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::$BUCKET_NAME",
                "arn:aws:s3:::$BUCKET_NAME/*"
            ]
        }
    ]
}
EOF

# 4. 创建 IAM 策略
echo "📝 创建 IAM 策略..."

POLICY_ARN=$(aws iam create-policy \
    --policy-name GitHubActions-ITWords-S3Access \
    --policy-document file://github-actions-policy.json \
    --query 'Policy.Arn' --output text 2>/dev/null || echo "")

if [ -n "$POLICY_ARN" ]; then
    echo "✅ GitHub Actions IAM 策略创建成功: $POLICY_ARN"
else
    echo "ℹ️  IAM 策略可能已存在，继续..."
    POLICY_ARN="arn:aws:iam::$ACCOUNT_ID:policy/GitHubActions-ITWords-S3Access"
fi

# 5. 创建 EC2 IAM 角色
echo "👤 创建 EC2 IAM 角色..."

cat > ec2-trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

# 创建角色
aws iam create-role \
    --role-name EC2-ITWords-S3Access \
    --assume-role-policy-document file://ec2-trust-policy.json \
    --description "EC2 role for IT Words Learning app to access S3" 2>/dev/null || echo "ℹ️  角色可能已存在"

# 创建并附加 EC2 策略
aws iam create-policy \
    --policy-name EC2-ITWords-S3Access \
    --policy-document file://ec2-s3-policy.json 2>/dev/null || echo "ℹ️  EC2 策略可能已存在"

aws iam attach-role-policy \
    --role-name EC2-ITWords-S3Access \
    --policy-arn "arn:aws:iam::$ACCOUNT_ID:policy/EC2-ITWords-S3Access" 2>/dev/null || echo "ℹ️  策略可能已附加"

# 创建实例配置文件
aws iam create-instance-profile \
    --instance-profile-name EC2-ITWords-S3Access 2>/dev/null || echo "ℹ️  实例配置文件可能已存在"

aws iam add-role-to-instance-profile \
    --instance-profile-name EC2-ITWords-S3Access \
    --role-name EC2-ITWords-S3Access 2>/dev/null || echo "ℹ️  角色可能已添加到实例配置文件"

echo "✅ EC2 IAM 角色配置完成"

# 6. 创建 GitHub Actions IAM 用户
echo "👤 创建 GitHub Actions IAM 用户..."

USERNAME="github-actions-itwords"
aws iam create-user --user-name $USERNAME 2>/dev/null || echo "ℹ️  用户可能已存在"

# 附加策略到用户
aws iam attach-user-policy \
    --user-name $USERNAME \
    --policy-arn $POLICY_ARN 2>/dev/null || echo "ℹ️  策略可能已附加"

# 创建访问密钥
echo "🔑 创建访问密钥..."
ACCESS_KEY_OUTPUT=$(aws iam create-access-key --user-name $USERNAME 2>/dev/null || echo "")

if [ -n "$ACCESS_KEY_OUTPUT" ]; then
    ACCESS_KEY_ID=$(echo $ACCESS_KEY_OUTPUT | jq -r '.AccessKey.AccessKeyId')
    SECRET_ACCESS_KEY=$(echo $ACCESS_KEY_OUTPUT | jq -r '.AccessKey.SecretAccessKey')
else
    echo "ℹ️  访问密钥可能已存在，请在 AWS Console 中查看或重新创建"
    ACCESS_KEY_ID="请在 AWS Console 中查看"
    SECRET_ACCESS_KEY="请在 AWS Console 中查看"
fi

# 清理临时文件
rm -f github-actions-policy.json ec2-s3-policy.json ec2-trust-policy.json

echo ""
echo "🎉 AWS 资源配置完成！"
echo "=========================="
echo ""
echo "📋 GitHub Secrets 配置信息："
echo "----------------------------"
echo "AWS_ACCESS_KEY_ID: $ACCESS_KEY_ID"
echo "AWS_SECRET_ACCESS_KEY: $SECRET_ACCESS_KEY"
echo "AWS_REGION: $REGION"
echo "S3_BUCKET: $BUCKET_NAME"
echo "EC2_HOST: 3.215.153.19"
echo ""
echo "🔑 EC2_PRIVATE_KEY 内容："
echo "------------------------"
cat project-structure/aws-deployment/itwords-key.pem
echo ""
echo "🎯 下一步操作："
echo "1. 复制上述信息到 GitHub Secrets"
echo "2. 在 EC2 Console 中将角色 'EC2-ITWords-S3Access' 附加到你的 EC2 实例"
echo "3. 推送代码到 main 分支测试自动部署"
echo ""
echo "🔗 GitHub Secrets 设置地址："
echo "   https://github.com/YOUR_USERNAME/YOUR_REPO/settings/secrets/actions"
echo ""
echo "✅ 配置完成！" 