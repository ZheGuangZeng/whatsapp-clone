# WhatsApp Clone Development Guide Using CCPM Methodology

## 概览 (Overview)

This comprehensive guide outlines the development of a WhatsApp clone using CCPM (Claude Code Project Management) methodology with Flutter, Supabase, and modern best practices for 2024-2025.

## 🎯 技术栈建议 (Recommended Technology Stack)

### ✅ **推荐技术栈 (Recommended Stack)**

- **前端**: Flutter (跨平台，高性能)
- **后端**: Supabase (实时数据库，认证，存储)
- **状态管理**: **Riverpod** (现代化，灵活，测试友好)
- **实时通信**: Supabase Realtime + LiveKit (音视频通话)
- **测试**: TDD 方法 (测试驱动开发)
- **架构**: Clean Architecture + CCPM 流程

### 🏗️ **技术栈分析**

#### Flutter + Supabase 组合 ✅
- **优势**: 原生性能，实时同步，内置认证
- **适合**: 聊天应用，群组功能，社区功能
- **生态**: 成熟的社区支持和官方文档

#### 状态管理选择: Riverpod vs Bloc

| 特性 | Riverpod | Bloc |
|------|----------|------|
| **学习曲线** | 较简单 | 较陡峭 |
| **性能** | 优秀 | 优秀 |
| **测试友好性** | 极佳 | 优秀 |
| **代码简洁性** | 更简洁 | 更多样板代码 |
| **企业级应用** | 适合 | 非常适合 |
| **2024推荐** | ✅ **推荐** | 适合复杂应用 |

**结论**: 选择 **Riverpod** - 现代化，减少样板代码，优秀的测试支持

## 📋 CCPM 开发流程

### Phase 1: 🧠 Brainstorm (头脑风暴)
```
目标: 深入思考项目需求，使用 Opus 模型进行规划
方法: Ultra Think 模式进行深度分析
```

### Phase 2: 📝 Document (文档化)
```
创建: 产品需求文档 (PRD)
工具: /pm:prd-new 命令
内容: 精确、无歧义的规格说明
```

### Phase 3: 📐 Plan (计划)
```
架构决策: 明确技术选型
工具: /pm:prd-parse 转换为实施计划
输出: 详细的技术架构图
```

### Phase 4: ⚡ Execute (执行)
```
开发: 严格按照规格实施
工具: /pm:epic-oneshot 分解并同步到 GitHub
方法: 5-8 个并行任务同时执行
```

### Phase 5: 📊 Track (跟踪)
```
监控: 透明的进度跟踪
工具: /pm:issue-start, /pm:issue-sync
目标: 保持项目可见性和可追溯性
```

## 🚀 分步实施指南

### 第一阶段: 环境搭建与基础架构

#### 1. CCPM 工具安装和初始化

##### 步骤 1: 官方快速安装 (推荐)
```bash
# 1. 创建项目目录
mkdir whatsapp-clone
cd whatsapp-clone

# 2. 官方一键安装脚本 (2分钟完成)
# macOS/Linux
curl -sSL https://raw.githubusercontent.com/automazeio/ccpm/main/ccpm.sh | bash

# Windows PowerShell (可选)
# iwr -useb https://raw.githubusercontent.com/automazeio/ccpm/main/ccpm.bat | iex

# 3. 初始化 CCPM 系统
/pm:init

# 4. 更新 CLAUDE.md 规则 (如果已有 CLAUDE.md)
/re-init

# 5. 创建项目上下文 (优化系统理解)
/context:create
```

##### 步骤 1备选: 手动克隆方式
```bash
# 如果需要手动安装或已有 .claude 目录
git clone https://github.com/automazeio/ccpm.git temp-ccpm
cp -r temp-ccpm/.claude/* .claude/
rm -rf temp-ccpm
/pm:init
```

##### 步骤 2: CCPM 初始化详细说明
初始化脚本会自动完成以下任务：

```bash
🚀 CCPM 初始化检查清单:
✅ 检查 GitHub CLI (gh) 是否安装
✅ 验证 GitHub 身份认证状态
✅ 安装 gh-sub-issue 扩展 (用于创建子任务)
✅ 创建 CCPM 目录结构:
   ├── .claude/prds/         # PRD 文档存储
   ├── .claude/epics/        # Epic 任务分解
   ├── .claude/rules/        # CCPM 规则配置
   ├── .claude/agents/       # 子代理配置
   └── .claude/scripts/pm/   # PM 脚本工具
✅ 检查 Git 仓库配置
✅ 创建 CLAUDE.md 项目规则文件
```

##### 步骤 3: GitHub 仓库设置
```bash
# 如果没有远程仓库，需要创建并设置
# 1. 在 GitHub 创建新仓库 (不要用 automazeio/ccpm)
# 2. 设置远程仓库地址
git remote add origin https://github.com/YOUR_USERNAME/whatsapp-clone.git

# 3. 推送初始代码
git push -u origin main
```

##### 步骤 4: 验证 CCPM 安装
```bash
# 检查 CCPM 系统状态
/pm:status

# 查看可用命令
/pm:help

# 验证 GitHub 集成
gh auth status
gh extension list
```

#### 2. Flutter 项目集成
```bash
# 在已有的 CCPM 目录中初始化 Flutter 项目
flutter create . --project-name whatsapp_clone

# 或者如果需要，可以删除现有内容重新创建
rm -rf lib/ test/ pubspec.yaml
flutter create . --project-name whatsapp_clone --overwrite
```

#### 2. 依赖配置
```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  
  # 状态管理
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3
  
  # Supabase
  supabase_flutter: ^2.0.2
  
  # 实时通信
  livekit_client: ^1.6.4
  
  # UI 组件
  flutter_chat_ui: ^1.6.9
  flutter_supabase_chat_core: ^0.1.2
  
  # 其他工具
  go_router: ^12.1.3
  image_picker: ^1.0.4
  permission_handler: ^11.0.1
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # 代码生成
  riverpod_generator: ^2.3.9
  build_runner: ^2.4.7
  
  # 测试
  mocktail: ^1.0.0
  integration_test:
    sdk: flutter
```

#### 3. Supabase 环境配置

##### 本地开发环境
```bash
# 安装 Supabase CLI
npm install -g @supabase/cli

# 初始化本地项目
supabase init

# 启动本地开发服务器
supabase start

# 生成数据库类型定义
supabase gen types dart --local > lib/types/database.dart
```

##### 云端部署
```bash
# 链接到云端项目
supabase link --project-ref YOUR_PROJECT_REF

# 推送本地数据库变更
supabase db push

# 生成云端类型定义
supabase gen types dart --project-ref YOUR_PROJECT_REF > lib/types/database.dart
```

##### 自托管部署
```bash
# 使用 Docker Compose
supabase start --ignore-health-check
supabase status

# 部署到生产环境
supabase deploy
```

### 第二阶段: 核心架构实现

#### 4. Clean Architecture 结构
```
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── utils/
│   └── providers/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── chat/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── groups/
│   └── communities/
├── shared/
│   ├── widgets/
│   ├── services/
│   └── repositories/
└── main.dart
```

#### 5. 数据库 Schema 设计
```sql
-- 用户表
CREATE TABLE profiles (
  id UUID REFERENCES auth.users PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  avatar_url TEXT,
  status TEXT DEFAULT 'online',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 聊天室表
CREATE TABLE rooms (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT,
  type TEXT CHECK (type IN ('direct', 'group', 'community')) NOT NULL,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 消息表
CREATE TABLE messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  room_id UUID REFERENCES rooms(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT,
  type TEXT CHECK (type IN ('text', 'image', 'file', 'audio', 'video')) DEFAULT 'text',
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 群组成员表
CREATE TABLE room_participants (
  room_id UUID REFERENCES rooms(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT CHECK (role IN ('admin', 'member')) DEFAULT 'member',
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (room_id, user_id)
);

-- RLS 策略
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_participants ENABLE ROW LEVEL SECURITY;

-- 安全策略
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view messages in joined rooms" ON messages
  FOR SELECT USING (
    room_id IN (
      SELECT room_id FROM room_participants 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert messages in joined rooms" ON messages
  FOR INSERT WITH CHECK (
    user_id = auth.uid() AND
    room_id IN (
      SELECT room_id FROM room_participants 
      WHERE user_id = auth.uid()
    )
  );
```

### 第三阶段: TDD 开发实践

#### 6. 测试架构
```dart
// test/helpers/test_helpers.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockRealtimeClient extends Mock implements RealtimeClient {}

class TestHelpers {
  static MockSupabaseClient getMockSupabaseClient() {
    final mockClient = MockSupabaseClient();
    final mockAuth = MockGoTrueClient();
    final mockRealtime = MockRealtimeClient();
    
    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockClient.realtime).thenReturn(mockRealtime);
    
    return mockClient;
  }
}
```

#### 7. 核心功能测试
```dart
// test/features/chat/domain/chat_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('ChatRepository', () {
    late ChatRepository repository;
    late MockSupabaseClient mockClient;

    setUp(() {
      mockClient = TestHelpers.getMockSupabaseClient();
      repository = SupabaseChatRepository(mockClient);
    });

    test('should send message successfully', () async {
      // Arrange
      const message = Message(
        id: 'test-id',
        content: 'Hello World',
        userId: 'user-1',
        roomId: 'room-1',
      );

      when(() => mockClient.from('messages').insert(any()))
          .thenAnswer((_) async => null);

      // Act
      final result = await repository.sendMessage(message);

      // Assert
      expect(result, isA<Right<Failure, void>>());
      verify(() => mockClient.from('messages').insert({
        'content': 'Hello World',
        'user_id': 'user-1',
        'room_id': 'room-1',
        'type': 'text',
      })).called(1);
    });
  });
}
```

### 第四阶段: 核心功能实现

#### 8. 认证系统
```dart
// lib/features/auth/data/auth_repository.dart
@riverpod
class AuthRepository extends _$AuthRepository {
  @override
  FutureOr<User?> build() async {
    final session = Supabase.instance.client.auth.currentSession;
    return session?.user;
  }

  Future<Either<AuthFailure, User>> signInWithEmail(
    String email, 
    String password,
  ) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        ref.invalidateSelf();
        return Right(response.user!);
      }
      
      return Left(AuthFailure('Sign in failed'));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  Future<Either<AuthFailure, void>> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      ref.invalidateSelf();
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}
```

#### 9. 实时聊天功能
```dart
// lib/features/chat/data/chat_repository.dart
@riverpod
class ChatRepository extends _$ChatRepository {
  @override
  Stream<List<Message>> build(String roomId) {
    return Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at')
        .map((data) => data.map((json) => Message.fromJson(json)).toList());
  }

  Future<Either<ChatFailure, void>> sendMessage({
    required String roomId,
    required String content,
    required MessageType type,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return Left(ChatFailure('User not authenticated'));
      }

      await Supabase.instance.client.from('messages').insert({
        'room_id': roomId,
        'user_id': user.id,
        'content': content,
        'type': type.name,
        'created_at': DateTime.now().toIso8601String(),
      });

      return const Right(null);
    } catch (e) {
      return Left(ChatFailure(e.toString()));
    }
  }
}
```

#### 10. LiveKit 音视频集成
```dart
// lib/features/call/services/call_service.dart
@riverpod
class CallService extends _$CallService {
  Room? _room;
  
  @override
  FutureOr<CallState> build() {
    return const CallState.idle();
  }

  Future<void> startCall({
    required String roomName,
    required String token,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      _room = Room();
      
      _room!.addListener(_onRoomUpdate);
      
      await _room!.connect(
        'wss://your-livekit-server.com',
        token,
      );
      
      // 启用音频和视频
      await _room!.localParticipant?.setCameraEnabled(true);
      await _room!.localParticipant?.setMicrophoneEnabled(true);
      
      state = AsyncValue.data(CallState.connected(_room!));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void _onRoomUpdate() {
    if (_room != null) {
      state = AsyncValue.data(CallState.connected(_room!));
    }
  }

  Future<void> endCall() async {
    await _room?.disconnect();
    _room?.removeListener(_onRoomUpdate);
    _room = null;
    state = const AsyncValue.data(CallState.idle());
  }
}
```

### 第五阶段: 群组和社区功能

#### 11. 群组管理
```dart
// lib/features/groups/data/group_repository.dart
@riverpod
class GroupRepository extends _$GroupRepository {
  @override
  FutureOr<List<Group>> build() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    final response = await Supabase.instance.client
        .from('rooms')
        .select('''
          *,
          room_participants!inner(*)
        ''')
        .eq('type', 'group')
        .eq('room_participants.user_id', user.id);

    return response.map((json) => Group.fromJson(json)).toList();
  }

  Future<Either<GroupFailure, Group>> createGroup({
    required String name,
    required List<String> memberIds,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return Left(GroupFailure('User not authenticated'));
      }

      // 创建群组
      final roomResponse = await Supabase.instance.client
          .from('rooms')
          .insert({
            'name': name,
            'type': 'group',
            'metadata': {'created_by': user.id},
          })
          .select()
          .single();

      final roomId = roomResponse['id'] as String;

      // 添加成员（包括创建者）
      final participants = [
        {'room_id': roomId, 'user_id': user.id, 'role': 'admin'},
        ...memberIds.map((id) => {
          'room_id': roomId,
          'user_id': id,
          'role': 'member',
        }),
      ];

      await Supabase.instance.client
          .from('room_participants')
          .insert(participants);

      ref.invalidateSelf();
      return Right(Group.fromJson(roomResponse));
    } catch (e) {
      return Left(GroupFailure(e.toString()));
    }
  }
}
```

### 第六阶段: 测试和质量保证

#### 12. 集成测试
```dart
// integration_test/app_test.dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:whatsapp_clone/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('WhatsApp Clone Integration Tests', () {
    testWidgets('complete user journey: auth -> chat -> call', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. 测试登录流程
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(Key('password_field')), 'password123');
      
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle(Duration(seconds: 3));

      // 验证登录成功
      expect(find.text('Chats'), findsOneWidget);

      // 2. 测试发送消息
      await tester.tap(find.text('Test User').first);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(Key('message_input')), 
        'Hello from integration test!'
      );
      await tester.tap(find.byKey(Key('send_button')));
      await tester.pumpAndSettle();

      // 验证消息发送
      expect(find.text('Hello from integration test!'), findsOneWidget);

      // 3. 测试视频通话
      await tester.tap(find.byKey(Key('video_call_button')));
      await tester.pumpAndSettle();

      // 验证通话界面
      expect(find.byKey(Key('call_controls')), findsOneWidget);
    });
  });
}
```

#### 13. 性能测试
```dart
// test/performance/performance_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Performance Tests', () {
    test('message loading performance', () async {
      final stopwatch = Stopwatch()..start();
      
      // 模拟加载1000条消息
      final messages = List.generate(1000, (i) => Message(
        id: 'msg-$i',
        content: 'Message $i',
        userId: 'user-1',
        roomId: 'room-1',
      ));

      stopwatch.stop();
      
      // 确保在500ms内完成
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    test('real-time update performance', () async {
      // 测试实时更新性能
      final repository = ChatRepository();
      final stopwatch = Stopwatch()..start();
      
      await repository.sendMessage(
        roomId: 'test-room',
        content: 'Performance test message',
        type: MessageType.text,
      );
      
      stopwatch.stop();
      
      // 确保在200ms内完成
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
    });
  });
}
```

## 🛠️ CCPM 工具使用指南

### 完整命令参考

#### 初始化和配置命令
```bash
# 系统初始化
/pm:init                          # 初始化 CCPM 系统
/pm:status                        # 查看系统状态
/pm:help                          # 显示帮助信息
/re-init                          # 重新初始化或更新 CLAUDE.md

# 上下文管理
/context:create                   # 创建项目上下文 (优化系统理解)
```

#### PRD (产品需求文档) 命令
```bash
/pm:prd-new <feature-name>        # 创建新的 PRD
/pm:prd-list                      # 列出所有 PRD
/pm:prd-status <feature-name>     # 查看 PRD 状态
/pm:prd-edit <feature-name>       # 编辑现有 PRD
/pm:prd-parse <feature-name>      # 将 PRD 转换为技术实施方案
```

#### Epic (史诗任务) 命令  
```bash
/pm:epic-oneshot <epic-name>      # 一键创建并分解 Epic
/pm:epic-list                     # 列出所有 Epic
/pm:epic-show <epic-name>         # 显示 Epic 详情
/pm:epic-status <epic-name>       # 查看 Epic 状态
/pm:epic-sync <epic-name>         # 同步 Epic 到 GitHub
/pm:epic-start <epic-name>        # 开始 Epic 开发
/pm:epic-start-worktree <epic>    # 在 worktree 中开始 Epic
```

#### Issue (任务) 命令
```bash
/pm:issue-start #<issue-number>   # 开始处理指定 issue
/pm:issue-sync                    # 同步当前进度到 GitHub
/pm:issue-show #<issue-number>    # 显示 issue 详情
```

#### 搜索和验证命令
```bash
/pm:search <keyword>              # 搜索 PRD 和 Epic 内容
/pm:validate                      # 验证项目配置和文件完整性
```

### 核心工作流命令
```bash
# 标准 CCPM 开发流程
/pm:prd-new "whatsapp-clone"      # 1. 创建 PRD
/pm:prd-parse "whatsapp-clone"    # 2. 解析为技术方案
/pm:epic-oneshot "whatsapp-clone" # 3. 创建并分解 Epic
/pm:issue-start #1                # 4. 开始第一个任务
/pm:issue-sync                    # 5. 同步进度
```

### 工作流示例
```
1. Brainstorm (使用 Opus Ultra Think 模式)
   └── 分析 WhatsApp 核心功能和技术难点

2. Document
   └── 创建详细的 PRD 和技术规格

3. Plan
   └── 架构设计和技术选型决策

4. Execute (5-8 并行任务)
   ├── 认证系统实现
   ├── 实时聊天功能
   ├── 群组管理
   ├── 音视频通话
   └── UI/UX 实现

5. Track
   └── GitHub Issues 实时进度跟踪
```

## 📈 质量保证和最佳实践

### TDD 开发流程
1. **Red**: 编写失败的测试
2. **Green**: 编写最小可行代码使测试通过
3. **Refactor**: 重构代码保持质量

### 测试策略
- **单元测试**: 覆盖率 > 80%
- **集成测试**: 核心用户流程
- **性能测试**: 响应时间 < 200ms
- **端到端测试**: 完整用户场景

### 代码质量
```bash
# 运行所有测试
flutter test

# 运行集成测试
flutter test integration_test/

# 代码格式化
dart format lib/ test/

# 静态分析
flutter analyze

# 性能分析
flutter run --profile
```

## 🚢 部署策略

### 测试环境层级
```
1. Local Development (supabase local dev)
   └── 本地数据库和 API 测试

2. Cloud Staging (supabase cloud)
   └── 云端环境集成测试

3. Self-hosted Production (supabase self-host)
   └── 生产环境部署和监控
```

### CI/CD 流程
```yaml
# .github/workflows/flutter.yml
name: Flutter CI/CD

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
    - run: flutter pub get
    - run: flutter test
    - run: flutter test integration_test/

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
    - run: flutter build apk --release
    - run: flutter build web --release
```

## 🎯 项目里程碑

### Phase 1: 基础设施 (Week 1-2)
- [x] CCPM 工具集成
- [x] Flutter 项目初始化
- [x] Supabase 配置 (本地 → 云端 → 自托管)
- [x] CI/CD 流程设置

### Phase 2: 核心功能 (Week 3-4)
- [ ] 用户认证系统
- [ ] 实时聊天功能
- [ ] 文件上传和媒体处理
- [ ] 推送通知

### Phase 3: 高级功能 (Week 5-6)
- [ ] 群组聊天
- [ ] 语音/视频通话 (LiveKit)
- [ ] 消息状态 (已读/未读)
- [ ] 在线状态

### Phase 4: 社区功能 (Week 7-8)
- [ ] 社区频道
- [ ] 广播消息
- [ ] 管理员功能
- [ ] 内容审核

### Phase 5: 完善和优化 (Week 9-10)
- [ ] 性能优化
- [ ] 安全加固
- [ ] 用户体验优化
- [ ] 文档完善

## 📚 资源和参考

### 官方文档
- [Flutter Documentation](https://docs.flutter.dev/)
- [Supabase Documentation](https://supabase.com/docs)
- [Riverpod Documentation](https://riverpod.dev/)
- [LiveKit Documentation](https://docs.livekit.io/)

### 最佳实践参考
- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)
- [Supabase Flutter Examples](https://github.com/supabase/supabase-flutter)
- [Clean Architecture Flutter](https://github.com/ResoCoder/flutter-tdd-clean-architecture-course)

### CCPM 相关
- [CCPM GitHub Repository](https://github.com/automazeio/ccpm.git)
- [Claude Code Documentation](https://docs.anthropic.com/claude/docs)

---

## 🎉 开始开发

### 完整启动流程

准备好开始了吗？按照以下完整流程开始你的 WhatsApp 克隆之旅：

#### 1. 环境准备
```bash
# 确保系统已安装必要工具
# GitHub CLI, Flutter, Git

# 验证工具版本
gh --version
flutter --version  
git --version
```

#### 2. 项目初始化
```bash
# 1. 使用官方快速安装 (推荐)
mkdir whatsapp-clone && cd whatsapp-clone
curl -sSL https://raw.githubusercontent.com/automazeio/ccpm/main/ccpm.sh | bash

# 2. 初始化 CCPM 系统
/pm:init

# 3. 更新 CLAUDE.md 规则 (如果已有)
/re-init

# 4. 创建项目上下文
/context:create

# 5. 设置 Git 和 GitHub 仓库
git init
git add .
git commit -m "Initial CCPM setup"

# 4. 创建 GitHub 仓库并推送
git remote add origin https://github.com/YOUR_USERNAME/whatsapp-clone.git
git push -u origin main

# 5. 集成 Flutter 项目
flutter create . --project-name whatsapp_clone
# 注意：可能需要解决文件冲突，保留 .claude/ 目录
```

#### 3. 开始 CCPM 开发流程
```bash
# 步骤 1: 创建 PRD (已完成)
# /pm:prd-new "whatsapp-clone"

# 步骤 2: 解析 PRD 为技术实施方案
/pm:prd-parse "whatsapp-clone"

# 步骤 3: 创建并分解 Epic 任务
/pm:epic-oneshot "whatsapp-clone"  

# 步骤 4: 开始第一个开发任务
/pm:issue-start #1

# 步骤 5: 持续同步进度
/pm:issue-sync
```

#### 4. 验证设置
```bash
# 检查 CCPM 状态
/pm:status

# 查看创建的文件
ls -la .claude/prds/
ls -la .claude/epics/

# 验证 GitHub 集成
gh repo view
gh issue list
```

### 核心原则

**CCPM 开发黄金法则:**
- **每一行代码都必须能够追溯到规格说明**
- **先文档，后代码** - PRD → Epic → Issue → Code  
- **测试驱动开发** - 每个功能都要有对应测试
- **并行开发** - 使用多个 issue 同时推进 5-8 个任务

### 如果遇到问题

```bash
# 查看帮助
/pm:help

# 重新初始化
/pm:init

# 验证配置
/pm:validate

# 搜索相关命令或文档
/pm:search "issue"
```

Good luck! 🚀