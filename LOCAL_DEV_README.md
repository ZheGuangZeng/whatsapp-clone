# WhatsApp Clone - 本地开发环境

## 🎯 概述

这个文档描述了如何在本地开发环境中运行WhatsApp Clone，包括Mock服务和完整的本地Supabase实例。

## 📋 生产就绪状态

✅ **Production-Ready Epic已完成 (100%)**

| Task | Status | Description |
|------|--------|-------------|
| Task 21 | ✅ Complete | Code Quality Excellence (256→49 warnings) |
| Task 22 | ✅ Complete | Performance Optimization Bundle |
| Task 23 | ✅ Complete | CI/CD Pipeline Complete (Flutter mobile) |
| Task 24 | ✅ Complete | Production Infrastructure |
| Task 25 | ✅ Complete | Monitoring & Observability |

## 🚀 快速启动

### 选项 1: Mock服务模式 (推荐用于快速测试)

```bash
# 1. 启动简化版本 - 纯本地Mock服务
flutter run -d chrome -t lib/main_local.dart
```

这个模式包含：
- 🎭 Mock Supabase服务
- 🎥 Mock LiveKit会议服务  
- 📊 Mock监控服务
- 💬 模拟消息和用户数据
- 🔧 开发工具面板

### 选项 2: 完整本地服务 (推荐用于完整开发)

```bash
# 1. 确保Docker Desktop运行 
# macOS: open -a Docker
# 或手动打开Docker Desktop应用

# 2. 启动本地Supabase服务
supabase start

# 3. 启动LiveKit服务 (可选)
docker-compose -f docker-compose.livekit.yml up -d

# 4. 在新终端中启动Flutter应用
flutter run -d chrome -t lib/main_local.dart
```

这个模式包含：
- 🗄️ 完整PostgreSQL数据库
- 🔐 Supabase认证服务  
- 📡 实时通信服务
- 📦 文件存储服务
- 📊 Supabase Studio (http://127.0.0.1:54323)
- ✅ **已验证工作** - Supabase完全可用
- 🎥 LiveKit视频会议服务 (配置中 - Mock服务可用)

## 📁 项目结构

```
whatsapp-clone/
├── lib/
│   ├── main.dart              # 生产版本 (需要真实凭据)
│   ├── main_dev.dart          # 简化开发版本
│   ├── main_local.dart        # 完整本地开发版本
│   └── core/services/
│       └── mock_services.dart # Mock服务系统
├── docker-compose.local.yml   # 本地Supabase配置
├── .env.local                 # 本地开发环境变量
└── scripts/
    └── start-local-dev.sh     # 本地环境启动脚本
```

## 🛠️ 本地开发服务

### Mock服务组件

| 服务 | 描述 | 状态 |
|-----|------|------|
| MockSupabaseService | 模拟数据库和认证 | ✅ 可用 |
| MockLiveKitService | 模拟视频会议 | ✅ 可用 |
| MockFirebaseService | 模拟监控和分析 | ✅ 可用 |

### 完整本地服务

| 服务 | URL | 状态 |
|-----|-----|------|
| Supabase Studio | http://127.0.0.1:54323 | ✅ 可用 |
| API Gateway | http://127.0.0.1:54321 | ✅ 可用 |
| PostgreSQL | localhost:54322 | ✅ 可用 |
| Realtime | ws://127.0.0.1:54321/realtime/v1 | ✅ 可用 |
| Storage | http://127.0.0.1:54321/storage/v1/s3 | ✅ 可用 |
| LiveKit Server | ws://localhost:7880 | 🔧 配置中 |
| Mock LiveKit | Mock服务 | ✅ 可用 |

## 🎮 开发功能

### Mock版本功能 (main_local.dart)

1. **概览页面**: 显示生产就绪状态和本地服务状态
2. **消息测试**: 模拟实时消息发送和接收
3. **会议测试**: 模拟视频会议创建和参与者管理
4. **开发工具**: 错误报告、分析事件、环境信息

### 测试数据

Mock服务预加载了以下测试数据：
- 3个模拟用户 (Alice, Bob, Charlie)
- 5条历史消息
- 随机会议参与者

## 🔧 环境配置

### .env.local 配置

```bash
# 核心配置
ENVIRONMENT=development
SUPABASE_URL=http://localhost:8000
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# 功能开关
ENABLE_ANALYTICS=false
ENABLE_CRASH_REPORTING=false
ENABLE_PERFORMANCE_MONITORING=false
ENABLE_LOGGING=true
LOG_LEVEL=debug
```

## 📊 开发工具

### 1. 内置开发面板

访问 `main_local.dart` 的开发工具页面：
- 测试错误报告
- 发送分析事件
- 查看环境信息
- 访问Supabase Studio

### 2. Docker管理

```bash
# 查看服务状态
docker-compose -f docker-compose.local.yml ps

# 查看服务日志
docker-compose -f docker-compose.local.yml logs [service_name]

# 停止所有服务
docker-compose -f docker-compose.local.yml down

# 清理卷和数据
docker-compose -f docker-compose.local.yml down -v
```

### 3. 数据库管理

```bash
# 直连数据库
psql -h localhost -p 54322 -U postgres -d postgres

# 或通过Supabase Studio
# http://localhost:3000
```

## 🧪 测试流程

### 1. 基础UI测试
- 启动 `flutter run -d chrome -t lib/main_local.dart`
- 验证4个页面都能正常显示
- 测试底部导航

### 2. 消息功能测试  
- 进入消息页面
- 发送测试消息
- 验证实时更新

### 3. 会议功能测试
- 进入会议页面  
- 创建测试会议
- 验证参与者管理

### 4. 完整服务测试
- 启动完整Supabase服务
- 访问Studio创建表结构
- 测试认证和数据存储

## 🚨 故障排除

### 常见问题

1. **Docker服务启动失败**
   ```bash
   # 检查端口冲突
   lsof -i :3000,8000,54322
   
   # 清理旧容器
   docker system prune -f
   ```

2. **Flutter应用启动卡住**
   - 使用Mock版本: `flutter run -d chrome -t lib/main_local.dart`
   - 检查Chrome是否允许localhost连接

3. **数据库连接失败**
   ```bash
   # 检查数据库服务状态
   docker-compose -f docker-compose.local.yml logs db
   ```

4. **端口冲突**
   - 修改 `.env.local` 中的端口配置
   - 重启Docker服务

### Debug模式

```bash
# 启用详细日志
export LOG_LEVEL=debug
flutter run -d chrome -t lib/main_local.dart --verbose
```

## 🎯 下一步

现在本地开发环境已经完整配置，你可以：

1. **🧪 开发新功能**: 在Mock环境中快速原型开发
2. **📱 测试完整流程**: 使用本地Supabase进行集成测试
3. **🚀 部署到Staging**: 将代码部署到staging环境验证
4. **📦 生产部署**: 使用CI/CD pipeline部署到生产环境

## 📝 技术说明

- **Flutter版本**: 3.35.2
- **Dart版本**: 3.9.0  
- **Supabase版本**: Latest (Docker)
- **支持平台**: Web (Chrome), iOS, Android
- **开发模式**: Mock服务 + 本地Supabase

---

**🎉 恭喜！WhatsApp Clone本地开发环境已完成配置！**

现在你可以在完全本地的环境中开发和测试所有功能，无需依赖外部服务。