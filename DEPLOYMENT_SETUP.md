# GitHub Actions 自动部署到 AWS EC2 设置指南

## 📋 概述

本指南将帮助你配置 GitHub Actions 自动部署流程，实现代码推送到 main 分支时自动部署到 AWS EC2。

## 🏗️ 部署架构

```
GitHub Repository → GitHub Actions → S3 (存储) → EC2 (部署)
```

### 部署流程
1. **构建阶段**: 编译前端和后端代码
2. **打包阶段**: 创建部署包并上传到 S3
3. **部署阶段**: SSH 到 EC2 并执行部署脚本
4. **健康检查**: 验证应用是否正常运行
5. **清理阶段**: 清理旧的部署文件

## 🔧 AWS 资源准备

### 1. 创建 EC2 实例

```bash
# 推荐配置
实例类型: t3.small 或更高
操作系统: Amazon Linux 2
安全组配置:
  - SSH (22): 仅限你的 IP
  - HTTP (80): 0.0.0.0/0
  - Custom (8080): 0.0.0.0/0  # 后端 API
存储: 至少 20GB
```

### 2. 创建 S3 存储桶

```bash
# 用于存储部署包
aws s3 mb s3://your-itwords-deployments-bucket
```

### 3. 创建 IAM 用户和角色

#### GitHub Actions IAM 用户
```json
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
        "arn:aws:s3:::your-itwords-deployments-bucket",
        "arn:aws:s3:::your-itwords-deployments-bucket/*"
      ]
    }
  ]
}
```

#### EC2 IAM 角色 (用于访问 S3)
```json
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
        "arn:aws:s3:::your-itwords-deployments-bucket",
        "arn:aws:s3:::your-itwords-deployments-bucket/*"
      ]
    }
  ]
}
```

### 4. 配置 EC2 实例

```bash
# SSH 到 EC2 实例
ssh -i your-key.pem ec2-user@your-ec2-ip

# 安装 AWS CLI
sudo yum install -y awscli

# 配置 AWS CLI (使用 IAM 角色或 credentials)
aws configure
```

## 🔐 GitHub Secrets 配置

在 GitHub 仓库设置中添加以下 Secrets：

### 必需的 Secrets

| Secret 名称 | 描述 | 示例值 |
|------------|------|--------|
| `AWS_ACCESS_KEY_ID` | GitHub Actions IAM 用户的访问密钥 | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | GitHub Actions IAM 用户的秘密访问密钥 | `...` |
| `AWS_REGION` | AWS 区域 | `us-east-1` |
| `S3_BUCKET` | S3 存储桶名称 | `your-itwords-deployments-bucket` |
| `EC2_HOST` | EC2 实例的公网 IP 或域名 | `3.15.123.456` |
| `EC2_PRIVATE_KEY` | EC2 实例的私钥文件内容 | `-----BEGIN RSA PRIVATE KEY-----...` |

### 配置步骤

1. **进入 GitHub 仓库设置**
   ```
   Settings → Secrets and variables → Actions → New repository secret
   ```

2. **添加每个 Secret**
   - 点击 "New repository secret"
   - 输入 Secret 名称和值
   - 点击 "Add secret"

3. **验证 EC2 私钥格式**
   ```bash
   # 确保私钥格式正确
   cat your-key.pem
   # 应该看到:
   # -----BEGIN RSA PRIVATE KEY-----
   # (密钥内容)
   # -----END RSA PRIVATE KEY-----
   ```

## 🚀 部署脚本说明

### 自动化步骤

1. **环境准备**
   - 安装 Node.js 18 和 Java 17
   - 缓存依赖项以加速构建

2. **应用构建**
   ```bash
   # 前端构建
   cd project-structure/frontend-app
   npm ci && npm run build
   
   # 后端构建
   cd project-structure/backend-api
   ./mvnw clean package -DskipTests
   ```

3. **部署包创建**
   - 包含前端构建文件
   - 包含后端 JAR 文件
   - 包含数据库脚本和配置文件
   - 生成自动部署脚本

4. **AWS 部署**
   - 上传到 S3 存储桶
   - SSH 到 EC2 实例
   - 下载并执行部署脚本

5. **健康检查**
   - 检查后端 API 健康状态
   - 检查前端可访问性

## 🔧 本地测试

### 测试构建流程

```bash
# 测试前端构建
cd project-structure/frontend-app
npm install
npm run build

# 测试后端构建
cd project-structure/backend-api
./mvnw clean package -DskipTests
```

### 测试部署脚本

```bash
# 在 EC2 实例上手动测试
scp -i your-key.pem deployment.tar.gz ec2-user@your-ec2-ip:/tmp/
ssh -i your-key.pem ec2-user@your-ec2-ip

# 在 EC2 上执行
cd /tmp
tar -xzf deployment.tar.gz
chmod +x deploy.sh
./deploy.sh
```

## 🐛 故障排除

### 常见问题

1. **权限错误**
   ```bash
   # 检查 IAM 权限
   aws sts get-caller-identity
   aws s3 ls s3://your-bucket
   ```

2. **SSH 连接失败**
   ```bash
   # 检查安全组配置
   # 确保 22 端口开放给 GitHub Actions IP
   # 验证私钥格式
   ```

3. **构建失败**
   ```bash
   # 检查 package.json 和 pom.xml
   # 确保构建脚本存在
   # 检查依赖项版本
   ```

4. **部署失败**
   ```bash
   # 在 EC2 上查看日志
   tail -f /opt/itwords/app.log
   sudo journalctl -u nginx
   ```

### 调试技巧

1. **启用 GitHub Actions 调试**
   ```bash
   # 在 repository secrets 中添加:
   ACTIONS_STEP_DEBUG = true
   ACTIONS_RUNNER_DEBUG = true
   ```

2. **手动 SSH 测试**
   ```bash
   # 测试 SSH 连接
   ssh -i your-key.pem -o StrictHostKeyChecking=no ec2-user@your-ec2-ip "echo 'Connection successful'"
   ```

3. **检查服务状态**
   ```bash
   # 在 EC2 上检查服务
   sudo systemctl status nginx
   ps aux | grep java
   netstat -tulpn | grep :8080
   ```

## 📊 监控和维护

### 部署监控

1. **GitHub Actions 监控**
   - 查看 Actions 页面的部署历史
   - 设置失败通知

2. **应用监控**
   - 配置 CloudWatch 监控
   - 设置健康检查告警

3. **日志管理**
   ```bash
   # 应用日志
   tail -f /opt/itwords/app.log
   
   # Nginx 日志
   sudo tail -f /var/log/nginx/access.log
   sudo tail -f /var/log/nginx/error.log
   ```

### 维护任务

1. **定期备份**
   - 数据库备份
   - 配置文件备份

2. **更新管理**
   - 系统更新
   - 依赖项更新

3. **性能优化**
   - 监控资源使用
   - 优化配置参数

## 🔄 回滚策略

### 自动回滚

如果健康检查失败，可以手动触发回滚：

```bash
# 在 EC2 上回滚到上一个版本
cd /opt/itwords
# 保留上一个版本的备份，快速切换
```

### 手动回滚

```bash
# 停止当前服务
sudo pkill -f backend.jar
sudo systemctl stop nginx

# 恢复上一个版本
# (需要预先准备回滚脚本)
```

---

## 🎯 快速开始

1. ✅ 创建并配置 AWS 资源
2. ✅ 设置 GitHub Secrets
3. ✅ 推送代码到 main 分支
4. ✅ 查看 GitHub Actions 执行情况
5. ✅ 访问部署的应用

**部署完成后访问：**
- 前端: `http://your-ec2-ip`
- 后端 API: `http://your-ec2-ip:8080`

## 📞 支持

如遇问题，请检查：
1. GitHub Actions 日志
2. EC2 实例日志
3. AWS CloudWatch 日志
4. 网络和安全组配置 