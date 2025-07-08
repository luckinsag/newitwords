# IT Words Learning - AWS部署指南

## 概述

本指南将帮助你将IT Words Learning应用程序部署到AWS免费层服务。该应用使用以下AWS服务：

- **Amazon ECS Fargate** - 容器化应用运行环境
- **Amazon RDS MySQL** - 数据库服务
- **Amazon ECR** - Docker镜像仓库
- **Application Load Balancer** - 负载均衡器
- **CloudWatch** - 监控和日志

## 预准备

### 1. 安装必要工具

```bash
# 安装AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# 安装Docker Desktop
# 访问 https://www.docker.com/products/docker-desktop 下载安装
```

### 2. 配置AWS账户

```bash
# 配置AWS CLI
aws configure

# 输入以下信息：
# AWS Access Key ID: 你的访问密钥
# AWS Secret Access Key: 你的密钥
# Default region name: us-east-1
# Default output format: json
```

### 3. 准备项目文件

```bash
# 复制环境变量模板
cp docker-env.template .env

# 编辑.env文件，设置你的配置
vim .env
```

## 本地Docker部署

### 1. 构建和运行

```bash
# 构建Docker镜像
docker-compose build

# 启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 2. 访问应用

- 前端: http://localhost:80
- 后端API: http://localhost:8080
- 数据库: localhost:3306

### 3. 停止服务

```bash
# 停止所有服务
docker-compose down

# 删除所有数据（包括数据库）
docker-compose down -v
```

## AWS部署

### 1. 设置AWS账户ID

```bash
# 获取你的AWS账户ID
aws sts get-caller-identity --query Account --output text

# 更新部署脚本中的变量
vim aws-deployment/deploy-to-aws.sh
# 修改 AWS_ACCOUNT_ID="你的账户ID"
```

### 2. 执行部署

```bash
# 进入部署目录
cd aws-deployment

# 给脚本执行权限
chmod +x deploy-to-aws.sh

# 执行部署
./deploy-to-aws.sh
```

### 3. 部署步骤说明

部署脚本会自动完成以下步骤：

1. **检查必要工具** - 验证AWS CLI和Docker是否安装
2. **创建ECR仓库** - 存储Docker镜像
3. **构建和推送镜像** - 构建应用镜像并推送到ECR
4. **创建RDS实例** - 部署MySQL数据库（免费层）
5. **创建ECS集群** - 容器运行环境
6. **创建CloudWatch日志组** - 应用日志管理
7. **注册任务定义** - 定义容器运行配置
8. **创建ECS服务** - 运行和管理容器

### 4. 配置负载均衡器（可选）

```bash
# 创建Application Load Balancer
aws elbv2 create-load-balancer \
  --name itwords-alb \
  --subnets subnet-xxx subnet-yyy \
  --security-groups sg-xxx \
  --scheme internet-facing \
  --type application \
  --ip-address-type ipv4

# 创建目标组
aws elbv2 create-target-group \
  --name itwords-targets \
  --protocol HTTP \
  --port 80 \
  --vpc-id vpc-xxx \
  --target-type ip

# 创建监听器
aws elbv2 create-listener \
  --load-balancer-arn arn:aws:elasticloadbalancing:xxx \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:xxx
```

## 免费层资源限制

### AWS免费层包含：

- **ECS Fargate**: 每月20GB-Hours + 4GB-Hours ephemeral storage
- **RDS MySQL**: 每月750小时 db.t3.micro实例
- **ECR**: 每月500MB存储
- **CloudWatch**: 每月10GB日志摄取，5GB日志存储
- **Application Load Balancer**: 每月750小时 + 15LCU

### 成本优化建议：

1. **使用最小实例规格** - db.t3.micro, 0.25 vCPU, 512MB内存
2. **启用自动暂停** - 开发环境可以设置自动暂停
3. **监控使用量** - 定期检查AWS账单
4. **清理未使用资源** - 删除不需要的镜像和日志

## 监控和维护

### 1. 查看应用状态

```bash
# 查看ECS服务状态
aws ecs describe-services \
  --cluster itwords-cluster \
  --services itwords-service

# 查看任务状态
aws ecs list-tasks \
  --cluster itwords-cluster \
  --service-name itwords-service
```

### 2. 查看日志

```bash
# 查看后端日志
aws logs tail /ecs/itwords-learning-app --follow

# 查看前端日志
aws logs tail /ecs/itwords-learning-app --log-stream-name-prefix frontend
```

### 3. 更新应用

```bash
# 重新构建和推送镜像
./deploy-to-aws.sh

# 强制部署新版本
aws ecs update-service \
  --cluster itwords-cluster \
  --service itwords-service \
  --force-new-deployment
```

## 故障排除

### 1. 常见问题

**问题**: 容器无法启动
```bash
# 检查任务定义
aws ecs describe-task-definition --task-definition itwords-learning-app

# 检查容器日志
aws ecs describe-tasks --cluster itwords-cluster --tasks <task-id>
```

**问题**: 数据库连接失败
```bash
# 检查RDS实例状态
aws rds describe-db-instances --db-instance-identifier itwords-db

# 检查安全组设置
aws ec2 describe-security-groups --group-ids sg-xxx
```

**问题**: 前端无法访问后端
```bash
# 检查ECS服务网络配置
aws ecs describe-services --cluster itwords-cluster --services itwords-service

# 检查任务的网络接口
aws ecs describe-tasks --cluster itwords-cluster --tasks <task-id>
```

### 2. 清理资源

```bash
# 删除ECS服务
aws ecs delete-service --cluster itwords-cluster --service itwords-service --force

# 删除ECS集群
aws ecs delete-cluster --cluster itwords-cluster

# 删除RDS实例
aws rds delete-db-instance --db-instance-identifier itwords-db --skip-final-snapshot

# 删除ECR仓库
aws ecr delete-repository --repository-name itwords-backend --force
aws ecr delete-repository --repository-name itwords-frontend --force
```

## 安全建议

1. **使用IAM角色** - 为ECS任务创建专用IAM角色
2. **启用VPC** - 将资源部署在私有子网中
3. **配置安全组** - 限制网络访问
4. **使用Secrets Manager** - 管理敏感信息
5. **启用SSL/TLS** - 使用HTTPS协议

## 扩展功能

### 1. 自动扩缩容

```bash
# 创建Auto Scaling目标
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --resource-id service/itwords-cluster/itwords-service \
  --scalable-dimension ecs:service:DesiredCount \
  --min-capacity 1 \
  --max-capacity 10
```

### 2. 蓝绿部署

```bash
# 创建CodeDeploy应用
aws deploy create-application \
  --application-name itwords-app \
  --compute-platform ECS
```

### 3. 域名配置

```bash
# 使用Route 53配置域名
aws route53 create-hosted-zone --name yourdomain.com --caller-reference $(date +%s)
```

## 支持和帮助

如果遇到问题，可以：

1. 查看AWS文档: https://docs.aws.amazon.com/
2. 查看项目GitHub仓库
3. 联系AWS支持（免费层包含基础支持）

---

**注意**: 请定期检查AWS账单，确保在免费层限制内使用服务。超出限制会产生费用。 