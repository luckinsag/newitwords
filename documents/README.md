# IT Words Learning AWS 部署脚本使用指南

## 文件说明

- `AWS_部署指南.md` - 详细的部署指南文档
- `deploy-frontend.sh` - 前端部署脚本
- `deploy-backend.sh` - 后端部署脚本
- `quick-deploy.sh` - 一键部署脚本
- `production.properties` - 生产环境配置模板
- `nginx.conf` - Nginx反向代理配置（可选）
- `database-setup.sql` - 数据库初始化脚本
- `frontend-env-config.js` - 前端环境配置脚本

## 快速开始

### 1. 准备工作

1. 注册AWS账户并激活免费层
2. 安装AWS CLI并配置访问密钥
3. 确保本地有Node.js和Maven环境

### 2. 设置AWS服务

```bash
# 1. 创建RDS MySQL实例
# 2. 创建EC2实例
# 3. 创建S3存储桶
# 4. 配置安全组
```

### 3. 初始化数据库

```bash
# 连接到RDS实例
mysql -h your-rds-endpoint.region.rds.amazonaws.com -u admin -p

# 执行初始化脚本
source database-setup.sql
```

### 4. 使用一键部署脚本

```bash
chmod +x quick-deploy.sh
./quick-deploy.sh your-s3-bucket-name your-ec2-ip your-rds-endpoint
```

### 5. 手动部署（推荐）

#### 前端部署
```bash
chmod +x deploy-frontend.sh
./deploy-frontend.sh your-s3-bucket-name
```

#### 后端部署
```bash
# 先上传脚本到EC2
scp -i "your-key.pem" deploy-backend.sh ec2-user@your-ec2-ip:/home/ec2-user/

# 在EC2上执行
ssh -i "your-key.pem" ec2-user@your-ec2-ip
chmod +x deploy-backend.sh
./deploy-backend.sh
```

## 重要配置项

### 环境变量
- `DB_PASSWORD` - RDS数据库密码
- `AWS_ACCESS_KEY_ID` - AWS访问密钥
- `AWS_SECRET_ACCESS_KEY` - AWS秘密密钥

### 需要修改的地址
- `your-rds-endpoint` - RDS数据库终端地址
- `your-ec2-ip` - EC2公网IP地址
- `your-s3-bucket-name` - S3存储桶名称

## 常用命令

### 前端相关
```bash
# 更新API地址
node frontend-env-config.js

# 构建前端
cd "IT-wordslearing_display3.0 2"
npm run build

# 上传到S3
aws s3 sync dist/ s3://your-bucket-name --delete
```

### 后端相关
```bash
# 构建JAR包
cd itwordslearning_api
mvn clean package -DskipTests

# 查看服务状态
sudo systemctl status itwords

# 查看日志
sudo journalctl -u itwords -f
```

### 数据库相关
```bash
# 连接RDS
mysql -h your-rds-endpoint -u admin -p mysql_itwordslearning

# 备份数据库
mysqldump -h your-rds-endpoint -u admin -p mysql_itwordslearning > backup.sql
```

## 故障排除

### 1. 数据库连接失败
- 检查RDS安全组是否允许EC2访问
- 确认数据库连接字符串正确
- 检查数据库用户名和密码

### 2. 前端无法访问后端
- 检查EC2安全组是否开放8080端口
- 确认API地址配置正确
- 检查CORS配置

### 3. 服务无法启动
- 检查Java版本（需要Java 17）
- 查看服务日志：`sudo journalctl -u itwords -f`
- 检查端口是否被占用：`sudo netstat -tlnp | grep 8080`

## 监控和维护

### 健康检查
```bash
# 检查后端健康状态
curl http://your-ec2-ip:8080/actuator/health

# 检查前端访问
curl http://your-s3-bucket.s3-website-region.amazonaws.com
```

### 日志查看
```bash
# 查看应用日志
sudo journalctl -u itwords -f

# 查看系统日志
sudo tail -f /var/log/messages
```

### 性能监控
- 使用AWS CloudWatch监控资源使用情况
- 定期检查数据库性能
- 监控S3存储和流量使用

## 安全建议

1. **定期更新系统和依赖**
2. **使用强密码和密钥**
3. **限制安全组访问范围**
4. **定期备份数据**
5. **启用AWS CloudTrail日志**

## 成本控制

### 免费层限额
- EC2: 750小时/月
- RDS: 750小时/月, 20GB存储
- S3: 5GB存储, 20,000 GET请求

### 监控建议
- 设置账单警报
- 定期检查AWS Cost Explorer
- 使用AWS Budgets设置预算

## 联系支持

如果遇到问题，请：
1. 检查AWS官方文档
2. 查看CloudWatch日志
3. 参考故障排除部分
4. 联系AWS技术支持（付费用户） 