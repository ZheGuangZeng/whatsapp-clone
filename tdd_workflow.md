# TDD工作流程 - WhatsApp克隆项目

## TDD原则

### 红-绿-重构循环
1. **🔴 RED**: 写一个失败的测试
2. **🟢 GREEN**: 写最少的代码让测试通过
3. **🔵 REFACTOR**: 改进代码质量，保持测试通过

## 预提交检查清单

### 必须通过的检查：
- [ ] `flutter analyze` 无错误
- [ ] `flutter test` 全部通过 
- [ ] 测试覆盖率 ≥ 80%
- [ ] 每个公共方法都有测试
- [ ] 每个边界条件都有测试

## TDD命令

### 开发前
```bash
# 确保清洁状态
flutter clean && flutter pub get
flutter analyze lib/core/  # 确保核心架构无问题
```

### 开发中 (每个功能)
```bash
# 1. 写测试
flutter test test/path/to/your_test.dart  # 应该失败

# 2. 写实现
flutter test test/path/to/your_test.dart  # 应该通过

# 3. 重构
flutter analyze  # 应该无错误
flutter test     # 应该全部通过
```

### 提交前
```bash
flutter analyze     # 必须0错误
flutter test       # 必须100%通过
flutter test --coverage  # 检查覆盖率
```

## 当前状态

### ✅ 已完成
- 核心架构 (lib/core/) 编译清洁
- TDD工作流程建立
- 分支 feature/tdd-restart 创建

### 🔄 进行中
- 建立预提交钩子
- 清理破损代码

### ⏳ 待完成
- 实施第一个TDD功能
- 建立CI/CD管道