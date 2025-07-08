# GitHub 仓库设置指南

## 🎯 目标
将 IT Words Learning 项目推送到 GitHub 并启用自动部署

## 📋 当前状态
✅ 本地 Git 仓库已初始化  
✅ 代码已提交到本地仓库  
❌ 远程 GitHub 仓库未配置  

## 🚀 设置步骤

### 步骤 1: 创建 GitHub 仓库

1. **登录 GitHub**
   - 访问 https://github.com
   - 使用你的账户登录

2. **创建新仓库**
   - 点击右上角的 "+" 按钮
   - 选择 "New repository"

3. **仓库配置**
   ```
   Repository name: ITWORDS
   Description: IT Words Learning - 多语言单词学习系统
   Visibility: Public (推荐) 或 Private
   
   ⚠️ 重要：不要勾选以下选项
   - Add a README file
   - Add .gitignore  
   - Choose a license
   ```

4. **创建仓库**
   - 点击 "Create repository"

### 步骤 2: 连接本地仓库到 GitHub

创建仓库后，GitHub 会显示设置说明。你需要执行以下命令：

```bash
# 添加远程仓库（替换 YOUR_USERNAME 为你的 GitHub 用户名）
git remote add origin https://github.com/YOUR_USERNAME/ITWORDS.git

# 推送代码到 GitHub
git branch -M main
git push -u origin main
```

### 步骤 3: 验证推送成功

推送完成后：
1. 刷新 GitHub 仓库页面
2. 确认所有文件都已上传
3. 检查是否有 `.github/workflows/deploy-to-aws.yml` 文件

### 步骤 4: 配置 GitHub Secrets

按照 `setup-github-secrets.md` 中的指南配置以下 Secrets：

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `S3_BUCKET`
- `EC2_HOST`
- `EC2_PRIVATE_KEY`

### 步骤 5: 测试自动部署

配置完成后，推送任何代码变更都会触发自动部署：

```bash
git add .
git commit -m "test: 测试自动部署"
git push origin main
```

## 🔧 如果你已经有 GitHub 仓库

如果你已经有一个 GitHub 仓库，直接添加远程地址：

```bash
# 添加远程仓库
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git

# 推送代码
git push -u origin main
```

## 📞 需要帮助？

如果遇到问题：
1. 确认 GitHub 用户名和仓库名正确
2. 检查网络连接
3. 确认 Git 凭证配置正确

## 🎉 完成后

仓库设置完成后，你将拥有：
- ✅ 完整的项目代码托管
- ✅ 自动化 CI/CD 部署
- ✅ 代码版本控制
- ✅ 团队协作能力

---

**下一步：配置 GitHub Secrets 并享受自动部署！** 🚀 