import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/chat_message.dart';
import 'package:whatsapp_clone/features/chat/presentation/widgets/chat_message_widget.dart';
import 'package:whatsapp_clone/features/messaging/domain/entities/message.dart';

void main() {
  group('ChatMessageWidget', () {
    final testMessage = ChatMessage(
      id: 'message_1',
      senderId: 'user_1',
      content: 'Hello, this is a test message!',
      roomId: 'room_1',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      messageType: MessageType.text,
      isRead: true,
    );

    testWidgets('should display message content correctly', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageWidget(
              message: testMessage,
              isCurrentUser: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Hello, this is a test message!'), findsOneWidget);
      expect(find.text('5m ago'), findsOneWidget);
    });

    testWidgets('should display current user message with correct alignment', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageWidget(
              message: testMessage,
              isCurrentUser: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Hello, this is a test message!'), findsOneWidget);
      
      // Check that the message is aligned to the right (current user)
      final chatWidget = tester.widget<ChatMessageWidget>(
        find.byType(ChatMessageWidget)
      );
      expect(chatWidget.isCurrentUser, isTrue);
    });

    testWidgets('should display edited message indicator', (tester) async {
      // Arrange
      final editedMessage = testMessage.copyWith(
        editedAt: DateTime.now().subtract(const Duration(minutes: 2)),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageWidget(
              message: editedMessage,
              isCurrentUser: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('(edited)'), findsOneWidget);
    });

    testWidgets('should display deleted message indicator', (tester) async {
      // Arrange
      final deletedMessage = testMessage.copyWith(
        isDeleted: true,
        content: '[Deleted]',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageWidget(
              message: deletedMessage,
              isCurrentUser: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('[Deleted]'), findsWidgets);
    });

    testWidgets('should display reactions correctly', (tester) async {
      // Arrange
      final messageWithReactions = testMessage.copyWith(
        reactions: {
          '👍': ['user_2', 'user_3'],
          '❤️': ['user_4'],
        },
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageWidget(
              message: messageWithReactions,
              isCurrentUser: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('👍'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('❤️'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('should show user avatar for other users', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageWidget(
              message: testMessage,
              isCurrentUser: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('U'), findsOneWidget); // First letter of user_1
    });

    testWidgets('should format time correctly for different durations', (tester) async {
      // Test recent message (now)
      final recentMessage = testMessage.copyWith(
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageWidget(
              message: recentMessage,
              isCurrentUser: false,
            ),
          ),
        ),
      );

      expect(find.text('now'), findsOneWidget);
    });
  });
}