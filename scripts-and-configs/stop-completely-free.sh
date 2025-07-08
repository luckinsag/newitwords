#!/bin/bash

# 停止AWS资源脚本
# 用于停止ITWords项目的所有AWS资源以节约成本

echo "🛑 停止ITWords项目AWS资源..."

# 配置变量
INSTANCE_ID="i-0afe53952ee8a6190"
REGION="us-east-1"
RDS_INSTANCE="itwords-db"

# 检查AWS CLI配置
echo "📋 检查AWS配置..."
if ! aws configure list | grep -q access_key; then
    echo "❌ AWS CLI未配置，请先运行 aws configure"
    exit 1
fi

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

# 停止EC2实例
if [ "$INSTANCE_STATE" = "running" ]; then
    echo "🛑 停止EC2实例 $INSTANCE_ID..."
    aws ec2 stop-instances \
        --instance-ids $INSTANCE_ID \
        --region $REGION
    
    if [ $? -eq 0 ]; then
        echo "✅ 停止命令已发送"
        
        # 等待实例完全停止
        echo "⏳ 等待实例停止..."
        aws ec2 wait instance-stopped \
            --instance-ids $INSTANCE_ID \
            --region $REGION
        
        echo "✅ EC2实例已成功停止"
    else
        echo "❌ 停止实例失败"
        exit 1
    fi
elif [ "$INSTANCE_STATE" = "stopped" ]; then
    echo "ℹ️  实例已经是停止状态"
else
    echo "⚠️  实例状态: $INSTANCE_STATE，请手动检查"
fi

# 检查RDS状态（可选）
echo "📋 检查RDS数据库状态..."
RDS_STATUS=$(aws rds describe-db-instances \
    --db-instance-identifier $RDS_INSTANCE \
    --region $REGION \
    --query 'DBInstances[0].DBInstanceStatus' \
    --output text 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "📋 RDS状态: $RDS_STATUS"
    
    # 注意：RDS免费层建议保持运行，因为启动需要时间
    if [ "$RDS_STATUS" = "available" ]; then
        echo "ℹ️  RDS保持运行状态（免费层建议）"
        echo "💡 如需停止RDS以节约成本，请手动执行："
        echo "   aws rds stop-db-instance --db-instance-identifier $RDS_INSTANCE --region $REGION"
    fi
else
    echo "⚠️  无法获取RDS状态，请手动检查"
fi

# 显示成本节约信息
echo ""
echo "💰 成本节约信息:"
echo "✅ EC2实例已停止 - 计算费用已停止"
echo "ℹ️  EBS存储 - 继续按存储容量计费"
echo "ℹ️  RDS实例 - 如运行则继续计费"
echo ""
echo "🔄 重新启动请运行: ./aws-deployment/start-completely-free.sh"
echo "🌐 DuckDNS域名将在实例启动后自动更新"
echo ""
echo "✅ 停止完成！" 