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