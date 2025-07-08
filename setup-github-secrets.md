# GitHub Secrets 配置指南

## 📋 已检测到的信息

✅ **EC2 实例 IP**: `3.215.153.19`  
✅ **私钥文件**: `project-structure/aws-deployment/itwords-key.pem`  
✅ **连接测试**: 成功 ✅

## 🔐 需要配置的 GitHub Secrets

### 1. 进入 GitHub 仓库设置

1. 打开你的 GitHub 仓库
2. 点击 `Settings` (设置)
3. 在左侧菜单选择 `Secrets and variables` → `Actions`
4. 点击 `New repository secret`

### 2. 添加以下 Secrets

#### A. AWS 访问密钥 (需要你提供)
```
Name: AWS_ACCESS_KEY_ID
Value: [你的 AWS Access Key ID]
```

#### B. AWS 秘密密钥 (需要你提供)
```
Name: AWS_SECRET_ACCESS_KEY  
Value: [你的 AWS Secret Access Key]
```

#### C. AWS 区域
```
Name: AWS_REGION
Value: us-east-1
```
*注：根据你的 EC2 实例所在区域设置，由于 IP 地址 3.215.153.19 显示为美东区域*

#### D. S3 存储桶 (需要创建)
```
Name: S3_BUCKET
Value: [你的 S3 存储桶名称]
```
*示例: `itwords-deployment-bucket-your-unique-id`*

#### E. EC2 实例 IP (已确认)
```
Name: EC2_HOST
Value: 3.215.153.19
```

#### F. EC2 私钥 (已准备)
```
Name: EC2_PRIVATE_KEY
Value: [私钥文件的完整内容]
```

## 🔑 获取 EC2 私钥内容

请执行以下命令来获取私钥内容：

```bash
cat project-structure/aws-deployment/itwords-key.pem
```

复制输出的完整内容（包括 `-----BEGIN RSA PRIVATE KEY-----` 和 `-----END RSA PRIVATE KEY-----`）作为 `EC2_PRIVATE_KEY` 的值。

## 🪣 创建 S3 存储桶

### 方法 1: 使用 AWS Console
1. 登录 AWS Console
2. 进入 S3 服务
3. 点击 "Create bucket"
4. 输入桶名称（如：`itwords-deployment-bucket-20240101`）
5. 选择 `us-east-1` 区域
6. 保持默认设置，创建存储桶

### 方法 2: 使用 AWS CLI
```bash
aws s3 mb s3://itwords-deployment-bucket-your-unique-id --region us-east-1
```

## 🔧 AWS IAM 配置

### 创建 GitHub Actions IAM 用户

1. **登录 AWS Console → IAM**
2. **创建用户**：
   - 用户名：`github-actions-itwords`
   - 访问类型：程序化访问

3. **附加策略**：创建自定义策略
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
                "arn:aws:s3:::your-bucket-name",
                "arn:aws:s3:::your-bucket-name/*"
            ]
        }
    ]
}
```

4. **获取访问密钥**：
   - 记录 `Access Key ID`
   - 记录 `Secret Access Key`

### EC2 IAM 角色配置

1. **创建 IAM 角色**：
   - 角色名：`EC2-S3-Access-Role`
   - 信任实体：EC2

2. **附加策略**：
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
                "arn:aws:s3:::your-bucket-name",
                "arn:aws:s3:::your-bucket-name/*"
            ]
        }
    ]
}
```

3. **附加到 EC2 实例**：
   - 在 EC2 Console 选择你的实例
   - Actions → Security → Modify IAM role
   - 选择创建的角色

## ✅ GitHub Secrets 配置检查表

配置完成后，你的 GitHub Secrets 应该包含：

- [ ] `AWS_ACCESS_KEY_ID` - ✅ AWS 访问密钥
- [ ] `AWS_SECRET_ACCESS_KEY` - ✅ AWS 秘密密钥  
- [ ] `AWS_REGION` - ✅ `us-east-1`
- [ ] `S3_BUCKET` - ✅ S3 存储桶名称
- [ ] `EC2_HOST` - ✅ `3.215.153.19`
- [ ] `EC2_PRIVATE_KEY` - ✅ 私钥文件内容

## 🧪 测试部署

配置完成后，进行测试：

1. **提交代码触发部署**：
```bash
git add .
git commit -m "test: 测试 GitHub Actions 自动部署"
git push origin main
```

2. **监控部署进度**：
   - 打开 GitHub 仓库的 Actions 页面
   - 查看最新的工作流执行情况

3. **验证部署结果**：
   - 前端：http://3.215.153.19
   - 后端 API：http://3.215.153.19:8080
   - 健康检查：http://3.215.153.19:8080/actuator/health

## 🚨 常见问题处理

### 问题 1: SSH 连接失败
```bash
# 检查 EC2 安全组是否开放 22 端口
# 确保私钥格式正确，包含完整的 BEGIN/END 标记
```

### 问题 2: S3 权限错误
```bash
# 检查 IAM 用户权限
# 确保 S3 存储桶名称正确
aws s3 ls s3://your-bucket-name
```

### 问题 3: 部署脚本失败
```bash
# SSH 到 EC2 查看日志
ssh -i project-structure/aws-deployment/itwords-key.pem ec2-user@3.215.153.19
tail -f /opt/itwords/app.log
```

## 🎯 下一步

配置完成后：
1. ✅ 推送代码测试自动部署
2. ✅ 访问应用验证功能
3. ✅ 监控日志和性能
4. ✅ 设置监控告警

---

**📞 需要帮助？**
如遇问题，请检查：
- GitHub Actions 日志
- EC2 实例状态和日志
- AWS IAM 权限配置
- 网络安全组设置

**�� 完成后即可享受自动化部署的便利！** 