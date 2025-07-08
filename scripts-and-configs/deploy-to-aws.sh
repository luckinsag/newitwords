#!/bin/bash

# IT Words Learning - AWS部署脚本
# 使用AWS免费层服务部署应用

set -e

# 配置变量
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="628532653086"
CLUSTER_NAME="itwords-cluster"
SERVICE_NAME="itwords-service"
TASK_DEFINITION_NAME="itwords-learning-app"
ECR_REPO_BACKEND="itwords-backend"
ECR_REPO_FRONTEND="itwords-frontend"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查必要的工具
check_prerequisites() {
    echo_info "检查必要的工具..."
    
    if ! command -v aws &> /dev/null; then
        echo_error "AWS CLI未安装. 请安装: https://aws.amazon.com/cli/"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        echo_error "Docker未安装. 请安装Docker Desktop"
        exit 1
    fi
    
    # 检查AWS配置
    if ! aws sts get-caller-identity &> /dev/null; then
        echo_error "AWS CLI未配置. 请运行: aws configure"
        exit 1
    fi
    
    echo_info "所有必要工具检查通过"
}

# 创建ECR仓库
create_ecr_repositories() {
    echo_info "创建ECR仓库..."
    
    # 创建后端仓库
    aws ecr describe-repositories --repository-names $ECR_REPO_BACKEND --region $AWS_REGION &> /dev/null || \
    aws ecr create-repository --repository-name $ECR_REPO_BACKEND --region $AWS_REGION
    
    # 创建前端仓库
    aws ecr describe-repositories --repository-names $ECR_REPO_FRONTEND --region $AWS_REGION &> /dev/null || \
    aws ecr create-repository --repository-name $ECR_REPO_FRONTEND --region $AWS_REGION
    
    echo_info "ECR仓库创建完成"
}

# 构建并推送Docker镜像
build_and_push_images() {
    echo_info "构建并推送Docker镜像..."
    
    # 获取ECR登录token
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
    
    # 构建后端镜像
    echo_info "构建后端镜像..."
    cd ../itwordslearning_api
    docker build -t $ECR_REPO_BACKEND:latest .
    docker tag $ECR_REPO_BACKEND:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_BACKEND:latest
    docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_BACKEND:latest
    
    # 构建前端镜像
    echo_info "构建前端镜像..."
    cd "../IT-wordslearing_display3.0 2"
    docker build -t $ECR_REPO_FRONTEND:latest .
    docker tag $ECR_REPO_FRONTEND:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_FRONTEND:latest
    docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_FRONTEND:latest
    
    cd ../aws-deployment
    echo_info "镜像构建和推送完成"
}

# 创建RDS实例
create_rds_instance() {
    echo_info "创建RDS MySQL实例..."
    
    # 检查RDS实例是否存在
    if aws rds describe-db-instances --db-instance-identifier itwords-db --region $AWS_REGION &> /dev/null; then
        echo_info "RDS实例已存在"
        return
    fi
    
    # 获取默认VPC和安全组
    VPC_ID=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true --region $AWS_REGION --query 'Vpcs[0].VpcId' --output text)
    SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters Name=group-name,Values=default Name=vpc-id,Values=$VPC_ID --region $AWS_REGION --query 'SecurityGroups[0].GroupId' --output text)
    
    # 创建RDS实例 (免费层)
    aws rds create-db-instance \
        --db-instance-identifier itwords-db \
        --db-instance-class db.t3.micro \
        --engine mysql \
        --engine-version 8.0.35 \
        --master-username root \
        --master-user-password itwords123! \
        --allocated-storage 20 \
        --storage-type gp2 \
        --vpc-security-group-ids $SECURITY_GROUP_ID \
        --db-name mysql_itwordslearning \
        --backup-retention-period 0 \
        --region $AWS_REGION
    
    echo_info "RDS实例创建中，请等待约10分钟..."
    aws rds wait db-instance-available --db-instance-identifier itwords-db --region $AWS_REGION
    echo_info "RDS实例创建完成"
}

# 创建ECS集群
create_ecs_cluster() {
    echo_info "创建ECS集群..."
    
    # 创建集群
    aws ecs create-cluster --cluster-name $CLUSTER_NAME --region $AWS_REGION --capacity-providers FARGATE --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1 || echo_info "集群已存在"
    
    echo_info "ECS集群创建完成"
}

# 创建CloudWatch日志组
create_log_group() {
    echo_info "创建CloudWatch日志组..."
    
    aws logs create-log-group --log-group-name /ecs/itwords-learning-app --region $AWS_REGION || echo_info "日志组已存在"
    
    echo_info "CloudWatch日志组创建完成"
}

# 注册任务定义
register_task_definition() {
    echo_info "注册ECS任务定义..."
    
    # 更新任务定义文件中的占位符
    sed -i.bak "s/YOUR_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" ecs-task-definition.json
    sed -i.bak "s/YOUR_REGION/$AWS_REGION/g" ecs-task-definition.json
    
    # 获取RDS端点
    RDS_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier itwords-db --region $AWS_REGION --query 'DBInstances[0].Endpoint.Address' --output text)
    sed -i.bak "s/YOUR_RDS_ENDPOINT/$RDS_ENDPOINT/g" ecs-task-definition.json
    
    # 注册任务定义
    aws ecs register-task-definition --cli-input-json file://ecs-task-definition.json --region $AWS_REGION
    
    echo_info "任务定义注册完成"
}

# 创建ECS服务
create_ecs_service() {
    echo_info "创建ECS服务..."
    
    # 获取默认VPC和子网
    VPC_ID=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true --region $AWS_REGION --query 'Vpcs[0].VpcId' --output text)
    SUBNET_IDS=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$VPC_ID --region $AWS_REGION --query 'Subnets[0:2].SubnetId' --output text | tr '\t' ',')
    SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters Name=group-name,Values=default Name=vpc-id,Values=$VPC_ID --region $AWS_REGION --query 'SecurityGroups[0].GroupId' --output text)
    
    # 创建服务
    aws ecs create-service \
        --cluster $CLUSTER_NAME \
        --service-name $SERVICE_NAME \
        --task-definition $TASK_DEFINITION_NAME:1 \
        --desired-count 1 \
        --launch-type FARGATE \
        --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_IDS],securityGroups=[$SECURITY_GROUP_ID],assignPublicIp=ENABLED}" \
        --region $AWS_REGION || echo_info "服务已存在"
    
    echo_info "ECS服务创建完成"
}

# 主函数
main() {
    echo_info "开始部署IT Words Learning到AWS..."
    
    check_prerequisites
    create_ecr_repositories
    build_and_push_images
    create_rds_instance
    create_ecs_cluster
    create_log_group
    register_task_definition
    create_ecs_service
    
    echo_info "部署完成！"
    echo_info "你可以在AWS ECS控制台查看服务状态"
    echo_info "RDS数据库端点: $(aws rds describe-db-instances --db-instance-identifier itwords-db --region $AWS_REGION --query 'DBInstances[0].Endpoint.Address' --output text)"
}

# 运行主函数
main "$@" 