---
created: 2025-09-05T13:56:24Z
last_updated: 2025-09-05T13:56:24Z
version: 1.0
author: Claude Code PM System
---

# System Patterns & Architecture

## Primary Architectural Patterns

### Clean Architecture Implementation

The project follows Clean Architecture principles with strict layer separation:

```
┌─────────────────────────────────────────────────┐
│                 Presentation                     │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────┐ │
│  │   Pages     │  │ Controllers │  │  Widgets │ │
│  │ (Screens)   │  │ (Riverpod)  │  │   (UI)   │ │
│  └─────────────┘  └─────────────┘  └──────────┘ │
└─────────────────────────────────────────────────┘
                        │
┌─────────────────────────────────────────────────┐
│                   Domain                        │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────┐ │
│  │  Entities   │  │  Use Cases  │  │Repository│ │
│  │ (Models)    │  │(Business)   │  │Contracts │ │
│  └─────────────┘  └─────────────┘  └──────────┘ │
└─────────────────────────────────────────────────┘
                        │
┌─────────────────────────────────────────────────┐
│                    Data                         │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────┐ │
│  │ Repository  │  │ Data Sources│  │  Models  │ │
│  │Implementations│ │(API/Local)  │  │  (DTOs)  │ │
│  └─────────────┘  └─────────────┘  └──────────┘ │
└─────────────────────────────────────────────────┘
```

### State Management Pattern (Riverpod)

**Provider Architecture:**
```dart
// Data Layer Provider
@riverpod
ChatRepository chatRepository(ChatRepositoryRef ref) {
  return SupabaseChatRepository(ref.read(supabaseProvider));
}

// Domain Layer Provider  
@riverpod
class ChatNotifier extends _$ChatNotifier {
  @override
  Future<List<Message>> build(String roomId) async {
    return ref.read(chatRepositoryProvider).getMessages(roomId);
  }
  
  Future<void> sendMessage(String content) async {
    // Business logic implementation
  }
}

// Presentation Layer Consumer
Consumer(
  builder: (context, ref, child) {
    final chatState = ref.watch(chatNotifierProvider(roomId));
    return chatState.when(
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error),
      data: (messages) => MessageList(messages),
    );
  },
)
```

### Repository Pattern Implementation

**Abstract Repository (Domain Layer):**
```dart
abstract class ChatRepository {
  Stream<List<Message>> watchMessages(String roomId);
  Future<Either<Failure, void>> sendMessage(Message message);
  Future<Either<Failure, List<Room>>> getUserRooms();
}
```

**Concrete Implementation (Data Layer):**
```dart
class SupabaseChatRepository implements ChatRepository {
  final SupabaseClient _client;
  
  @override
  Stream<List<Message>> watchMessages(String roomId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .map((data) => data.map((json) => Message.fromJson(json)).toList());
  }
}
```

## Design Patterns

### Factory Pattern (Service Initialization)

**Service Factory for LiveKit Integration:**
```dart
class MeetingServiceFactory {
  static IMeetingService create(MeetingConfig config) {
    switch (config.provider) {
      case MeetingProvider.livekit:
        return LiveKitMeetingService(config.livekitConfig);
      case MeetingProvider.mock:
        return MockMeetingService();
      default:
        throw UnsupportedError('Provider not supported');
    }
  }
}
```

### Observer Pattern (Real-time Updates)

**Supabase Real-time Integration:**
```dart
class RealtimeMessageObserver {
  late final RealtimeChannel _channel;
  final StreamController<Message> _messageController = StreamController();

  Stream<Message> get messageStream => _messageController.stream;

  void listen(String roomId) {
    _channel = supabase
        .channel('messages:$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(column: 'room_id', value: roomId),
          callback: (payload) {
            final message = Message.fromJson(payload.newRecord);
            _messageController.add(message);
          },
        )
        .subscribe();
  }
}
```

### Strategy Pattern (Meeting Features)

**Meeting Strategy Implementation:**
```dart
abstract class MeetingStrategy {
  Future<void> joinMeeting(String roomId);
  Future<void> leaveMeeting();
  Future<void> toggleCamera();
  Future<void> toggleMicrophone();
}

class LiveKitMeetingStrategy implements MeetingStrategy {
  final Room _room = Room();
  
  @override
  Future<void> joinMeeting(String roomId) async {
    await _room.connect(serverUrl, token);
    await _room.localParticipant?.setCameraEnabled(true);
  }
}

class MockMeetingStrategy implements MeetingStrategy {
  @override
  Future<void> joinMeeting(String roomId) async {
    // Mock implementation for testing
  }
}
```

## Data Flow Patterns

### Unidirectional Data Flow

```
User Action → Controller → Use Case → Repository → External Service
     ↓                                                    ↓
UI Update ← Riverpod State ← Domain Entity ← Data Model ← API Response
```

### Event-Driven Architecture

**Message Flow Pattern:**
```dart
// Event Definition
abstract class ChatEvent {}
class MessageSent extends ChatEvent {
  final Message message;
  MessageSent(this.message);
}

// Event Bus Implementation
class EventBus {
  static final StreamController<ChatEvent> _controller = StreamController.broadcast();
  
  static void emit(ChatEvent event) => _controller.add(event);
  static Stream<T> on<T extends ChatEvent>() => 
      _controller.stream.where((event) => event is T).cast<T>();
}

// Usage in Controllers
class ChatController {
  void sendMessage(String content) {
    final message = Message(content: content);
    repository.sendMessage(message);
    EventBus.emit(MessageSent(message));
  }
}
```

## Error Handling Patterns

### Either Pattern (Functional Error Handling)

```dart
// Error Types
abstract class Failure {
  final String message;
  Failure(this.message);
}

class NetworkFailure extends Failure {
  NetworkFailure(String message) : super(message);
}

// Repository Implementation
Future<Either<Failure, List<Message>>> getMessages(String roomId) async {
  try {
    final response = await _client.from('messages').select().eq('room_id', roomId);
    final messages = response.map((json) => Message.fromJson(json)).toList();
    return Right(messages);
  } catch (e) {
    return Left(NetworkFailure('Failed to fetch messages: $e'));
  }
}

// Controller Usage
Future<void> loadMessages() async {
  final result = await repository.getMessages(roomId);
  result.fold(
    (failure) => state = AsyncError(failure, StackTrace.current),
    (messages) => state = AsyncData(messages),
  );
}
```

### Resilience Patterns

**Circuit Breaker for External Services:**
```dart
class CircuitBreaker {
  static const int _failureThreshold = 5;
  static const Duration _timeout = Duration(minutes: 1);
  
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  CircuitState _state = CircuitState.closed;

  Future<T> execute<T>(Future<T> Function() operation) async {
    if (_state == CircuitState.open) {
      if (_shouldAttemptReset()) {
        _state = CircuitState.halfOpen;
      } else {
        throw CircuitBreakerOpenException();
      }
    }

    try {
      final result = await operation();
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure();
      rethrow;
    }
  }
}
```

## Testing Patterns

### Test Double Patterns

**Repository Mocking:**
```dart
class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  group('ChatController Tests', () {
    late MockChatRepository mockRepository;
    late ChatController controller;

    setUp(() {
      mockRepository = MockChatRepository();
      controller = ChatController(mockRepository);
    });

    test('should send message successfully', () async {
      // Arrange
      when(() => mockRepository.sendMessage(any()))
          .thenAnswer((_) async => Right(null));

      // Act
      await controller.sendMessage('Hello World');

      // Assert
      verify(() => mockRepository.sendMessage(any())).called(1);
    });
  });
}
```

### Integration Test Patterns

**End-to-End Test Flow:**
```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Chat Integration Tests', () {
    testWidgets('complete chat flow', (tester) async {
      // Setup test environment
      await tester.pumpWidget(TestApp());
      
      // Login flow
      await tester.enterText(find.byKey(Key('email')), 'test@example.com');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();
      
      // Navigate to chat
      await tester.tap(find.text('Start Chat'));
      await tester.pumpAndSettle();
      
      // Send message
      await tester.enterText(find.byKey(Key('message_input')), 'Test message');
      await tester.tap(find.byKey(Key('send_button')));
      await tester.pumpAndSettle();
      
      // Verify message appears
      expect(find.text('Test message'), findsOneWidget);
    });
  });
}
```

## Performance Patterns

### Lazy Loading Pattern

```dart
@riverpod
class MessagePagination extends _$MessagePagination {
  static const int _pageSize = 20;
  
  @override
  Future<List<Message>> build(String roomId) async {
    return _loadPage(0);
  }
  
  Future<void> loadMore() async {
    final currentMessages = state.value ?? [];
    final nextPage = currentMessages.length ~/ _pageSize;
    final newMessages = await _loadPage(nextPage);
    
    state = AsyncData([...currentMessages, ...newMessages]);
  }
  
  Future<List<Message>> _loadPage(int page) async {
    return repository.getMessages(
      roomId: roomId,
      offset: page * _pageSize,
      limit: _pageSize,
    );
  }
}
```

### Caching Pattern

```dart
class MessageCache {
  final Map<String, List<Message>> _cache = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  List<Message>? getCachedMessages(String roomId) {
    return _cache[roomId];
  }
  
  void cacheMessages(String roomId, List<Message> messages) {
    _cache[roomId] = messages;
    
    // Auto-cleanup after expiry
    Timer(_cacheExpiry, () => _cache.remove(roomId));
  }
}
```

## Security Patterns

### Authentication Guard Pattern

```dart
class AuthGuard {
  static bool canAccess(BuildContext context, String route) {
    final user = context.read(authProvider);
    return user != null && user.isAuthenticated;
  }
}

// Router integration
GoRoute(
  path: '/chat',
  builder: (context, state) {
    if (!AuthGuard.canAccess(context, '/chat')) {
      return LoginPage();
    }
    return ChatPage();
  },
)
```

These patterns ensure consistent, maintainable, and testable code throughout the application while supporting the real-time, meeting-focused requirements of the WhatsApp clone.