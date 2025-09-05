---
created: 2025-09-05T13:56:24Z
last_updated: 2025-09-05T13:56:24Z
version: 1.0
author: Claude Code PM System
---

# Project Style Guide

## Code Style & Conventions

### Dart/Flutter Code Standards

#### File Naming
- **Snake case for files**: `user_profile.dart`, `meeting_service.dart`  
- **Feature prefix for clarity**: `auth_repository.dart`, `chat_controller.dart`
- **Layer suffix for architecture**: `_page.dart`, `_provider.dart`, `_test.dart`
- **Avoid abbreviations**: Use `authentication` not `auth` in file names when possible

#### Class Naming  
```dart
// Good: PascalCase for classes
class UserProfileController extends StateNotifier<UserProfile> {}
class ChatMessageRepository implements IChatMessageRepository {}
class MeetingRoomPage extends ConsumerWidget {}

// Good: Descriptive names that indicate purpose  
class LiveKitMeetingService implements IMeetingService {}
class SupabaseChatRepository implements IChatRepository {}

// Avoid: Generic or unclear names
class Manager {} // Too generic
class Helper {} // Unclear purpose  
class Utils {}  // Too broad
```

#### Variable and Method Naming
```dart
// Good: CamelCase for variables and methods
final String userName = 'john_doe';
final List<Message> unreadMessages = [];

void sendMessageToChat(String content) {}
Future<List<User>> fetchCommunityMembers() async {}

// Good: Boolean variables with is/has/can prefixes
bool isUserOnline = true;
bool hasUnreadMessages = false;  
bool canStartMeeting = false;

// Good: Private members with underscore prefix
String _privateApiKey = '';
void _internalMethod() {}
```

#### Constant Naming
```dart
// Good: SCREAMING_SNAKE_CASE for constants
const String API_BASE_URL = 'https://api.whatsapp-clone.com';
const int MAX_MESSAGE_LENGTH = 4096;
const Duration MEETING_TIMEOUT = Duration(minutes: 60);

// Good: Group related constants in classes
class AppConstants {
  static const int MAX_GROUP_SIZE = 500;
  static const int MEETING_PARTICIPANT_LIMIT = 100;
  static const String DEFAULT_AVATAR_URL = 'assets/images/default_avatar.png';
}
```

### Project Structure Patterns

#### Feature Module Organization
```
lib/features/{feature_name}/
├── data/
│   ├── models/          # JSON serialization models  
│   ├── repositories/    # Repository implementations
│   └── sources/         # API and local data sources
├── domain/
│   ├── entities/        # Business objects (pure Dart)
│   ├── repositories/    # Repository interfaces  
│   └── usecases/        # Business use cases
└── presentation/
    ├── controllers/     # Riverpod state management
    ├── pages/           # Full-screen widgets
    └── widgets/         # Feature-specific UI components
```

#### Import Organization
```dart
// Good: Import order and grouping
// 1. Dart core libraries
import 'dart:async';
import 'dart:convert';

// 2. Flutter framework
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. Third-party packages (alphabetical)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 4. Internal imports (relative paths)
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../domain/entities/message.dart';
```

### Riverpod State Management Patterns

#### Provider Naming and Structure
```dart
// Good: Descriptive provider names with Provider suffix
@riverpod
SupabaseClient supabaseClient(SupabaseClientRef ref) {
  return Supabase.instance.client;
}

@riverpod
class ChatMessagesNotifier extends _$ChatMessagesNotifier {
  @override
  Future<List<Message>> build(String roomId) async {
    return ref.read(chatRepositoryProvider).getMessages(roomId);
  }
  
  Future<void> sendMessage(String content) async {
    // Implementation
  }
}

// Usage: Clear, intention-revealing names
final messages = ref.watch(chatMessagesNotifierProvider(roomId));
```

#### Error Handling Pattern
```dart  
// Good: Consistent error handling with Either pattern
Future<Either<ChatFailure, void>> sendMessage(Message message) async {
  try {
    await _supabaseClient.from('messages').insert(message.toJson());
    return const Right(null);
  } on PostgrestException catch (e) {
    return Left(ChatFailure.database(e.message));
  } catch (e) {
    return Left(ChatFailure.unknown(e.toString()));
  }
}

// Controller usage
Future<void> handleSendMessage(String content) async {
  state = const AsyncLoading();
  
  final result = await _repository.sendMessage(Message(content: content));
  result.fold(
    (failure) => state = AsyncError(failure, StackTrace.current),
    (_) => state = const AsyncData(null),
  );
}
```

### UI/UX Conventions

#### Widget Composition Patterns
```dart
// Good: Small, focused widgets with clear responsibilities
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  
  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        // Implementation
      ),
    );
  }
}

// Good: Use composition over inheritance
class ChatPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const ChatAppBar(),
      body: const ChatMessageList(),
      bottomNavigationBar: const ChatInputBar(),
    );
  }
}
```

#### Theme and Styling Consistency
```dart
// Good: Centralized theme configuration
class AppTheme {
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFF44336);
  
  static ThemeData lightTheme = ThemeData(
    primarySwatch: MaterialColor(primaryBlue.value, _blueSwatch),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
    ),
    // Additional theme configuration
  );
}

// Usage in widgets
Container(
  decoration: BoxDecoration(
    color: Theme.of(context).primaryColor,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Text(
    message.content,
    style: Theme.of(context).textTheme.bodyMedium,
  ),
)
```

### Testing Conventions

#### Test File Organization  
```dart
// test/features/chat/presentation/chat_controller_test.dart
void main() {
  group('ChatController', () {
    late MockChatRepository mockRepository;
    late ChatController controller;

    setUp(() {
      mockRepository = MockChatRepository();
      controller = ChatController(mockRepository);
    });

    group('sendMessage', () {
      test('should send message successfully', () async {
        // Arrange
        const testMessage = 'Hello, World!';
        when(() => mockRepository.sendMessage(any()))
            .thenAnswer((_) async => const Right(null));

        // Act
        await controller.sendMessage(testMessage);

        // Assert
        verify(() => mockRepository.sendMessage(any())).called(1);
        expect(controller.state, isA<AsyncData>());
      });

      test('should handle send message failure', () async {
        // Test implementation
      });
    });
  });
}
```

#### Test Naming Conventions
```dart
// Good: Descriptive test names following "should_when" pattern
test('should return messages when repository call succeeds', () async {});
test('should throw ChatException when network fails', () async {});
test('should update UI state when new message arrives', () async {});

// Good: Widget test descriptions
testWidgets('displays loading indicator when messages are loading', (tester) async {});
testWidgets('shows error message when message loading fails', (tester) async {});
testWidgets('renders message list when messages load successfully', (tester) async {});
```

### Documentation Standards

#### Code Comments
```dart
/// Manages real-time chat functionality for group conversations.
/// 
/// This service handles message sending, receiving, and real-time synchronization
/// using Supabase Realtime. It maintains connection state and provides
/// error recovery for network interruptions.
class ChatService {
  /// Sends a message to the specified chat room.
  /// 
  /// [roomId] The unique identifier for the chat room
  /// [content] The message text content
  /// [type] The message type (text, image, file, etc.)
  /// 
  /// Returns [Right(null)] on success, [Left(ChatFailure)] on error.
  Future<Either<ChatFailure, void>> sendMessage({
    required String roomId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    // Implementation
  }
}
```

#### API Documentation  
```dart
// Good: Complete API documentation with examples
/// Represents a message in the chat system.
/// 
/// Example usage:
/// ```dart
/// final message = Message(
///   id: 'msg_123',
///   content: 'Hello, World!',
///   userId: 'user_456', 
///   roomId: 'room_789',
///   createdAt: DateTime.now(),
/// );
/// ```
class Message {
  /// Unique identifier for this message
  final String id;
  
  /// The text content of the message
  final String content;
  
  /// ID of the user who sent this message  
  final String userId;
  
  /// ID of the room this message belongs to
  final String roomId;
  
  /// Timestamp when the message was created
  final DateTime createdAt;
}
```

### Performance Guidelines

#### Efficient Widget Building
```dart
// Good: Use const constructors when possible  
const Icon(Icons.send, color: Colors.blue),

// Good: Extract expensive operations outside build method
class MessageList extends StatelessWidget {
  final List<Message> messages;
  
  // Pre-compute expensive operations
  late final List<Message> sortedMessages = 
      List.from(messages)..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: sortedMessages.length,
      itemBuilder: (context, index) => MessageBubble(
        message: sortedMessages[index],
      ),
    );
  }
}

// Good: Use keys for lists with dynamic content
ListView.builder(
  itemBuilder: (context, index) => MessageBubble(
    key: ValueKey(messages[index].id),
    message: messages[index],
  ),
)
```

#### Memory Management
```dart
// Good: Dispose of controllers and subscriptions
class ChatPageController extends StateNotifier<ChatState> {
  late final StreamSubscription _messageSubscription;
  
  @override
  void dispose() {
    _messageSubscription.cancel();
    super.dispose();
  }
}
```

### Security Best Practices

#### Data Sanitization
```dart
// Good: Sanitize user input
String sanitizeMessageContent(String content) {
  return content
      .trim()
      .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
      .substring(0, math.min(content.length, MAX_MESSAGE_LENGTH));
}

// Good: Validate data before processing
bool isValidRoomId(String roomId) {
  return roomId.isNotEmpty && 
         roomId.length <= 50 && 
         RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(roomId);
}
```

#### API Security  
```dart
// Good: Never expose sensitive data in logs
void logApiError(String operation, dynamic error) {
  // Good: Sanitize error information
  final sanitizedError = error.toString().replaceAll(
    RegExp(r'token=\w+'), 
    'token=***'
  );
  log('API Error in $operation: $sanitizedError');
}
```

This style guide ensures consistency, maintainability, and quality across the entire codebase while supporting the project's real-time, community-focused requirements.