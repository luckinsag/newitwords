# IT单词学习系统 - 项目概览

## 📋 项目简介

**IT单词学习系统**是一个面向IT从业人员和学习者的在线单词学习平台，支持多语言学习（日语、中文、英文），提供完整的学习闭环：学习 → 测试 → 复习 → 巩固。

## 🏗️ 技术架构

### 前端技术栈
- **Vue 3.3.4** - 使用 Composition API
- **Vuetify 3.8.8** - Material Design UI框架  
- **Vue Router 4.2.4** - 单页面路由管理
- **Pinia 3.0.3** - 状态管理
- **Axios 1.9.0** - HTTP客户端
- **ECharts 5.6.0** - 数据可视化
- **Vite 5.0.0** - 构建工具

### 后端技术栈
- **Spring Boot** - 主框架
- **Spring Security** - 安全框架
- **MyBatis** - 数据持久化
- **MySQL** - 数据库
- **Maven** - 项目管理

## 📁 项目结构

```
ITWORDS/
├── documents/                    # 📚 项目文档
│   ├── 详细设计书.md             # 详细技术设计文档
│   ├── 基本设计书.md             # 项目基础设计文档
│   ├── AWS-DEPLOYMENT-GUIDE.md   # AWS部署指南
│   ├── aws-cost-analysis.md      # AWS成本分析
│   ├── aws-setup-guide.md        # AWS设置指南
│   ├── conversion-guide.md       # 转换指南
│   ├── startup-status.md         # 启动状态文档
│   └── README.md                 # 项目说明
│
├── project-structure/            # 🏗️ 主要项目代码
│   ├── frontend-app/             # 前端应用 (Vue.js)
│   │   ├── src/
│   │   │   ├── api/              # API服务层
│   │   │   ├── components/       # Vue组件
│   │   │   ├── views/            # 页面组件
│   │   │   ├── router/           # 路由配置
│   │   │   └── store/            # 状态管理
│   │   ├── public/avatars/       # 用户头像资源
│   │   └── package.json          # 前端依赖配置
│   │
│   ├── backend-api/              # 后端API (Spring Boot)
│   │   └── src/main/java/com/example/itwordslearning/
│   │       ├── controller/       # 控制器层
│   │       ├── service/          # 业务逻辑层
│   │       ├── mapper/           # 数据访问层
│   │       ├── entity/           # 数据实体
│   │       ├── dto/              # 数据传输对象
│   │       ├── config/           # 配置类
│   │       └── exception/        # 异常处理
│   │
│   ├── aws-deployment/           # AWS部署相关脚本
│   └── deployment-scripts/       # 通用部署脚本
│
├── scripts-and-configs/          # 🔧 脚本和配置文件
│   ├── docker-compose.yml        # Docker编排配置
│   ├── nginx.conf                # Nginx配置
│   ├── database-setup.sql        # 数据库初始化脚本
│   └── *.sh                      # 各种部署和管理脚本
│
├── docker-and-deployment/        # 🐳 Docker和部署文件
│   ├── Dockerfile                # Docker镜像构建文件
│   ├── AWSCLIV2.pkg              # AWS CLI安装包
│   └── *.sh                      # 部署相关脚本
│
├── code-and-project-files/       # 💻 代码和项目文件
│   ├── convert-to-image.js       # 图像转换脚本
│   └── 其他项目文件
│
└── images-and-diagrams/          # 🖼️ 图像和图表
    ├── architecture-diagram.png   # 架构图
    ├── conversion-flow.png        # 转换流程图
    └── *.mmd                      # Mermaid图表源文件
```

## 🌟 核心功能

### 1. 用户管理
- ✅ 用户注册/登录
- ✅ 个人信息管理
- ✅ 用户设置

### 2. 单词学习
- ✅ 分类单词浏览
- ✅ 多语言显示（日/中/英）
- ✅ 学习笔记记录
- ✅ 重点单词标记

### 3. 测试系统
- ✅ 智能组题测试
- ✅ 成绩记录
- ✅ 错题收集
- ✅ 测试历史查看

### 4. 数据分析
- ✅ 学习进度统计
- ✅ 成绩趋势分析
- ✅ 错题分布分析
- ✅ 可视化图表

### 5. 学习管理
- ✅ 重点单词管理
- ✅ 错题本复习
- ✅ 学习记录跟踪

## 🗄️ 数据库设计

### 核心数据表
- **users** - 用户基本信息
- **words** - 单词词库（日/中/英 + 分类）
- **user_notes** - 用户学习笔记
- **user_tests** - 测试记录
- **user_wrong** - 错题记录
- **user_test_sessions** - 测试会话
- **user_settings** - 用户设置

## 🚀 部署方式

### 开发环境
```bash
# 前端 (端口3000)
cd project-structure/frontend-app
npm install && npm run dev

# 后端 (端口8080)
cd project-structure/backend-api
mvn spring-boot:run

# 数据库 (端口3306)
mysql -u root -p < scripts-and-configs/database-setup.sql
```

### Docker部署
```bash
# 使用Docker Compose一键启动
docker-compose up -d
```

### AWS部署
```bash
# 参考 documents/AWS-DEPLOYMENT-GUIDE.md
# 使用提供的AWS部署脚本
./docker-and-deployment/start-project.sh
```

## 📊 API接口概览

### 认证相关
- `POST /api/auth/login` - 用户登录
- `POST /api/auth/register` - 用户注册

### 单词相关
- `POST /api/words/all` - 获取所有单词
- `POST /api/words/byCategories` - 按分类获取单词

### 学习相关
- `POST /api/userNotes/addto-important-wordlist` - 添加重点单词
- `PUT /api/userNotes/save-comments` - 保存学习笔记
- `POST /api/userNotes/show-important-wordlist` - 查看重点单词

### 测试相关
- `POST /api/userTest/add` - 保存测试记录
- `POST /api/userWrong/add` - 添加错题
- `POST /api/userWrong/list` - 获取错题列表

## 🔒 安全特性

- ✅ 用户认证和会话管理
- ✅ 密码加密存储
- ✅ SQL注入防护
- ✅ 跨域请求控制
- ✅ 统一异常处理

## 📈 性能优化

- ✅ Vue3 Composition API优化
- ✅ 路由懒加载
- ✅ 数据库索引优化
- ✅ 分页查询支持
- ✅ 前端组件缓存

## 🔄 扩展规划

### 功能扩展
- [ ] 语音朗读功能
- [ ] 社交学习功能  
- [ ] 离线学习模式
- [ ] 移动端应用

### 技术扩展
- [ ] 微服务架构改造
- [ ] Redis缓存集成
- [ ] 消息队列支持
- [ ] Kubernetes部署

## 📝 开发规范

### 前端
- Vue 3 Composition API
- 统一组件命名规范
- 统一API请求封装
- 统一错误处理机制

### 后端
- RESTful API设计
- 分层架构 (Controller-Service-Mapper)
- 统一响应格式 Result<T>
- 全局异常处理

---

## 🚀 快速开始

1. **克隆项目**
   ```bash
   git clone <项目地址>
   cd ITWORDS
   ```

2. **启动后端**
   ```bash
   cd project-structure/backend-api
   mvn spring-boot:run
   ```

3. **启动前端**
   ```bash
   cd project-structure/frontend-app
   npm install
   npm run dev
   ```

4. **初始化数据库**
   ```bash
   mysql -u root -p < scripts-and-configs/database-setup.sql
   ```

5. **访问应用**
   - 前端: http://localhost:3000
   - 后端API: http://localhost:8080

---

**更多详细信息请参考 `documents/` 目录下的相关文档。** 