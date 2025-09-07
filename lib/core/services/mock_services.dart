import 'dart:async';
import 'dart:math';

/// Mock services for local development environment
/// Provides fake implementations of external services like LiveKit
class MockServices {
  static final MockServices _instance = MockServices._internal();
  factory MockServices() => _instance;
  MockServices._internal();

  /// Initialize mock services
  static Future<void> initialize() async {
    print('🎭 Mock Services initialized for local development');
  }

  /// Mock LiveKit service
  static MockLiveKitService get liveKit => MockLiveKitService();

  /// Mock Firebase service  
  static MockFirebaseService get firebase => MockFirebaseService();
}

/// Mock LiveKit service for video/audio calls
class MockLiveKitService {
  final List<MockParticipant> _participants = [];
  final StreamController<List<MockParticipant>> _participantsController = 
      StreamController<List<MockParticipant>>.broadcast();

  /// Create a mock meeting room
  Future<MockRoom> createRoom(String roomName) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    return MockRoom(
      id: 'room_${DateTime.now().millisecondsSinceEpoch}',
      name: roomName,
      participants: [],
    );
  }

  /// Join a mock meeting room
  Future<void> joinRoom(String roomId, String participantName) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final participant = MockParticipant(
      id: 'participant_${DateTime.now().millisecondsSinceEpoch}',
      name: participantName,
      isAudioEnabled: true,
      isVideoEnabled: true,
      joinedAt: DateTime.now(),
    );
    
    _participants.add(participant);
    _participantsController.add(List.from(_participants));
    
    print('🎥 Mock: $participantName joined room $roomId');
  }

  /// Leave a mock meeting room
  Future<void> leaveRoom(String participantId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    _participants.removeWhere((p) => p.id == participantId);
    _participantsController.add(List.from(_participants));
    
    print('👋 Mock: Participant left room');
  }

  /// Toggle audio for mock participant
  Future<void> toggleAudio(String participantId) async {
    final participant = _participants.firstWhere((p) => p.id == participantId);
    participant.isAudioEnabled = !participant.isAudioEnabled;
    _participantsController.add(List.from(_participants));
    
    print('🎤 Mock: Audio ${participant.isAudioEnabled ? 'enabled' : 'disabled'}');
  }

  /// Toggle video for mock participant  
  Future<void> toggleVideo(String participantId) async {
    final participant = _participants.firstWhere((p) => p.id == participantId);
    participant.isVideoEnabled = !participant.isVideoEnabled;
    _participantsController.add(List.from(_participants));
    
    print('📹 Mock: Video ${participant.isVideoEnabled ? 'enabled' : 'disabled'}');
  }

  /// Get participants stream
  Stream<List<MockParticipant>> get participantsStream => _participantsController.stream;

  /// Add some fake participants for demo
  Future<void> addFakeParticipants() async {
    final fakeNames = ['Alice', 'Bob', 'Charlie', 'Diana', 'Eve'];
    final random = Random();
    
    for (int i = 0; i < random.nextInt(4) + 1; i++) {
      await Future.delayed(Duration(milliseconds: 500 * i));
      
      final participant = MockParticipant(
        id: 'fake_${DateTime.now().millisecondsSinceEpoch}_$i',
        name: fakeNames[random.nextInt(fakeNames.length)],
        isAudioEnabled: random.nextBool(),
        isVideoEnabled: random.nextBool(),
        joinedAt: DateTime.now().subtract(Duration(minutes: random.nextInt(30))),
      );
      
      _participants.add(participant);
      _participantsController.add(List.from(_participants));
    }
  }

  void dispose() {
    _participantsController.close();
  }
}

/// Mock Firebase service
class MockFirebaseService {
  /// Mock crash reporting
  Future<void> recordError(dynamic exception, StackTrace? stackTrace) async {
    print('🚨 Mock Crashlytics: Recorded error: $exception');
  }

  /// Mock analytics event
  Future<void> logEvent(String name, Map<String, dynamic>? parameters) async {
    print('📊 Mock Analytics: Event $name with params: $parameters');
  }

  /// Mock performance trace
  MockPerformanceTrace startTrace(String name) {
    return MockPerformanceTrace(name);
  }
}

/// Mock performance trace
class MockPerformanceTrace {
  final String name;
  final DateTime startTime;

  MockPerformanceTrace(this.name) : startTime = DateTime.now();

  void stop() {
    final duration = DateTime.now().difference(startTime);
    print('⏱️ Mock Performance: Trace "$name" took ${duration.inMilliseconds}ms');
  }
}

/// Mock room data class
class MockRoom {
  final String id;
  final String name;
  final List<MockParticipant> participants;
  final DateTime createdAt;

  MockRoom({
    required this.id,
    required this.name,
    required this.participants,
  }) : createdAt = DateTime.now();
}

/// Mock participant data class
class MockParticipant {
  final String id;
  final String name;
  bool isAudioEnabled;
  bool isVideoEnabled;
  final DateTime joinedAt;

  MockParticipant({
    required this.id,
    required this.name,
    required this.isAudioEnabled,
    required this.isVideoEnabled,
    required this.joinedAt,
  });
}

/// Mock Supabase service
class MockSupabaseService {
  static final MockSupabaseService _instance = MockSupabaseService._internal();
  factory MockSupabaseService() => _instance;
  MockSupabaseService._internal();

  final List<MockMessage> _messages = [];
  final List<MockUser> _users = [];
  final StreamController<List<MockMessage>> _messagesController = 
      StreamController<List<MockMessage>>.broadcast();

  /// Initialize with fake data
  Future<void> initialize() async {
    print('📡 Mock Supabase initialized');
    
    // Add some fake users
    _users.addAll([
      MockUser(id: '1', name: 'Alice Chen', email: 'alice@example.com'),
      MockUser(id: '2', name: 'Bob Wang', email: 'bob@example.com'),
      MockUser(id: '3', name: 'Charlie Li', email: 'charlie@example.com'),
    ]);
    
    // Add some fake messages
    await _addFakeMessages();
  }

  /// Mock authentication
  Future<MockUser?> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (email.contains('@') && password.length >= 6) {
      final user = MockUser(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: email.split('@')[0],
        email: email,
      );
      print('✅ Mock Auth: Signed in as $email');
      return user;
    } else {
      print('❌ Mock Auth: Invalid credentials');
      throw Exception('Invalid credentials');
    }
  }

  /// Mock message sending
  Future<void> sendMessage(String content, String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final user = _users.firstWhere((u) => u.id == userId, orElse: () => 
      MockUser(id: userId, name: 'User $userId', email: '$userId@example.com'));
    
    final message = MockMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      senderId: userId,
      senderName: user.name,
      timestamp: DateTime.now(),
    );
    
    _messages.add(message);
    _messagesController.add(List.from(_messages));
    
    print('💬 Mock: Message sent by ${user.name}');
  }

  /// Get messages stream
  Stream<List<MockMessage>> get messagesStream => _messagesController.stream;

  /// Get current messages
  List<MockMessage> get messages => List.from(_messages);

  Future<void> _addFakeMessages() async {
    final fakeMessages = [
      'Hello everyone! 👋',
      'How is everyone doing today?',
      'Looking forward to our meeting',
      'The new features look great!',
      'Thanks for the update 🙏',
    ];

    for (int i = 0; i < fakeMessages.length; i++) {
      await Future.delayed(Duration(milliseconds: 100 * i));
      
      final user = _users[i % _users.length];
      final message = MockMessage(
        id: 'fake_$i',
        content: fakeMessages[i],
        senderId: user.id,
        senderName: user.name,
        timestamp: DateTime.now().subtract(Duration(minutes: 30 - (i * 5))),
      );
      
      _messages.add(message);
    }
    
    _messagesController.add(List.from(_messages));
  }

  void dispose() {
    _messagesController.close();
  }
}

/// Mock user data class
class MockUser {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  MockUser({
    required this.id,
    required this.name,
    required this.email,
  }) : createdAt = DateTime.now();
}

/// Mock message data class
class MockMessage {
  final String id;
  final String content;
  final String senderId;
  final String senderName;
  final DateTime timestamp;

  MockMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
  });
}