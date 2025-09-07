# Epic: 代码质量和测试套件重构

## Overview
系统性修复472个分析器错误，重构测试套件以适配更新的实体属性，提升代码质量和可维护性。

## Epic Scope
- 修复所有Message实体属性名不一致问题
- 重构测试文件以使用正确的属性名  
- 确保完整聊天功能可以激活
- 实现0分析器错误的代码质量目标

## Tasks

### Task 1: 错误分析和分类
- **Goal**: 分析472个分析器错误的分布和类型
- **Acceptance Criteria**: 
  - 生成错误分析报告
  - 按模块和文件分组错误
  - 制定修复优先级
- **Estimated Hours**: 1

### Task 2: 实体层属性标准化  
- **Goal**: 统一Message及相关实体的属性命名
- **Acceptance Criteria**:
  - Message实体使用统一属性名(userId, type, createdAt)
  - 更新所有copyWith和工厂方法
  - 相关实体保持一致性
- **Estimated Hours**: 2

### Task 3: 核心服务层同步
- **Goal**: 更新Repository和Service实现以匹配新属性名
- **Acceptance Criteria**:
  - RealSupabaseMessageService属性映射正确
  - MockMessageService属性映射正确  
  - 数据库字段映射更新
- **Estimated Hours**: 1

### Task 4: 测试文件批量重构
- **Goal**: 修复所有测试文件中的属性引用错误
- **Acceptance Criteria**:
  - 所有Message相关测试使用新属性名
  - 修复构造函数参数错误
  - 测试逻辑保持正确性
- **Estimated Hours**: 3

### Task 5: 验证和质量检查
- **Goal**: 确保修复效果和代码质量
- **Acceptance Criteria**:
  - `flutter analyze` 输出0错误
  - `flutter test` 所有测试通过
  - 完整聊天功能可正常激活
- **Estimated Hours**: 1

## Definition of Done
- [ ] 472个分析器错误全部修复
- [ ] 所有测试通过
- [ ] 完整聊天功能可以激活使用
- [ ] 代码质量符合项目标准
- [ ] 文档更新完整

## Risk Mitigation
- 分阶段修复，每阶段运行测试验证
- 重点关注核心业务逻辑不被破坏
- 保持测试覆盖率不下降