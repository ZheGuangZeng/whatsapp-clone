#
git clone https://github.com/automazeio/ccpm.git . && rm -rf .git

#
采用 https://github.com/automazeio/ccpm.git claude code ccpm 来开发 canvas whatsapp clone，该如何开始呢？
可以联网查找最新的资料？
最佳实践是什么？
技术栈采用 flutter 和 supabase 是否合适？
flutter state management, 采用 riverpod 还是 bloc, 哪个更合适?
supabase 需要先 supabase local dev 测试通过，然后 supabase cloud 测试通过，最后， supbase self-host 测试通过？ 
采用 livekit 开发 视频或者语音聊天 和 视频或者语音会议 功能？
livekit 也 需要先 livekit local dev 测试通过，然后 livekit cloud 测试通过，最后， livekit self-host 测试通过？ 
聊天功能，采用 supabase 是否合适？
group 和 community 功能也需要
ccpm epic 开发的时候，需要采用 TDD 的方式？
并且需要保证测试通过？
为我生成一步步操作指南, 保存到 markdown ?
ccpm 设置需要采用 官方推荐方式？
规划的时候，采用 opus 模型，并且 ultra think?



🎯 会议功能深度需求

  既然会议功能是高优先级，我需要了解更多细节：

  会议类型和规模

  1. 会议规模：
    - 大型会议为主：50-100人

  2. 会议类型：
    - 语音会议 vs 视频会议 （为主）
    - 屏幕分享需求
    - 录制功能需要
  3. 会议发起方式：
    - 从群组直接发起
    - 预约会议
    - 随时加入的会议室
    都需要

  会议功能特性

  1. 核心功能：
    - 静音/取消静音
    - 摄像头开关
    - 参会者管理
    - 会议邀请链接
  2. 高级功能：
    - 主持人权限
    - 举手发言
    - 分组讨论（Breakout rooms）
    - 会议白板
    都需要


  🌏 中文市场特定需求

  本地化考虑

  1. 语言：简体中文为主，需要繁体吗？
  2. 文化特性：
    - 红包功能？
    - 表情包文化？
    - 语音转文字（中文识别）？
    优先级放最低
  3. 社交习惯：
    - 群组@功能
    - 群公告
    - 群投票
    - 群相册
    优先级往后放


     📱 具体产品定位问题

  1. 竞争对手对标：
    - 更像微信（全功能社交平台）？
    - 更像钉钉（企业协作+会议）？
    - 更像 Discord（社区+语音频道）？
    - 还是独特定位？
    更像 whatsapp 为主，完善 类似 zoom 会议功能。
  2. 使用场景排序（1-5，1最重要）：
    - ( 5 ) 家庭群聊
    - ( 4 ) 朋友聊天
    - ( 3 ) 工作团队协作
    - ( 2 ) 在线会议/远程办公
    - ( 1 ) 兴趣社区讨论
  3. 目标用户年龄段：
    - 学生群体（18-25）？
    - 职场人士（25-40）？
    - 全年龄段？
    全年龄段

      🏗️ 技术约束确认

  1. 会议技术选择：确认使用 LiveKit？还是考虑其他方案？
  如果没有其他合适的，就采用 livekit
  2. 服务器部署：主要在中国大陆部署？
  虽然用户是中国为主，但是服务器不能部署在中国大陆，可能部署在 日本，新加坡
  3. 用户规模预期：第一年目标多少用户？
  1万+


#
技术提醒我 使用 /context 命令？


  🔄 Next Steps:

  1. Use /context:prime to load context in new sessions
  2. Run /pm:prd-parse whatsapp-clone to create technical epic
  3. Initialize git repository for version control
  4. Set up Flutter project with dependencies

  💡 Tip:

  Run /context:update regularly to keep context current as the
  project evolves.

  The comprehensive context documentation is now established,
  providing a complete foundation for all future development
  decisions and maintaining consistency across the entire project
   lifecycle! 🚀