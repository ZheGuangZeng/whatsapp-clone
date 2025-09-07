import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/theme/app_theme.dart';
import 'core/config/environment_config.dart';
import 'core/providers/service_factory.dart';
import 'core/providers/service_providers.dart';
import 'core/services/mock_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize environment configuration
  EnvironmentConfig.initialize(environment: Environment.development);
  
  final config = EnvironmentConfig.config;
  
  print('🚀 Starting WhatsApp Clone in LOCAL DEV mode');
  print('🔧 Environment: ${config.environment}');
  print('🎭 Service Mode: ${config.serviceMode}');
  
  // Validate services before starting the app
  final validationResult = await ServiceFactory.validateServices(config);
  
  if (validationResult.isValid) {
    print('✅ Service validation passed');
    if (validationResult.hasWarnings) {
      print('⚠️  Validation warnings:');
      for (final warning in validationResult.warnings) {
        print('   - $warning');
      }
    }
  } else {
    print('❌ Service validation failed');
    for (final error in validationResult.errors) {
      print('   - $error');
    }
  }
  
  // Initialize services based on configuration
  if (config.isMockMode) {
    await MockServices.initialize();
    await MockSupabaseService().initialize();
    print('🎭 Mock services initialized');
  } else {
    print('🔗 Real services will be initialized on demand');
  }
  
  runApp(
    ProviderScope(
      child: WhatsAppCloneLocalApp(validationResult: validationResult),
    ),
  );
}

class WhatsAppCloneLocalApp extends ConsumerWidget {
  const WhatsAppCloneLocalApp({
    super.key,
    required this.validationResult,
  });
  
  final ServiceValidationResult validationResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceStatus = ref.watch(serviceConfigStatusProvider);
    
    return MaterialApp(
      title: 'WhatsApp Clone - Local Dev (${serviceStatus.serviceModeDisplayName})',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: LocalDevHomePage(serviceStatus: serviceStatus, validationResult: validationResult),
    );
  }
}

class LocalDevHomePage extends StatefulWidget {
  const LocalDevHomePage({
    super.key,
    required this.serviceStatus,
    required this.validationResult,
  });
  
  final ServiceConfigStatus serviceStatus;
  final ServiceValidationResult validationResult;

  @override
  State<LocalDevHomePage> createState() => _LocalDevHomePageState();
}

class _LocalDevHomePageState extends State<LocalDevHomePage> {
  int _selectedIndex = 0;
  MockUser? _currentUser;

  late final _pages = [
    DevTestOverviewPage(
      serviceStatus: widget.serviceStatus,
      validationResult: widget.validationResult,
    ),
    const MockMessagingPage(),
    const MockMeetingPage(),
    DevToolsPage(serviceStatus: widget.serviceStatus),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Clone - Local Dev'),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
        actions: [
          if (_currentUser != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                avatar: const Icon(Icons.person, size: 16),
                label: Text(_currentUser!.name),
                backgroundColor: Colors.white.withOpacity(0.2),
                labelStyle: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF075E54),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '概览',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: '消息',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_call),
            label: '会议',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '工具',
          ),
        ],
      ),
    );
  }
}

// Overview Page
class DevTestOverviewPage extends StatelessWidget {
  const DevTestOverviewPage({
    super.key,
    required this.serviceStatus,
    required this.validationResult,
  });
  
  final ServiceConfigStatus serviceStatus;
  final ServiceValidationResult validationResult;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 32),
                      SizedBox(width: 12),
                      Text(
                        'Production-Ready Epic Complete',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _TaskStatusTile(task: 'Task 21: Code Quality Excellence', isComplete: true),
                  _TaskStatusTile(task: 'Task 22: Performance Optimization', isComplete: true),
                  _TaskStatusTile(task: 'Task 23: CI/CD Pipeline Complete', isComplete: true),
                  _TaskStatusTile(task: 'Task 24: Production Infrastructure', isComplete: true),
                  _TaskStatusTile(task: 'Task 25: Monitoring & Observability', isComplete: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '服务环境状态 (${serviceStatus.environmentDisplayName})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _ServiceStatusTile(
                    service: 'Service Mode',
                    status: serviceStatus.serviceModeDisplayName,
                    icon: serviceStatus.serviceMode == ServiceMode.mock 
                        ? Icons.theater_comedy 
                        : Icons.cloud,
                    color: serviceStatus.serviceMode == ServiceMode.mock 
                        ? Colors.blue 
                        : Colors.green,
                  ),
                  _ServiceStatusTile(
                    service: 'Validation Status',
                    status: serviceStatus.isValid ? 'Valid' : 'Invalid',
                    icon: serviceStatus.isValid ? Icons.check_circle : Icons.error,
                    color: serviceStatus.isValid 
                        ? (serviceStatus.hasWarnings ? Colors.orange : Colors.green)
                        : Colors.red,
                  ),
                  if (serviceStatus.serviceMode == ServiceMode.mock) ...[
                    _ServiceStatusTile(
                      service: 'Mock Supabase',
                      status: 'Running',
                      icon: Icons.cloud_done,
                      color: Colors.green,
                    ),
                    _ServiceStatusTile(
                      service: 'Mock LiveKit',
                      status: 'Ready',
                      icon: Icons.videocam,
                      color: Colors.blue,
                    ),
                    _ServiceStatusTile(
                      service: 'Mock Analytics',
                      status: 'Disabled',
                      icon: Icons.analytics,
                      color: Colors.orange,
                    ),
                  ] else ...[
                    _ServiceStatusTile(
                      service: 'Real Supabase',
                      status: 'Connected',
                      icon: Icons.cloud_done,
                      color: Colors.green,
                    ),
                    _ServiceStatusTile(
                      service: 'Real LiveKit',
                      status: 'Ready',
                      icon: Icons.videocam,
                      color: Colors.green,
                    ),
                    _ServiceStatusTile(
                      service: 'Real Analytics',
                      status: 'Enabled',
                      icon: Icons.analytics,
                      color: Colors.green,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('启动本地Supabase'),
                    content: const Text(
                      '要启动完整的本地开发环境，请运行：\n\n'
                      'docker-compose -f docker-compose.local.yml up -d\n\n'
                      '然后访问 http://localhost:3000 查看Supabase Studio',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('了解'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.rocket_launch),
              label: const Text('启动完整本地环境'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF075E54),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Mock Messaging Page
class MockMessagingPage extends StatefulWidget {
  const MockMessagingPage({super.key});

  @override
  State<MockMessagingPage> createState() => _MockMessagingPageState();
}

class _MockMessagingPageState extends State<MockMessagingPage> {
  final TextEditingController _messageController = TextEditingController();
  final MockSupabaseService _mockSupabase = MockSupabaseService();
  MockUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = MockUser(id: '999', name: 'Local Dev User', email: 'dev@local.com');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF075E54),
          child: const Row(
            children: [
              Icon(Icons.chat, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Mock 消息测试',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<MockMessage>>(
            stream: _mockSupabase.messagesStream,
            initialData: _mockSupabase.messages,
            builder: (context, snapshot) {
              final messages = snapshot.data ?? [];
              
              if (messages.isEmpty) {
                return const Center(
                  child: Text('没有消息。发送第一条消息开始测试！'),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isMe = message.senderId == _currentUser?.id;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFF075E54) : Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Text(
                                  message.senderName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF075E54),
                                  ),
                                ),
                              Text(
                                message.content,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe ? Colors.white70 : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: '输入消息...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () async {
                  if (_messageController.text.trim().isNotEmpty && _currentUser != null) {
                    await _mockSupabase.sendMessage(_messageController.text.trim(), _currentUser!.id);
                    _messageController.clear();
                  }
                },
                icon: const Icon(Icons.send),
                color: const Color(0xFF075E54),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Mock Meeting Page
class MockMeetingPage extends StatefulWidget {
  const MockMeetingPage({super.key});

  @override
  State<MockMeetingPage> createState() => _MockMeetingPageState();
}

class _MockMeetingPageState extends State<MockMeetingPage> {
  final MockLiveKitService _mockLiveKit = MockServices.liveKit;
  MockRoom? _currentRoom;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mock 会议测试',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final room = await _mockLiveKit.createRoom('Test Room');
                        setState(() => _currentRoom = room);
                        await _mockLiveKit.joinRoom(room.id, 'Local Dev User');
                        await _mockLiveKit.addFakeParticipants();
                      },
                      icon: const Icon(Icons.video_call),
                      label: const Text('创建测试会议'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF075E54),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  if (_currentRoom != null) ...[
                    const SizedBox(height: 16),
                    Text('房间: ${_currentRoom!.name}'),
                    Text('ID: ${_currentRoom!.id}'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<MockParticipant>>(
            stream: _mockLiveKit.participantsStream,
            builder: (context, snapshot) {
              final participants = snapshot.data ?? [];
              
              if (participants.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('没有活跃的参与者'),
                  ),
                );
              }
              
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '参与者 (${participants.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...participants.map((participant) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              child: Text(participant.name[0]),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(participant.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('加入时间: ${participant.joinedAt.hour}:${participant.joinedAt.minute.toString().padLeft(2, '0')}'),
                                ],
                              ),
                            ),
                            Icon(
                              participant.isAudioEnabled ? Icons.mic : Icons.mic_off,
                              color: participant.isAudioEnabled ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              participant.isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                              color: participant.isVideoEnabled ? Colors.green : Colors.red,
                              size: 16,
                            ),
                          ],
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Dev Tools Page
class DevToolsPage extends StatelessWidget {
  const DevToolsPage({
    super.key,
    required this.serviceStatus,
  });
  
  final ServiceConfigStatus serviceStatus;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '开发工具',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('启动本地Supabase'),
              subtitle: const Text('docker-compose -f docker-compose.local.yml up -d'),
              trailing: const Icon(Icons.launch),
              onTap: () {
                // Could implement actual Docker commands here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请在终端中运行Docker命令')),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.web),
              title: const Text('打开Supabase Studio'),
              subtitle: const Text('http://localhost:3000'),
              trailing: const Icon(Icons.launch),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请在浏览器中打开 http://localhost:3000')),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('测试错误报告'),
              subtitle: const Text('触发Mock错误以测试监控系统'),
              trailing: const Icon(Icons.warning),
              onTap: () {
                MockServices.firebase.recordError('Test error for development', StackTrace.current);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mock错误已记录')),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('测试分析事件'),
              subtitle: const Text('发送测试分析事件'),
              trailing: const Icon(Icons.trending_up),
              onTap: () {
                MockServices.firebase.logEvent('test_event', {
                  'screen': 'dev_tools',
                  'timestamp': DateTime.now().toIso8601String(),
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('分析事件已发送')),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '环境信息',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text('Environment: ${serviceStatus.environmentDisplayName}'),
                  Text('Service Mode: ${serviceStatus.serviceModeDisplayName}'),
                  if (serviceStatus.serviceMode == ServiceMode.mock) ...[
                    const Text('Database: In-memory Mock data'),
                    const Text('Authentication: Mock authentication (bypass)'),
                    const Text('Monitoring: Mock monitoring services'),
                  ] else ...[
                    const Text('Database: Real Supabase connection'),
                    const Text('Authentication: Real Supabase auth'),
                    const Text('Monitoring: Real monitoring services'),
                  ],
                  Text('Validation: ${serviceStatus.isValid ? "✅ Passed" : "❌ Failed"}'),
                  if (serviceStatus.hasWarnings) 
                    const Text('Warnings: ⚠️ Check startup logs'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper Widgets
class _TaskStatusTile extends StatelessWidget {
  final String task;
  final bool isComplete;

  const _TaskStatusTile({
    required this.task,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isComplete ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(task)),
        ],
      ),
    );
  }
}

class _ServiceStatusTile extends StatelessWidget {
  final String service;
  final String status;
  final IconData icon;
  final Color color;

  const _ServiceStatusTile({
    required this.service,
    required this.status,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(service)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}