import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../lib/core/services/real_supabase_message_service.dart';
import '../../../lib/features/messaging/domain/entities/message.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockPostgrestQueryBuilder extends Mock implements PostgrestQueryBuilder {}
class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder {}
class MockUuid extends Mock implements Uuid {}

void main() {
  group('RealSupabaseMessageService', () {
    late RealSupabaseMessageService messageService;
    late MockSupabaseClient mockClient;
    late MockUuid mockUuid;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockUuid = MockUuid();
      
      messageService = RealSupabaseMessageService(
        client: mockClient,
        uuid: mockUuid,
      );
    });

    tearDown(() {
      messageService.dispose();
    });

    group('sendMessage', () {
      test('should successfully send a message', () async {
        // Arrange
        final message = Message(
          id: '',
          senderId: 'sender_123',
          content: 'Test message',
          roomId: 'room_123',
          timestamp: DateTime.now(),
          messageType: MessageType.text,
        );

        final mockQuery = MockPostgrestQueryBuilder();
        
        when(() => mockUuid.v4()).thenReturn('generated_id');
        when(() => mockClient.from('messages')).thenReturn(mockQuery);
        when(() => mockQuery.insert(any())).thenReturn(mockQuery);
        when(() => mockQuery.select()).thenReturn(mockQuery);
        when(() => mockQuery.single()).thenAnswer((_) async => {
          'id': 'generated_id',
          'room_id': 'room_123',
          'sender_id': 'sender_123',
          'content': 'Test message',
          'message_type': 'text',
          'timestamp': DateTime.now().toIso8601String(),
          'is_read': false,
        });

        // Act
        final result = await messageService.sendMessage(message);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, isA<Message>());
        expect(result.dataOrNull!.id, equals('generated_id'));
        expect(result.dataOrNull!.content, equals('Test message'));
        
        verify(() => mockClient.from('messages')).called(1);
        verify(() => mockQuery.insert(any())).called(1);
        verify(() => mockQuery.select()).called(1);
        verify(() => mockQuery.single()).called(1);
      });

      test('should handle database errors gracefully', () async {
        // Arrange
        final message = Message(
          id: '',
          senderId: 'sender_123',
          content: 'Test message',
          roomId: 'room_123',
          timestamp: DateTime.now(),
          messageType: MessageType.text,
        );

        final mockQuery = MockPostgrestQueryBuilder();
        
        when(() => mockUuid.v4()).thenReturn('generated_id');
        when(() => mockClient.from('messages')).thenReturn(mockQuery);
        when(() => mockQuery.insert(any())).thenReturn(mockQuery);
        when(() => mockQuery.select()).thenReturn(mockQuery);
        when(() => mockQuery.single()).thenThrow(
          PostgrestException(
            message: 'Database error',
            code: 'PGRST001',
          ),
        );

        // Act
        final result = await messageService.sendMessage(message);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureOrNull?.message, contains('Database error'));
      });

      test('should retry on network failures', () async {
        // Arrange
        final message = Message(
          id: '',
          senderId: 'sender_123',
          content: 'Test message',
          roomId: 'room_123',
          timestamp: DateTime.now(),
          messageType: MessageType.text,
        );

        final mockQuery = MockPostgrestQueryBuilder();
        
        when(() => mockUuid.v4()).thenReturn('generated_id');
        when(() => mockClient.from('messages')).thenReturn(mockQuery);
        when(() => mockQuery.insert(any())).thenReturn(mockQuery);
        when(() => mockQuery.select()).thenReturn(mockQuery);
        
        // First call fails, second succeeds
        when(() => mockQuery.single())
            .thenThrow(Exception('network connection failed'))
            .thenAnswer((_) async => {
              'id': 'generated_id',
              'room_id': 'room_123',
              'sender_id': 'sender_123',
              'content': 'Test message',
              'message_type': 'text',
              'timestamp': DateTime.now().toIso8601String(),
              'is_read': false,
            });

        // Act
        final result = await messageService.sendMessage(message);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(() => mockQuery.single()).called(2);
      });
    });

    group('getMessages', () {
      test('should retrieve messages for a room', () async {
        // Arrange
        final mockQuery = MockPostgrestQueryBuilder();
        
        when(() => mockClient.from('messages')).thenReturn(mockQuery);
        when(() => mockQuery.select()).thenReturn(mockQuery);
        when(() => mockQuery.eq('room_id', any())).thenReturn(mockQuery);
        when(() => mockQuery.eq('is_deleted', any())).thenReturn(mockQuery);
        when(() => mockQuery.order(any(), ascending: any(named: 'ascending'))).thenReturn(mockQuery);
        when(() => mockQuery.limit(any())).thenReturn(mockQuery);
        when(() => mockQuery.call()).thenAnswer((_) async => [
          {
            'id': 'msg_1',
            'room_id': 'room_123',
            'sender_id': 'sender_123',
            'content': 'Message 1',
            'message_type': 'text',
            'timestamp': DateTime.now().toIso8601String(),
            'is_read': false,
          },
          {
            'id': 'msg_2',
            'room_id': 'room_123',
            'sender_id': 'sender_456',
            'content': 'Message 2',
            'message_type': 'text',
            'timestamp': DateTime.now().toIso8601String(),
            'is_read': true,
          },
        ]);

        // Act
        final result = await messageService.getMessages('room_123', limit: 50);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, isA<List<Message>>());
        expect(result.dataOrNull!.length, equals(2));
        expect(result.dataOrNull![0].content, equals('Message 1'));
        expect(result.dataOrNull![1].content, equals('Message 2'));
      });

      test('should handle pagination with beforeId', () async {
        // Arrange
        final mockQuery = MockPostgrestQueryBuilder();
        
        when(() => mockClient.from('messages')).thenReturn(mockQuery);
        when(() => mockQuery.select(any())).thenReturn(mockQuery);
        when(() => mockQuery.eq('id', any())).thenReturn(mockQuery);
        when(() => mockQuery.single()).thenAnswer((_) async => {
          'timestamp': '2023-01-01T12:00:00Z',
        });
        when(() => mockQuery.eq('room_id', any())).thenReturn(mockQuery);
        when(() => mockQuery.eq('is_deleted', any())).thenReturn(mockQuery);
        when(() => mockQuery.filter(any(), any(), any())).thenReturn(mockQuery);
        when(() => mockQuery.order(any(), ascending: any(named: 'ascending'))).thenReturn(mockQuery);
        when(() => mockQuery.limit(any())).thenReturn(mockQuery);
        when(() => mockQuery.call()).thenAnswer((_) async => [
          {
            'id': 'msg_older',
            'room_id': 'room_123',
            'sender_id': 'sender_123',
            'content': 'Older message',
            'message_type': 'text',
            'timestamp': '2023-01-01T11:00:00Z',
            'is_read': false,
          },
        ]);

        // Act
        final result = await messageService.getMessages(
          'room_123',
          limit: 50,
          beforeId: 'msg_before',
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull!.length, equals(1));
        expect(result.dataOrNull![0].content, equals('Older message'));
      });
    });

    group('markAsRead', () {
      test('should mark messages as read', () async {
        // Arrange
        final mockQuery = MockPostgrestQueryBuilder();
        final mockFilter = MockPostgrestFilterBuilder();
        
        when(() => mockClient.from('messages')).thenReturn(mockQuery);
        when(() => mockQuery.update(any())).thenReturn(mockFilter);
        when(() => mockFilter.filter(any(), any(), any())).thenReturn(mockFilter);
        when(() => mockFilter.eq(any(), any())).thenReturn(mockFilter);
        when(() => mockFilter.call()).thenAnswer((_) async => {});

        // Act
        final result = await messageService.markAsRead('room_123', ['msg_1', 'msg_2']);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(() => mockClient.from('messages')).called(1);
        verify(() => mockQuery.update({'is_read': true})).called(1);
      });
    });

    group('deleteMessage', () {
      test('should soft delete a message', () async {
        // Arrange
        final mockQuery = MockPostgrestQueryBuilder();
        final mockFilter = MockPostgrestFilterBuilder();
        
        when(() => mockClient.from('messages')).thenReturn(mockQuery);
        when(() => mockQuery.update(any())).thenReturn(mockFilter);
        when(() => mockFilter.eq(any(), any())).thenReturn(mockFilter);
        when(() => mockFilter.call()).thenAnswer((_) async => {});

        // Act
        final result = await messageService.deleteMessage('msg_123');

        // Assert
        expect(result.isSuccess, isTrue);
        verify(() => mockClient.from('messages')).called(1);
        verify(() => mockQuery.update({'content': '[Message deleted]'})).called(1);
      });
    });

    group('message type parsing', () {
      test('should correctly parse message types', () async {
        // Arrange
        final mockQuery = MockPostgrestQueryBuilder();
        
        when(() => mockClient.from('messages')).thenReturn(mockQuery);
        when(() => mockQuery.select()).thenReturn(mockQuery);
        when(() => mockQuery.eq('room_id', any())).thenReturn(mockQuery);
        when(() => mockQuery.eq('is_deleted', any())).thenReturn(mockQuery);
        when(() => mockQuery.order(any(), ascending: any(named: 'ascending'))).thenReturn(mockQuery);
        when(() => mockQuery.limit(any())).thenReturn(mockQuery);
        when(() => mockQuery.call()).thenAnswer((_) async => [
          {
            'id': 'msg_text',
            'room_id': 'room_123',
            'sender_id': 'sender_123',
            'content': 'Text message',
            'message_type': 'text',
            'timestamp': DateTime.now().toIso8601String(),
            'is_read': false,
          },
          {
            'id': 'msg_image',
            'room_id': 'room_123',
            'sender_id': 'sender_123',
            'content': 'Image message',
            'message_type': 'image',
            'timestamp': DateTime.now().toIso8601String(),
            'is_read': false,
          },
          {
            'id': 'msg_file',
            'room_id': 'room_123',
            'sender_id': 'sender_123',
            'content': 'File message',
            'message_type': 'file',
            'timestamp': DateTime.now().toIso8601String(),
            'is_read': false,
          },
          {
            'id': 'msg_unknown',
            'room_id': 'room_123',
            'sender_id': 'sender_123',
            'content': 'Unknown message',
            'message_type': 'unknown_type',
            'timestamp': DateTime.now().toIso8601String(),
            'is_read': false,
          },
        ]);

        // Act
        final result = await messageService.getMessages('room_123');

        // Assert
        expect(result.isSuccess, isTrue);
        final messages = result.dataOrNull!;
        expect(messages[0].messageType, equals(MessageType.text));
        expect(messages[1].messageType, equals(MessageType.image));
        expect(messages[2].messageType, equals(MessageType.file));
        expect(messages[3].messageType, equals(MessageType.text)); // Unknown defaults to text
      });
    });
  });
}