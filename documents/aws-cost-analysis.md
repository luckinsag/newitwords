# IT Words Learning - AWS成本分析

## 📊 免费层资源配额（12个月）

### 计算服务
- **ECS Fargate**: 20GB-小时/月 + 4GB-小时临时存储
- **Lambda**: 100万次请求/月 + 400,000GB-秒计算时间

### 存储服务
- **S3**: 5GB标准存储
- **EBS**: 30GB通用型SSD存储

### 数据库服务
- **RDS**: 750小时db.t3.micro实例/月
- **RDS存储**: 20GB通用型SSD存储

### 网络服务
- **数据传输**: 1GB出站传输/月
- **CloudFront**: 50GB数据传输出站

## 💰 项目实际成本预估

### 🟢 **免费层内使用（月成本：$0）**

#### 基础配置：
```
ECS Fargate任务：
- CPU: 0.25 vCPU
- 内存: 512MB
- 运行时间: 24小时/天 × 30天 = 720小时
- 计算成本: 720小时 × 0.25 vCPU × 0.5GB = 90GB-小时
- 状态: ✅ 在20GB-小时免费配额内

RDS MySQL数据库：
- 实例类型: db.t3.micro
- 运行时间: 720小时/月
- 状态: ✅ 在750小时免费配额内

公共IP地址：
- ECS任务动态IP: 免费
- 数据传输: 前1GB免费
- 状态: ✅ 正常使用在免费配额内
```

### 🟡 **可能产生的小额费用**

#### 1. 数据传输费用
```
出站数据传输超过1GB：
- 成本: $0.09/GB
- 预估: 如果每月传输5GB，约 $0.36/月
```

#### 2. 存储费用
```
RDS存储超过20GB：
- 成本: $0.115/GB/月
- 预估: 如果使用30GB，约 $1.15/月
```

#### 3. ECR镜像存储
```
容器镜像存储超过500MB：
- 成本: $0.10/GB/月
- 预估: 如果存储2GB镜像，约 $0.15/月
```

### 🔴 **需要避免的高费用项**

#### 1. 负载均衡器（如果添加）
```
Application Load Balancer：
- 基础费用: $16.2/月
- LCU费用: 变动
- 建议: 免费层期间避免使用
```

#### 2. 弹性IP未关联
```
未使用的弹性IP：
- 费用: $3.6/月
- 解决: 及时删除未使用的弹性IP
```

#### 3. 大实例类型
```
超出免费层的实例：
- db.t3.small: $12.41/月
- ECS任务1GB内存: 约$6/月
- 建议: 坚持使用免费层规格
```

## 🛡️ 成本控制策略

### 1. 设置账单警报
```bash
# 创建账单警报（$5阈值）
aws budgets create-budget \
  --account-id YOUR_ACCOUNT_ID \
  --budget '{
    "BudgetName": "IT-Words-Learning-Budget",
    "BudgetLimit": {
      "Amount": "5",
      "Unit": "USD"
    },
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST"
  }'
```

### 2. 定期检查资源
```bash
# 查看ECS服务状态
aws ecs describe-services --cluster itwords-cluster --services itwords-service

# 查看RDS实例状态
aws rds describe-db-instances --db-instance-identifier itwords-db

# 查看ECR仓库大小
aws ecr describe-repositories
```

### 3. 自动关闭策略
```bash
# 设置夜间关闭ECS服务（可选）
aws ecs update-service \
  --cluster itwords-cluster \
  --service itwords-service \
  --desired-count 0
```

## 📈 成本监控工具

### 1. AWS Cost Explorer
- 访问：AWS控制台 → 账单 → Cost Explorer
- 功能：查看详细成本分析
- 免费：基础版本免费

### 2. AWS Budgets
- 功能：设置预算和警报
- 免费：前2个预算免费

### 3. AWS Trusted Advisor
- 功能：成本优化建议
- 免费：基础版本免费

## 🎯 推荐配置（月成本 < $2）

### 生产环境最小化配置：
```yaml
ECS Fargate任务:
  cpu: 256 (0.25 vCPU)
  memory: 512 (0.5 GB)
  
RDS实例:
  class: db.t3.micro
  storage: 20GB
  
网络:
  使用动态公共IP
  避免负载均衡器
  
存储:
  ECR镜像 < 500MB
  S3使用 < 5GB
```

### 开发环境配置：
```yaml
# 开发时可以关闭服务
ECS任务: 按需启动
RDS实例: 夜间关闭（需要手动管理）
```

## 📋 成本检查清单

### 每周检查：
- [ ] ECS服务运行状态
- [ ] RDS实例运行时间
- [ ] ECR镜像数量和大小
- [ ] 数据传输量

### 每月检查：
- [ ] AWS账单详情
- [ ] 免费层使用情况
- [ ] 未使用资源清理
- [ ] 成本预算调整

## 💡 省钱技巧

### 1. 合理使用免费层
- 坚持使用免费层实例规格
- 监控使用量，避免超出配额
- 及时删除不需要的资源

### 2. 优化镜像大小
- 使用多阶段构建
- 删除不必要的依赖
- 使用Alpine Linux基础镜像

### 3. 数据传输优化
- 使用CloudFront CDN（有免费配额）
- 压缩传输数据
- 合理设置缓存策略

## 🚨 费用警告

### 超出免费层的情况：
1. **连续运行大实例**
2. **大量数据传输**
3. **长期存储大量数据**
4. **使用高级服务功能**

### 紧急止损措施：
```bash
# 立即停止所有服务
aws ecs update-service --cluster itwords-cluster --service itwords-service --desired-count 0
aws rds stop-db-instance --db-instance-identifier itwords-db
```

**总结**: 按照我们的配置，正常使用情况下，月成本应该在$0-2之间，主要是数据传输和少量存储费用。 