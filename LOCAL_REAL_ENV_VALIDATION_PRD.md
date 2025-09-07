# CCPM PRD: 本地真实环境验证

## 问题陈述 (Problem Statement)

当前本地开发环境使用Mock服务进行测试，虽然开发便利但无法验证真实的Supabase和LiveKit集成。这导致：

1. **部署风险**: Mock环境通过不代表生产环境能正常工作
2. **集成盲点**: 无法发现Supabase RLS政策、数据库约束、实时订阅等问题
3. **调试困难**: 生产环境问题无法在本地重现

**核心需求**: 建立本地真实环境，使用实际的Supabase和LiveKit服务进行完整验证。

## Epic 定义

**Epic名称**: Local Real Environment Validation  
**目标**: 实现本地真实Supabase+LiveKit环境，确保部署前完整验证  
**成功标准**: 
- Flutter应用完全连接本地真实Supabase
- 所有消息、用户、会议功能正常工作
- LiveKit音视频通话功能验证通过

## 任务分解 (Task Breakdown)

### Phase 1: 数据库基础设施
**Task 1**: 创建真实Supabase数据库Schema
- 实现完整用户表结构 (users, profiles)
- 创建消息相关表 (chats, messages, participants)
- 建立会议功能表 (meetings, meeting_participants)
- 配置Row Level Security (RLS) 政策

**Task 2**: 初始化测试数据
- 创建测试用户账户
- 建立示例聊天会话
- 准备会议室测试数据

### Phase 2: Flutter应用集成
**Task 3**: 移除Mock服务依赖
- 删除lib/core/services/mock_services.dart中的Mock实现
- 更新依赖注入配置指向真实服务

**Task 4**: 实现真实Supabase连接
- 配置Supabase客户端连接本地实例
- 实现真实认证流程
- 建立实时数据订阅

**Task 5**: LiveKit真实服务集成
- 配置LiveKit客户端连接本地服务器
- 实现音视频通话功能
- 测试房间创建和加入流程

### Phase 3: 功能验证
**Task 6**: 消息系统验证
- 测试用户注册登录
- 验证消息发送接收
- 确认实时消息同步

**Task 7**: 会议功能验证
- 测试会议室创建
- 验证音视频通话质量
- 确认参与者管理功能

**Task 8**: 端到端集成测试
- 模拟完整用户使用场景
- 验证所有功能正常工作
- 性能和稳定性测试

## 实施指南 (Implementation Guide)

### Step 1: 环境准备
```bash
# 确保Docker和Supabase CLI已安装
supabase status
docker-compose -f docker-compose.local.yml ps

# 检查服务运行状态
curl http://localhost:54321/rest/v1/
curl http://localhost:7880/
```

### Step 2: 数据库Schema创建
```bash
# 进入Supabase目录
cd supabase

# 创建迁移文件
supabase migration new create_real_schema

# 应用迁移
supabase db push
```

### Step 3: Flutter配置更新
```bash
# 更新环境配置
cp .env.example .env.local

# 修改Supabase连接配置
# SUPABASE_URL=http://localhost:54321
# SUPABASE_ANON_KEY=your-anon-key

# 运行本地真实环境
flutter run -t lib/main_local.dart
```

### Step 4: 功能测试验证
1. **用户认证测试**: 注册新用户，验证登录流程
2. **消息功能测试**: 发送消息，确认实时同步
3. **会议功能测试**: 创建房间，测试音视频通话
4. **数据持久化测试**: 重启应用，确认数据保存

## 验收标准 (Acceptance Criteria)

### 必须满足 (Must Have)
- [ ] 本地Supabase数据库完整Schema
- [ ] Flutter应用无Mock服务依赖
- [ ] 用户注册登录功能正常
- [ ] 消息发送接收实时同步
- [ ] LiveKit音视频通话正常工作

### 期望满足 (Should Have)  
- [ ] RLS政策正确配置和验证
- [ ] 错误处理和异常情况覆盖
- [ ] 性能指标达到预期水平

### 可选满足 (Could Have)
- [ ] 自动化测试脚本
- [ ] 监控和日志收集
- [ ] 负载测试验证

## 风险和缓解措施

**风险1**: Supabase本地配置复杂  
**缓解**: 使用官方Docker镜像，遵循标准配置

**风险2**: LiveKit集成困难  
**缓解**: 先验证单独LiveKit功能，再集成Flutter

**风险3**: 数据库迁移问题  
**缓解**: 逐步创建迁移，每次验证后再继续

## 时间估算

- **Phase 1**: 2-3小时 (数据库基础设施)
- **Phase 2**: 3-4小时 (Flutter应用集成) 
- **Phase 3**: 2-3小时 (功能验证)
- **总计**: 7-10小时

## CCPM工作流命令

### 1. 创建新PRD
```bash
/pm:prd-new local-real-env-validation
```

### 2. 创建Epic
```bash
/pm:epic-new local-real-env-validation "Local Real Environment Validation"
```

### 3. 创建Tasks
```bash
# Phase 1: 数据库基础设施
/pm:task-new 1 "创建真实Supabase数据库Schema"
/pm:task-new 2 "初始化测试数据"

# Phase 2: Flutter应用集成  
/pm:task-new 3 "移除Mock服务依赖"
/pm:task-new 4 "实现真实Supabase连接"
/pm:task-new 5 "LiveKit真实服务集成"

# Phase 3: 功能验证
/pm:task-new 6 "消息系统验证"
/pm:task-new 7 "会议功能验证"
/pm:task-new 8 "端到端集成测试"
```

### 4. 执行工作流
```bash
# 开始执行epic
/pm:epic-execute local-real-env-validation

# 更新任务状态
/pm:task-update 1 in-progress
/pm:task-update 1 completed
```

### 5. 跟踪进度
```bash
# 查看epic状态
/pm:epic-status local-real-env-validation

# 查看任务列表
/pm:task-list
```

## 下一步行动

### 第一步: 初始化CCPM工作流
```bash
/pm:prd-new local-real-env-validation
```

### 第二步: 开始执行
1. **立即开始**: 创建Supabase数据库Schema (Task 1)
2. **并行进行**: 准备Flutter应用真实服务连接配置
3. **持续验证**: 每完成一个Task立即进行功能测试

---

**开始执行**: 首先运行 `/pm:prd-new local-real-env-validation` 创建CCPM项目



Functional Requirements:
  - Replace Mock services with real local Supabase instance
  - Integrate real LiveKit server for audio/video testing
  - Maintain all existing Flutter app functionality
  - Database schema matching production environment

  Success Criteria:
  - Zero deployment surprises due to local/production environment differences
  - All messaging, user auth, and meeting features work in local real environment
  - Performance parity between local real environment and production

  Constraints:
  - Must work with existing Docker setup
  - Should not interfere with current Mock-based development workflow
  - Timeline: 7-10 hours as estimated in your documentation

  Does this capture the essence correctly? Are there any specific technical
  requirements, edge cases, or success metrics I should include in the PRD?