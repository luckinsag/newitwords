# AWS部署配置指南

## 1. 配置AWS CLI

安装AWS CLI后，运行以下命令进行配置：

```bash
aws configure
```

系统会提示你输入：
- **AWS Access Key ID**: 你的访问密钥ID
- **AWS Secret Access Key**: 你的密钥
- **Default region name**: 建议使用 `us-east-1`
- **Default output format**: 输入 `json`

## 2. 验证配置

```bash
# 验证身份
aws sts get-caller-identity

# 应该返回类似：
{
    "UserId": "AIDACKCEVSQ6C2EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-username"
}
```

## 3. 获取账户ID

```bash
# 获取AWS账户ID
aws sts get-caller-identity --query Account --output text
```

记录这个账户ID，部署时需要用到。

## 4. 配置IAM权限

为了部署应用，你的IAM用户需要以下权限：

### 必需权限策略：
- `AmazonECS_FullAccess`
- `AmazonEC2ContainerRegistryFullAccess`
- `AmazonRDSFullAccess`
- `CloudWatchLogsFullAccess`
- `IAMFullAccess`
- `AmazonVPCFullAccess`

### 添加权限步骤：
1. 登录AWS控制台
2. 转到IAM服务
3. 选择"用户"
4. 选择你的用户
5. 点击"添加权限"
6. 选择"直接附加现有策略"
7. 搜索并选择上述策略

## 5. 部署准备

### 5.1 更新部署脚本

编辑 `aws-deployment/deploy-to-aws.sh`：

```bash
# 修改这些变量
AWS_ACCOUNT_ID="你的账户ID"
AWS_REGION="us-east-1"  # 或你选择的区域
```

### 5.2 检查Docker运行状态

```bash
# 确保Docker正在运行
docker info

# 如果需要，启动Docker Desktop
```

## 6. 执行部署

```bash
# 进入部署目录
cd aws-deployment

# 给脚本执行权限
chmod +x deploy-to-aws.sh

# 执行部署（大约需要20-30分钟）
./deploy-to-aws.sh
```

## 7. 部署流程说明

部署脚本会自动完成：

1. **检查环境** (1分钟)
   - 验证AWS CLI配置
   - 检查Docker状态

2. **创建ECR仓库** (2分钟)
   - 后端镜像仓库
   - 前端镜像仓库

3. **构建并推送镜像** (10-15分钟)
   - 构建后端Spring Boot镜像
   - 构建前端Vue.js镜像
   - 推送到ECR

4. **创建RDS数据库** (10-15分钟)
   - MySQL 8.0实例
   - 免费层配置(db.t3.micro)

5. **创建ECS服务** (5分钟)
   - 集群配置
   - 任务定义
   - 服务启动

## 8. 监控部署

### 查看进度：
```bash
# 查看ECS服务状态
aws ecs describe-services --cluster itwords-cluster --services itwords-service

# 查看任务状态
aws ecs list-tasks --cluster itwords-cluster --service-name itwords-service
```

### 查看日志：
```bash
# 查看应用日志
aws logs tail /ecs/itwords-learning-app --follow
```

## 9. 访问应用

部署完成后，获取公网IP：

```bash
# 获取任务的公网IP
aws ecs describe-tasks --cluster itwords-cluster --tasks $(aws ecs list-tasks --cluster itwords-cluster --service-name itwords-service --query 'taskArns[0]' --output text) --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text | xargs -I {} aws ec2 describe-network-interfaces --network-interface-ids {} --query 'NetworkInterfaces[0].Association.PublicIp' --output text
```

应用将在 `http://公网IP:80` 可用。

## 10. 成本控制

### 免费层监控：
- 定期检查AWS账单
- 设置账单警报
- 监控资源使用情况

### 停止服务：
```bash
# 停止ECS服务（防止产生费用）
aws ecs update-service --cluster itwords-cluster --service itwords-service --desired-count 0

# 删除RDS实例（如果不再需要）
aws rds delete-db-instance --db-instance-identifier itwords-db --skip-final-snapshot
```

## 11. 故障排除

### 常见问题：

1. **权限不足**
   - 检查IAM权限
   - 确保用户有足够的权限

2. **区域问题**
   - 确保所有服务在同一区域
   - 检查默认区域配置

3. **网络连接**
   - 检查安全组设置
   - 确保VPC配置正确

4. **镜像构建失败**
   - 检查Docker状态
   - 确保有足够的磁盘空间

### 获取帮助：
- AWS文档：https://docs.aws.amazon.com/
- AWS论坛：https://forums.aws.amazon.com/
- 本项目GitHub Issues 