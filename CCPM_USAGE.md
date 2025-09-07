CCPM 命令详细指南

  🚀 核心命令流程

  阶段1：项目初始化

  # 1. 安装CCPM系统
  curl -sSL https://raw.githubusercontent.com/automazeio/ccp
  m/main/ccpm.sh | bash

  # 2. 初始化项目
  /pm:init

  # 3. 重新初始化CLAUDE.md规则
  /re-init

  # 4. 创建项目上下文
  /context:create

  阶段2：需求分析到实现

  # 5. 解析PRD为技术史诗
  /pm:prd-parse <project-name>

  # 6. 史诗分解并同步GitHub
  /pm:epic-oneshot <project-name>

  # 7. 开始并发执行
  /pm:epic-start <project-name>

  📋 命令详细说明

  管理命令

  - /pm:init - 初始化CCPM系统，创建.claude目录结构
  - /re-init - 更新CLAUDE.md项目规则和开发标准
  - /context:create - 创建完整项目上下文文档（9个文件）
  - /context:update - 增量更新项目上下文（重大进展后使用）

  需求到代码

  - /pm:prd-parse <name> - 将PRD转换为技术实现计划
  - /pm:epic-oneshot <name> - 史诗分解+GitHub同步一键完成
  - /pm:epic-sync <name> - 手动同步史诗到GitHub Issues

  执行控制

  - /pm:epic-start <name> - 启动并发agents执行史诗
  - /pm:epic-status <name> - 查看执行状态和进度
  - /pm:epic-stop <name> - 停止所有运行中的agents
  - /pm:epic-merge <name> - 完成后合并分支到main

  🔄 常见使用场景

  场景1：新项目启动

  1. /pm:init                    # 系统初始化
  2. /re-init                    # 规则配置  
  3. /context:create            # 基础上下文
  4. /pm:prd-parse whatsapp-clone    # PRD解析
  5. /pm:epic-oneshot whatsapp-clone # 一键分解
  6. /pm:epic-start whatsapp-clone   # 开始执行

  场景2：项目中期检查

  /pm:epic-status whatsapp-clone     # 查看进度
  /context:update                    # 更新上下文

  场景3：执行完成

  /pm:epic-status whatsapp-clone     # 确认完成状态
  /pm:epic-merge whatsapp-clone      # 合并到main分支

  ⚠️ Usage Limit中断恢复

  最常见问题：agents被中断

  识别中断：
  - 看到类似"Usage limit reached"或内存错误
  - agents突然停止响应
  - 执行状态显示"paused"或"incomplete"

  恢复步骤：

  1. 检查当前状态
  /pm:epic-status whatsapp-clone

  2. 重新启动执行
  /pm:epic-start whatsapp-clone
  系统会自动：
  - 检测已完成的任务
  - 跳过已完成的工作
  - 继续未完成的agents
  - 启动准备好的新任务

  3. 如果仍有问题，分阶段恢复
  # 先停止所有agents
  /pm:epic-stop whatsapp-clone

  # 等待2-3分钟让系统清理资源

  # 重新启动
  /pm:epic-start whatsapp-clone

  内存不足的处理

  当前情况处理：
  # 1. 关闭其他应用释放内存
  # 2. 增加Node.js内存限制
  export NODE_OPTIONS="--max-old-space-size=8192"

  # 3. 重启执行（系统会从中断点继续）
  /pm:epic-start whatsapp-clone

  🎯 最佳实践

  监控策略

  # 每30分钟检查一次进度
  /pm:epic-status whatsapp-clone

  # 重大进展后更新上下文
  /context:update

  资源管理

  - 内存监控：定期检查系统内存使用
  - 并发控制：避免同时运行多个史诗
  - 分批执行：大型史诗分阶段进行

  中断恢复技巧

  - 立即重启：中断后马上运行/pm:epic-start
  - 状态确认：用/pm:epic-status确认恢复情况
  - 耐心等待：agents重启需要1-2分钟初始化时间

  💡 Ultra Think 模式

  启用方式：
  # 在需要深度规划时使用opus模型
  /pm:prd-parse whatsapp-clone --model opus --ultra-think

  适用场景：
  - 复杂架构设计
  - 技术栈选择
  - 性能优化规划
  - 问题诊断分析

  ---
  针对你当前情况：
  1. 关闭其他程序释放内存 ✅
  2. 运行 export NODE_OPTIONS="--max-old-space-size=8192"
  3. 重新启动 /pm:epic-start whatsapp-clone

  系统会自动检测已完成的Issue #6，继续执行Issue
  #9（基础设施部署）。

  需要我继续启动Infrastructure Deployment agent吗？



  根据CCPM工作流程，测试覆盖率实施完成后，接下来的标准流程是
  ：

  🔍 Phase 4: 验证 (Verification)

  让我检查当前项目状态并启动验证流程：

⏺ 是的！根据CCPM流程，接下来确实是验证阶段。

  CCPM 验证流程：

  1. 🧪 运行完整测试套件验证 - 确保所有测试通过
  2. 🏗️ 验证构建流程 - 确保项目可以正确构建
  3. 📊 检查代码质量指标 - lint、格式化、类型检查
  4. ✅ 验证功能完整性 - 确认所有需求都已实现
  5. 📋 生成验证报告 - 为后续部署/交付准备文档

  让我开始第一步 - 运行完整测试套件验证：



  CCPM完整工作流程

  阶段1: 💡 头脑风暴 (Brainstorm)

  - 分析需求和目标
  - 识别关键功能模块
  - 评估技术栈和架构选择
  - 制定初步实施策略

  阶段2: 📋 文档化 (Document)

  - 创建PRD (产品需求文档)
  - 定义技术规范和API设计
  - 建立项目结构和约定
  - 记录决策依据和权衡

  阶段3: 🎯 计划 (Plan)

  - 分解任务为可执行的里程碑
  - 评估工作量和时间线
  - 识别风险和依赖关系
  - 制定并行执行策略

  阶段4: ⚡ 执行 (Execute)

  - 使用并行代理执行任务
  - 实施核心功能和特性
  - 进行代码审查和测试
  - 持续集成和部署

  阶段5: ✅ 验证 (Verify)

  - 运行全面的测试套件
  - 验证功能完整性和性能
  - 修复发现的问题和缺陷
  - 确保代码质量标准

  阶段6: 📈 跟踪 (Track)

  - 监控项目进展和健康状态
  - 收集性能指标和用户反馈
  - 规划下一轮迭代
  - 持续优化和维护